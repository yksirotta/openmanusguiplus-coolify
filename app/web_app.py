from flask import Flask, render_template, request, jsonify
import os
import asyncio
from concurrent.futures import ThreadPoolExecutor

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
    # This would be replaced with actual model listing from config
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
        {
            "id": "claude-3-sonnet",
            "name": "Claude 3 Sonnet",
            "features": ["web_access", "file_upload", "code_execution"],
        },
        {
            "id": "llama-3",
            "name": "Llama 3",
            "features": ["file_upload", "code_execution"],
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
        # This would be replaced with actual user settings retrieval
        settings = {
            "theme": "dark",
            "default_model": "gpt-4o",
            "temperature": 0.7,
            "save_conversations": True,
            "allow_web_searches": True,
            "data_retention_days": 30,
        }
        return jsonify(settings)
    else:
        # Update settings
        data = request.json
        # In a real implementation, this would update user settings
        return jsonify({"success": True, "settings": data})


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
