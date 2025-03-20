from flask import Flask, render_template, request, jsonify
import os
import asyncio
from concurrent.futures import ThreadPoolExecutor
import psutil
import json
import tomli_w
from pathlib import Path

# Import OpenManus components
from app.llm import LLM
from app.config import config

# Create Flask app
app = Flask(__name__)
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY") or "dev-key-for-openmanus"

# Thread pool for running async code
executor = ThreadPoolExecutor(max_workers=4)


# Helper to run async functions from Flask routes
def run_async(coro):
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


# Initialize LLM
llm = None


def init_llm():
    global llm
    if llm is None:
        llm = LLM()


# Routes
@app.route("/")
def index():
    """Render the main dashboard page"""
    return render_template("index.html")


@app.route("/api/chat", methods=["POST"])
def chat():
    """API endpoint for chat messages"""
    data = request.json

    if not data or "message" not in data:
        return jsonify({"error": "Message is required"}), 400

    user_message = data["message"]
    model = data.get("model", "gpt-4o")  # Default to gpt-4o if not specified

    # Initialize LLM if not already done
    init_llm()

    try:
        # Process the message with OpenManus
        def process_message():
            # This would be replaced with actual OpenManus processing
            response = run_async(generate_response(user_message, model))
            return response

        # Run in thread pool to not block Flask
        response = executor.submit(process_message).result()

        return jsonify({"response": response, "model": model})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/models", methods=["GET"])
def get_models():
    """API endpoint to get available models"""
    # Get actual models from config
    models = []

    for model_name, model_config in config.llm.items():
        if model_name != "default":  # Skip default config
            model_info = {
                "id": model_name,
                "name": model_config.model,
                "base_url": model_config.base_url,
                "api_type": model_config.api_type,
                "features": ["web_access", "file_upload", "code_execution", "tool_use"],
            }
            models.append(model_info)

    # If no models found, provide defaults
    if not models:
        models = [
            {
                "id": "gpt-4o",
                "name": "GPT-4o",
                "features": ["web_access", "file_upload", "code_execution", "tool_use"],
            },
            {
                "id": "claude-3-opus",
                "name": "Claude 3 Opus",
                "features": ["web_access", "file_upload", "code_execution", "tool_use"],
            },
        ]

    return jsonify({"models": models})


@app.route("/api/tools", methods=["GET"])
def get_tools():
    """API endpoint to get available tools"""
    # This would be replaced with actual tool listing from OpenManus
    tools = [
        {
            "id": "web_search",
            "name": "Web Search",
            "icon": "fa-globe",
            "description": "Search the web for information",
        },
        {
            "id": "file_upload",
            "name": "File Upload",
            "icon": "fa-file-upload",
            "description": "Upload and analyze files",
        },
        {
            "id": "code_run",
            "name": "Code Execution",
            "icon": "fa-code",
            "description": "Execute code in various languages",
        },
        {
            "id": "browser",
            "name": "Web Browser",
            "icon": "fa-window-maximize",
            "description": "Navigate and interact with websites",
        },
        {
            "id": "terminal",
            "name": "Terminal",
            "icon": "fa-terminal",
            "description": "Run system commands",
        },
    ]

    return jsonify({"tools": tools})


@app.route("/api/upload", methods=["POST"])
def upload_file():
    """API endpoint for file uploads"""
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files["file"]

    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    # In a real implementation, this would save the file to a secure location and process it
    # For now, just return success
    return jsonify(
        {
            "success": True,
            "filename": file.filename,
            "size": 0,  # Would be actual file size
            "file_id": "123",  # Would be a unique ID for the file
        }
    )


@app.route("/api/settings", methods=["GET", "PUT"])
def settings():
    """API endpoint for user settings"""
    if request.method == "GET":
        # Return actual configuration
        llm_settings = {}
        for model_name, model_config in config.llm.items():
            # Remove sensitive information for display
            display_config = {
                "model": model_config.model,
                "base_url": model_config.base_url,
                "api_key_set": bool(model_config.api_key),  # Don't send actual API key
                "temperature": model_config.temperature,
                "max_tokens": model_config.max_tokens,
                "api_type": model_config.api_type,
                "api_version": model_config.api_version,
            }
            llm_settings[model_name] = display_config

        # Add other configuration sections
        browser_config = {}
        if config.browser_config:
            browser_config = {
                "headless": config.browser_config.headless,
                "disable_security": config.browser_config.disable_security,
                "max_content_length": config.browser_config.max_content_length,
            }

        # User interface settings (these would normally be stored per user)
        ui_settings = {
            "theme": "dark",
            "save_conversations": True,
            "allow_web_searches": True,
            "data_retention_days": 30,
        }

        return jsonify(
            {"llm": llm_settings, "browser": browser_config, "ui": ui_settings}
        )
    else:
        # Update settings
        data = request.json
        if not data:
            return jsonify({"error": "No settings provided"}), 400

        try:
            # In a real implementation, this would update the configuration file
            # For now, just return success
            return jsonify(
                {"success": True, "message": "Settings updated successfully"}
            )
        except Exception as e:
            return jsonify({"error": f"Failed to update settings: {str(e)}"}), 500


