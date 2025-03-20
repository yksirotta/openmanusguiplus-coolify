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

# Import OpenManus components
from app.llm import LLM
from app.config import config

# Create Flask app
app = Flask(__name__)
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY") or "dev-key-for-openmanus"
app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024  # Limit uploads to 10MB

# Thread pool for running async code
executor = ThreadPoolExecutor(max_workers=4)

# Configure memory management
memory_limit = int(config.get("system", {}).get("max_tokens_limit", 8192))
max_concurrent = int(config.get("system", {}).get("max_concurrent_requests", 2))
last_gc_time = time.time()
active_requests = 0


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
    try:
        # Check memory usage before processing
        memory_percent = psutil.virtual_memory().percent
        if memory_percent > 90:  # If memory usage is above 90%
            gc.collect()  # Force garbage collection

        # Process the chat message
        data = request.json
        message = data.get("message", "")
        context = data.get("context", [])

        # Generate a response (implement proper async handling)
        response = generate_response(message, context)

        # Return the response
        return jsonify({"response": response, "status": "success"})
    except Exception as e:
        logging.error(f"Error in chat API: {str(e)}")
        return jsonify({"error": str(e), "status": "error"}), 500


@app.route("/api/models", methods=["GET"])
def get_models():
    """API endpoint to get available models"""
    # Get actual models from config
    models = []

    for model_name, model_config in config.get("llm", {}).items():
        if model_name != "default":  # Skip default config
            model_info = {
                "id": model_name,
                "name": model_config.get("model", model_name),
                "base_url": model_config.get("base_url", ""),
                "api_type": model_config.get("api_type", "openai"),
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
        # Get current settings from config
        user_settings = {
            "theme": "dark",
            "model": config.get("llm", {}).get("default", "gpt-4o"),
            "temperature": config.get("llm", {}).get("temperature", 0.7),
            "save_conversations": True,
            "max_history": 100,
        }
        return jsonify({"settings": user_settings})
    else:
        # Update settings
        new_settings = request.json.get("settings", {})
        # Implementation would save these settings
        return jsonify({"status": "success", "settings": new_settings})


@app.route("/api/config", methods=["GET", "POST"])
def manage_config():
    """API endpoint for configuration management"""
    if request.method == "GET":
        try:
            # Get current configuration (mask sensitive data)
            masked_config = mask_sensitive_config(config)
            return jsonify({"success": True, "config": masked_config})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)})
    else:
        try:
            # Update configuration
            new_config = request.json.get("config", {})

            # Preserve API keys if they are masked
            preserve_api_keys(config, new_config)

            # Save configuration
            # Implementation would update and save config

            return jsonify({"success": True})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)})


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
        }

        return jsonify(stats)
    except Exception as e:
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
async def generate_response(message, context=None):
    """Generate a response using the LLM"""
    if context is None:
        context = []

    # If running without LLM, return a placeholder
    if LLM is None:
        await asyncio.sleep(1)  # Simulate processing time
        return f"This is a simulated response to: {message}"

    # Implement real LLM response generation
    response = "The OpenManus dashboard is now set up and functional. This is a placeholder response until the LLM integration is fully configured."

    return response


# Run the app
if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
