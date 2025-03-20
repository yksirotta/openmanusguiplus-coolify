#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
OpenManus Web UI Dashboard
Run this script to start the web interface.
"""

import os
import logging
import sys
from pathlib import Path

# Add the parent directory to sys.path to ensure imports work correctly
sys.path.insert(0, str(Path(__file__).resolve().parent))

# Import web app and config
from app.web_app import app
from app.config import config
from app.logger import setup_logger

# Set up logging
logger = setup_logger("web_dashboard")


def main():
    """
    Main entry point for the OpenManus Web UI Dashboard.
    """
    try:
        # Log startup
        logger.info("Starting OpenManus Web Dashboard")

        # Get port from config or environment, default to 5000
        port = int(os.environ.get("PORT", config.get("web", {}).get("port", 5000)))

        # Get debug mode from config or environment, default to False in production
        debug = os.environ.get("DEBUG", config.get("web", {}).get("debug", False))

        # Print access information
        print(f"OpenManus Web Dashboard is running!")
        print(f"Access the dashboard at: http://localhost:{port}")
        print(f"Press Ctrl+C to stop the server.")

        # Run the Flask app
        logger.info(f"Web UI available at http://localhost:{port}")
        app.run(debug=debug, host="0.0.0.0", port=port)

    except Exception as e:
        logger.error(f"Error starting web dashboard: {e}")
        raise


if __name__ == "__main__":
    main()
