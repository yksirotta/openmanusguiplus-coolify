#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
OpenManus Web UI Dashboard
Run this script to start the web interface.
"""

import os
import logging
import sys
import tomli
from pathlib import Path

# Add the parent directory to sys.path to ensure imports work correctly
sys.path.insert(0, str(Path(__file__).resolve().parent))

# Import web app and config
from app.web_app import app
from app.config import config
from app.logger import setup_logger

# Set up logging
logger = setup_logger("web_dashboard")


def get_config_value(section, key, default_value):
    """
    Safely get a configuration value, handling different config types.

    Args:
        section (str): Configuration section name
        key (str): Configuration key name
        default_value: Default value if not found

    Returns:
        The configuration value or default if not found
    """
    try:
        # For dict-type configs (fallback config)
        if isinstance(config, dict):
            return config.get(section, {}).get(key, default_value)

        # For Config class - try to read the raw TOML file
        try:
            config_path = config._get_config_path()
            with open(config_path, "rb") as f:
                toml_config = tomli.load(f)
                return toml_config.get(section, {}).get(key, default_value)
        except (AttributeError, FileNotFoundError, ImportError):
            # If we can't access the method or file, use defaults
            pass

        # Fallback to defaults
        return default_value
    except Exception as e:
        logger.error(f"Error accessing configuration: {e}")
        return default_value


def main():
    """
    Main entry point for the OpenManus Web UI Dashboard.
    """
    try:
        # Log startup
        logger.info("Starting OpenManus Web Dashboard")

        # Get port from config or environment, default to 5000
        port = int(os.environ.get("PORT", get_config_value("web", "port", 5000)))

        # Get debug mode from config or environment, default to False in production
        debug = os.environ.get("DEBUG", get_config_value("web", "debug", False))

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
