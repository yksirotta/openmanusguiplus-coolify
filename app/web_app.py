from flask import Flask, render_template, request, jsonify
import os
import asyncio
from concurrent.futures import ThreadPoolExecutor
import psutil
import json
import tomli_w
from pathlib import Path
import time
import gc
from werkzeug.utils import secure_filename
import logging
import importlib.util

# Create Flask app
app = Flask(__name__)
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY") or "dev-key-for-openmanus"
app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024  # Limit uploads to 10MB

# Thread pool for running async code
executor = ThreadPoolExecutor(max_workers=4)

# Load config
try:
    from app.config import config
except ImportError:
    # Fallback config if module not available
    config = {
        "system": {
            "max_tokens_limit": 8192,
            "max_concurrent_requests": 2,
            "lightweight_mode": False,
        },
        "llm": {"model": "gpt-4o", "temperature": 0.7},
        "web": {"port": 5000, "debug": False},
    }

# Configure memory management
try:
    # If config is a dictionary (fallback config)
    if isinstance(config, dict):
        memory_limit = int(config.get("system", {}).get("max_tokens_limit", 8192))
        max_concurrent = int(config.get("system", {}).get("max_concurrent_requests", 2))
        lightweight_mode = config.get("system", {}).get("lightweight_mode", False)
    else:
        # For the Config class from config.py, read values from raw config
        # Attempt to access the raw config via _load_config method
        raw_config = getattr(config, "_config", None)
        if raw_config:
            # Try to get system settings from AppConfig
            system_config = getattr(raw_config, "system", {})
            memory_limit = 8192  # Default value
            max_concurrent = 2  # Default value
            lightweight_mode = False  # Default value

            # Check if the loaded_config file exists and read from it directly
            try:
                config_path = config._get_config_path()
                import tomli

                with open(config_path, "rb") as f:
                    toml_config = tomli.load(f)
                    system_config = toml_config.get("system", {})
                    memory_limit = int(system_config.get("max_tokens_limit", 8192))
                    max_concurrent = int(
                        system_config.get("max_concurrent_requests", 2)
                    )
                    lightweight_mode = system_config.get("lightweight_mode", False)
            except Exception as e:
                print(f"Error loading system config: {e}")
        else:
            # Fallback to defaults
            memory_limit = 8192
            max_concurrent = 2
            lightweight_mode = False
except Exception as e:
    # Log the error and use defaults if anything goes wrong
    print(f"Error configuring memory management: {e}")
    memory_limit = 8192
    max_concurrent = 2
    lightweight_mode = False

last_gc_time = time.time()
active_requests = 0


# Helper function to check if a module can be imported
def is_module_available(module_name):
    """Check if a module can be imported without actually importing it"""
    try:
        spec = importlib.util.find_spec(module_name)
        return spec is not None
    except ModuleNotFoundError:
        return False


# Set up request limiter
@app.before_request
def before_request():
    global active_requests, last_gc_time

    # Check if we need to run garbage collection (every 60 seconds)
    if time.time() - last_gc_time > 60:
        gc.collect()
        last_gc_time = time.time()

    # Limit concurrent requests
    if active_requests >= max_concurrent and request.endpoint != "static":
        return (
            jsonify({"error": "Too many concurrent requests, please try again later"}),
            429,
        )

    active_requests += 1


@app.after_request
def after_request(response):
    global active_requests
    active_requests -= 1
    return response


# Initialize LLM lazily
llm = None


def init_llm():
    global llm
    if llm is None:
        try:
            # Only import LLM if needed
            from app.llm import LLM

            llm = LLM()
        except ImportError as e:
            logging.warning(f"Could not initialize LLM: {str(e)}")
            return None
    return llm


# Routes
@app.route("/")
def index():
    """Render the main dashboard page"""
    return render_template("index.html")