@app.route("/api/config", methods=["GET", "POST"])
def manage_config():
    """API endpoint for complete configuration management"""
    if request.method == "GET":
        # Read the current config file
        config_path = config._get_config_path()
        try:
            with open(config_path, "rb") as f:
                config_data = tomli.load(f)
                # Mask API keys for security
                if "llm" in config_data:
                    for key in config_data["llm"]:
                        if (
                            isinstance(config_data["llm"][key], dict)
                            and "api_key" in config_data["llm"][key]
                        ):
                            config_data["llm"][key]["api_key"] = "••••••"
                return jsonify({"config": config_data, "path": str(config_path)})
        except Exception as e:
            return jsonify({"error": f"Failed to read config: {str(e)}"}), 500
    else:
        # Update the config file
        data = request.json
        if not data or "config" not in data:
            return jsonify({"error": "No configuration provided"}), 400

        try:
            # Write the updated config
            config_path = config._get_config_path()
            config_data = data["config"]

            # Handle API keys (only update if not masked)
            current_config = {}
            with open(config_path, "rb") as f:
                current_config = tomli.load(f)

            # Preserve existing API keys if they're masked in the new config
            if "llm" in config_data and "llm" in current_config:
                for key in config_data["llm"]:
                    if (
                        isinstance(config_data["llm"][key], dict)
                        and "api_key" in config_data["llm"][key]
                    ):
                        if config_data["llm"][key]["api_key"] == "••••••":
                            # Keep the original API key
                            if key in current_config["llm"] and isinstance(
                                current_config["llm"][key], dict
                            ):
                                config_data["llm"][key]["api_key"] = current_config[
                                    "llm"
                                ][key].get("api_key", "")

            # Write the updated config
            with open(config_path, "wb") as f:
                tomli_w.dump(config_data, f)

            # Reload the configuration
            config._load_initial_config()

            return jsonify(
                {"success": True, "message": "Configuration updated successfully"}
            )
        except Exception as e:
            return jsonify({"error": f"Failed to update config: {str(e)}"}), 500


@app.route("/api/system/stats", methods=["GET"])
def system_stats():
    """API endpoint to get system resource usage"""
    try:
        # Get CPU usage
        cpu_percent = psutil.cpu_percent(interval=0.5)
        cpu_count = psutil.cpu_count()
        cpu_freq = psutil.cpu_freq()

        # Get memory usage
        memory = psutil.virtual_memory()

        # Get disk usage
        disk = psutil.disk_usage("/")

        # Format the data
        stats = {
            "cpu": {
                "percent": cpu_percent,
                "cores": cpu_count,
                "frequency": cpu_freq.current if cpu_freq else None,
                "per_core": psutil.cpu_percent(interval=0.5, percpu=True),
            },
            "memory": {
                "total": memory.total,
                "available": memory.available,
                "percent": memory.percent,
                "used": memory.used,
                "free": memory.free,
            },
            "disk": {
                "total": disk.total,
                "used": disk.used,
                "free": disk.free,
                "percent": disk.percent,
            },
        }

        return jsonify(stats)
    except Exception as e:
        return jsonify({"error": f"Failed to get system stats: {str(e)}"}), 500


# Async functions for AI processing
async def generate_response(message, model="gpt-4o"):
    """Generate a response using the LLM"""
    # This would use the actual OpenManus LLM with proper context
    try:
        # For now, return a placeholder response
        return f"This is a simulated response from OpenManus using the {model} model. Your message was: '{message}'"
    except Exception as e:
        print(f"Error generating response: {str(e)}")
        return f"Sorry, I encountered an error: {str(e)}"


# Run the app
if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