@app.route("/api/chat", methods=["POST"])
def chat():
    """API endpoint for chat messages"""
    try:
        # Check memory usage before processing
        memory_percent = psutil.virtual_memory().percent
        if memory_percent > 90:  # If memory usage is above 90%
            gc.collect()  # Force garbage collection

        # Process the chat message
        data = request.json
        message = data.get("message", "")
        context = data.get("context", [])
        model_id = data.get("model", "default")

        # Check if LLM is available
        if not is_module_available("tiktoken") or not is_module_available("openai"):
            return jsonify(
                {
                    "response": "AI features are not available in lightweight mode. Install AI dependencies with './cache-manager.sh ai'",
                    "status": "warning",
                }
            )

        # Initialize LLM lazily
        if init_llm() is None:
            return (
                jsonify(
                    {
                        "response": "Failed to initialize LLM. Please check your installation and dependencies.",
                        "status": "error",
                    }
                ),
                500,
            )

        # Use executor to run async task in the background
        loop = asyncio.new_event_loop()
        response = loop.run_until_complete(
            generate_response(message, model_id, context)
        )
        loop.close()

        # Return the response
        return jsonify({"response": response, "status": "success"})
    except Exception as e:
        logging.error(f"Error in chat API: {str(e)}")
        return jsonify({"error": str(e), "status": "error"}), 500


@app.route("/api/models", methods=["GET"])
def get_models():
    """API endpoint to get available models"""
    # Check if we're in lightweight mode
    if lightweight_mode or not is_module_available("openai"):
        return jsonify(
            {
                "models": [
                    {
                        "id": "lightweight-mode",
                        "name": "Lightweight Mode (AI disabled)",
                        "features": ["web_access", "file_upload", "code_execution"],
                        "disabled": True,
                    }
                ],
                "status": "lightweight_mode",
            }
        )

    # Get actual models from config
    try:
        models = []

        # Try to load the config directly from the toml file
        try:
            import tomli

            config_path = Path("config/config.toml")

            if config_path.exists():
                with open(config_path, "rb") as f:
                    toml_config = tomli.load(f)
                    llm_section = toml_config.get("llm", {})

                    # Process entries that are dictionaries (model configurations)
                    for model_name, model_config in llm_section.items():
                        if isinstance(model_config, dict):
                            model_info = {
                                "id": model_name,
                                "name": model_config.get("model", model_name),
                                "base_url": model_config.get("base_url", ""),
                                "api_type": model_config.get("api_type", "openai"),
                                "features": [
                                    "web_access",
                                    "file_upload",
                                    "code_execution",
                                    "tool_use",
                                ],
                            }
                            models.append(model_info)
        except Exception as e:
            logging.error(f"Error loading models from config: {e}")

        # If no models found, provide modern defaults
        if not models:
            models = [
                {
                    "id": "gpt-4o",
                    "name": "GPT-4o",
                    "api_type": "openai",
                    "features": [
                        "web_access",
                        "file_upload",
                        "code_execution",
                        "tool_use",
                        "vision",
                    ],
                },
                {
                    "id": "gpt-4o-mini",
                    "name": "GPT-4o Mini",
                    "api_type": "openai",
                    "features": [
                        "web_access",
                        "file_upload",
                        "code_execution",
                        "tool_use",
                        "vision",
                    ],
                },
                {
                    "id": "claude-3-opus-20240229",
                    "name": "Claude 3 Opus",
                    "api_type": "anthropic",
                    "features": [
                        "web_access",
                        "file_upload",
                        "code_execution",
                        "tool_use",
                        "vision",
                    ],
                },
                {
                    "id": "claude-3-sonnet-20240229",
                    "name": "Claude 3 Sonnet",
                    "api_type": "anthropic",
                    "features": [
                        "web_access",
                        "file_upload",
                        "code_execution",
                        "tool_use",
                        "vision",
                    ],
                },
                {
                    "id": "claude-3-haiku-20240307",
                    "name": "Claude 3 Haiku",
                    "api_type": "anthropic",
                    "features": [
                        "web_access",
                        "file_upload",
                        "code_execution",
                        "tool_use",
                        "vision",
                    ],
                },
                {
                    "id": "mistral-large-latest",
                    "name": "Mistral Large",
                    "api_type": "mistral",
                    "features": [
                        "web_access",
                        "file_upload",
                        "code_execution",
                        "tool_use",
                    ],
                },
                {
                    "id": "command-r",
                    "name": "Command R",
                    "api_type": "cohere",
                    "features": [
                        "web_access",
                        "file_upload",
                        "code_execution",
                        "tool_use",
                    ],
                },
            ]

        return jsonify({"models": models})
    except Exception as e:
        logging.error(f"Error in models API: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/api/tools", methods=["GET"])
def get_tools():
    """API endpoint to get available tools"""
    tools = [
        {
            "id": "web_search",
            "name": "Web Search",
            "description": "Search the web for information",
        },
        {
            "id": "code_execution",
            "name": "Code Execution",
            "description": "Execute code in a sandbox environment",
        },
        {
            "id": "file_browser",
            "name": "File Browser",
            "description": "Browse and manipulate files",
        },
        {
            "id": "terminal",
            "name": "Terminal",
            "description": "Execute terminal commands",
        },
    ]

    # Don't offer AI features in lightweight mode
    if not lightweight_mode and is_module_available("openai"):
        tools.append(
            {
                "id": "ai_completion",
                "name": "AI Completion",
                "description": "Generate text with AI models",
            }
        )

    return jsonify({"tools": tools})


@app.route("/api/upload", methods=["POST"])
def upload_file():
    """API endpoint for file uploads"""
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files["file"]

    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    # Create an uploads directory if it doesn't exist
    uploads_dir = Path("uploads")
    uploads_dir.mkdir(exist_ok=True)

    # Save the file
    filename = secure_filename(file.filename)
    file_path = uploads_dir / filename
    file.save(file_path)

    return jsonify({"status": "success", "filename": filename, "path": str(file_path)})


@app.route("/api/settings", methods=["GET", "PUT"])
def settings():
    """API endpoint for user settings"""
    if request.method == "GET":
        try:
            # Get config path and read directly
            config_path = Path("config/config.toml")

            # Default settings if file doesn't exist
            user_settings = {
                "theme": "dark",
                "model": "gpt-4o",
                "temperature": 0.7,
                "save_conversations": True,
                "max_history": 100,
                "lightweight_mode": lightweight_mode,
            }

            # Try to read from the config file
            if config_path.exists():
                try:
                    import tomli

                    with open(config_path, "rb") as f:
                        toml_config = tomli.load(f)
                        llm_config = toml_config.get("llm", {})
                        web_config = toml_config.get("web", {})
                        system_config = toml_config.get("system", {})

                        # Update settings from config
                        user_settings["model"] = llm_config.get("model", "gpt-4o")
                        user_settings["temperature"] = llm_config.get(
                            "temperature", 0.7
                        )
                        user_settings["theme"] = web_config.get("theme", "dark")
                        user_settings["save_conversations"] = web_config.get(
                            "save_conversations", True
                        )
                        user_settings["max_history"] = web_config.get(
                            "max_history", 100
                        )
                        user_settings["lightweight_mode"] = system_config.get(
                            "lightweight_mode", lightweight_mode
                        )
                except Exception as e:
                    logging.error(f"Error reading user settings: {e}")

            return jsonify({"settings": user_settings})
        except Exception as e:
            logging.error(f"Error getting settings: {e}")
            return jsonify({"error": str(e)}), 500
    else:
        try:
            # Update settings
            new_settings = request.json.get("settings", {})

            # Read existing config
            config_path = Path("config/config.toml")
            import tomli, tomli_w

            if config_path.exists():
                with open(config_path, "rb") as f:
                    toml_config = tomli.load(f)
            else:
                toml_config = {"llm": {}, "web": {}, "system": {}}

            # Update config with new settings
            if "model" in new_settings:
                toml_config["llm"]["model"] = new_settings["model"]

            if "temperature" in new_settings:
                toml_config["llm"]["temperature"] = new_settings["temperature"]

            if "theme" in new_settings:
                toml_config["web"]["theme"] = new_settings["theme"]

            if "save_conversations" in new_settings:
                toml_config["web"]["save_conversations"] = new_settings[
                    "save_conversations"
                ]

            if "max_history" in new_settings:
                toml_config["web"]["max_history"] = new_settings["max_history"]

            if "lightweight_mode" in new_settings:
                toml_config["system"]["lightweight_mode"] = new_settings[
                    "lightweight_mode"
                ]

            # Ensure the config directory exists
            config_path.parent.mkdir(exist_ok=True)

            # Write updated config
            with open(config_path, "wb") as f:
                tomli_w.dump(toml_config, f)

            return jsonify({"status": "success", "settings": new_settings})
        except Exception as e:
            logging.error(f"Error updating settings: {e}")
            return jsonify({"error": str(e)}), 500


@app.route("/api/config", methods=["GET", "POST"])
def manage_config():
    """API endpoint for configuration management"""
    if request.method == "GET":
        try:
            # Get config path and read directly
            config_path = Path("config/config.toml")
            if not config_path.exists():
                return (
                    jsonify(
                        {"success": False, "error": "Configuration file not found"}
                    ),
                    404,
                )

            # Read the configuration file
            import tomli

            with open(config_path, "rb") as f:
                toml_config = tomli.load(f)

            # Mask sensitive data (API keys)
            masked_config = mask_sensitive_config(toml_config)

            return jsonify({"success": True, "config": masked_config})
        except Exception as e:
            logging.error(f"Error getting configuration: {e}")
            return jsonify({"success": False, "error": str(e)}), 500
    else:
        try:
            # Update configuration
            new_config = request.json.get("config", {})

            # Read existing config
            config_path = Path("config/config.toml")
            import tomli, tomli_w

            if config_path.exists():
                with open(config_path, "rb") as f:
                    existing_config = tomli.load(f)
            else:
                existing_config = {}

            # Preserve API keys if they are masked
            preserve_api_keys(existing_config, new_config)

            # Ensure the config directory exists
            config_path.parent.mkdir(exist_ok=True)

            # Write updated config
            with open(config_path, "wb") as f:
                tomli_w.dump(new_config, f)

            return jsonify({"success": True})
        except Exception as e:
            logging.error(f"Error updating configuration: {e}")
            return jsonify({"success": False, "error": str(e)}), 500


@app.route("/api/system/stats", methods=["GET"])
def system_stats():
    """API endpoint for system resource usage statistics"""
    try:
        # Get CPU info
        cpu_percent = psutil.cpu_percent(interval=0.5)
        cpu_count = psutil.cpu_count(logical=True)

        # Get per-core CPU usage
        per_core = psutil.cpu_percent(interval=0.1, percpu=True)

        # Get memory info
        memory = psutil.virtual_memory()

        # Get disk info
        disk = psutil.disk_usage("/")

        stats = {
            "cpu": {
                "percent": cpu_percent,
                "cores": cpu_count,
                "per_core": per_core,
                "frequency": psutil.cpu_freq().current if psutil.cpu_freq() else None,
            },
            "memory": {
                "total": memory.total,
                "available": memory.available,
                "used": memory.used,
                "percent": memory.percent,
            },
            "disk": {
                "total": disk.total,
                "used": disk.used,
                "free": disk.free,
                "percent": disk.percent,
            },
            "process": {
                "memory_percent": psutil.Process(os.getpid()).memory_percent(),
                "cpu_percent": psutil.Process(os.getpid()).cpu_percent(interval=0.1),
            },
            "system": {
                "lightweight_mode": lightweight_mode,
                "time": time.time(),
                "uptime": (
                    time.time() - psutil.boot_time()
                    if hasattr(psutil, "boot_time")
                    else 0
                ),
            },
        }

        return jsonify(stats)
    except Exception as e:
        logging.error(f"Error in system stats API: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route("/api/system/dependencies", methods=["GET"])
def system_dependencies():
    """API endpoint for checking system dependencies"""
    try:
        # Check for critical dependencies
        dependencies = {
            "flask": True,  # We're running, so Flask is available
            "psutil": True,  # We're using it for stats
            "openai": is_module_available("openai"),
            "tiktoken": is_module_available("tiktoken"),
            "numpy": is_module_available("numpy"),
            "torch": is_module_available("torch"),
        }

        # Get installed package versions where possible
        versions = {}
        try:
            import pkg_resources

            for pkg in dependencies.keys():
                try:
                    versions[pkg] = pkg_resources.get_distribution(pkg).version
                except pkg_resources.DistributionNotFound:
                    versions[pkg] = None
        except ImportError:
            # pkg_resources not available
            pass

        return jsonify(
            {
                "dependencies": dependencies,
                "versions": versions,
                "lightweight_mode": lightweight_mode,
            }
        )
    except Exception as e:
        logging.error(f"Error in dependencies API: {str(e)}")
        return jsonify({"error": str(e)}), 500


# Helper functions
def mask_sensitive_config(config):
    """Mask sensitive information in configuration"""
    masked = {}

    # Deep copy while masking API keys
    for section, values in config.items():
        if isinstance(values, dict):
            masked[section] = {}
            for key, value in values.items():
                if isinstance(value, dict):
                    masked[section][key] = {}
                    for subkey, subvalue in value.items():
                        if "api_key" in subkey.lower() and subvalue:
                            masked[section][key][subkey] = "********"
                        else:
                            masked[section][key][subkey] = subvalue
                elif "api_key" in key.lower() and value:
                    masked[section][key] = "********"
                else:
                    masked[section][key] = value
        else:
            masked[section] = values

    return masked


def preserve_api_keys(old_config, new_config):
    """Preserve API keys in new configuration if they are masked"""
    for section, values in new_config.items():
        if isinstance(values, dict):
            if section not in old_config:
                continue

            for key, value in values.items():
                if isinstance(value, dict):
                    if key not in old_config[section]:
                        continue

                    for subkey, subvalue in value.items():
                        if "api_key" in subkey.lower() and subvalue == "********":
                            # Preserve the old API key
                            if subkey in old_config[section][key]:
                                value[subkey] = old_config[section][key][subkey]
                elif "api_key" in key.lower() and value == "********":
                    # Preserve the old API key
                    if key in old_config[section]:
                        values[key] = old_config[section][key]


# Async functions for AI processing
async def generate_response(message, model_id="default", context=None):
    """Generate a response using the LLM"""
    if context is None:
        context = []

    # Check if we're in lightweight mode
    if lightweight_mode:
        await asyncio.sleep(0.5)  # Simulate processing time
        return "AI features are disabled in lightweight mode. Install AI dependencies with './cache-manager.sh ai'"

    # If running without LLM, return a placeholder
    llm_instance = init_llm()
    if llm_instance is None:
        await asyncio.sleep(1)  # Simulate processing time
        return f"I've received your message: {message}. The OpenManus dashboard is running, but the LLM integration is not fully configured yet."

    try:
        # Convert context to messages format expected by LLM
        formatted_messages = [
            {"role": "system", "content": "You are OpenManus AI, a helpful assistant."}
        ]

        # Add context messages
        for ctx_msg in context:
            if "role" in ctx_msg and "content" in ctx_msg:
                formatted_messages.append(
                    {"role": ctx_msg["role"], "content": ctx_msg["content"]}
                )

        # Add user message
        formatted_messages.append({"role": "user", "content": message})

        try:
            # Try to call LLM for response
            response = await llm_instance.ask(formatted_messages)
            return response
        except AttributeError:
            # In case llm_instance doesn't have ask method
            logging.warning("LLM instance doesn't have ask method, using fallback")
            await asyncio.sleep(1)  # Simulate thinking
            return f"I received your message: '{message}'. This is a simulated response since the LLM integration is not properly configured."
        except Exception as inner_e:
            logging.error(f"Error calling LLM: {inner_e}")
            return f"I'm sorry, I encountered an error when processing your request through the language model: {str(inner_e)}"
    except Exception as e:
        logging.error(f"Error generating response: {e}")
        return f"I encountered an error while processing your request: {str(e)}"


# Run the app
if __name__ == "__main__":
    port = int(config.get("web", {}).get("port", 5000))
    debug = bool(config.get("web", {}).get("debug", False))

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )

    # Check if we're in lightweight mode
    if lightweight_mode:
        logging.info("Running in lightweight mode - AI features disabled")

    # Check for missing dependencies
    if not is_module_available("openai") or not is_module_available("tiktoken"):
        logging.warning(
            "AI dependencies missing. Run './manage_deps.sh install-ai' to enable AI features."
        )

    try:
        app.run(debug=debug, host="0.0.0.0", port=port)
    except Exception as e:
        logging.error(f"Error starting server: {str(e)}")
