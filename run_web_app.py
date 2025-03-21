#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
OpenManus Web UI Dashboard
Run this script to start the web interface.
"""

import os
import logging
import sys
import importlib.util
from pathlib import Path

# Add the parent directory to sys.path to ensure imports work correctly
sys.path.insert(0, str(Path(__file__).resolve().parent))

# Set up basic logging first in case imports fail
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("web_dashboard")

# Try importing dependencies with fallbacks
try:
    import tomli
except ImportError:
    logger.warning("tomli not found, attempting to use built-in tomllib")
    try:
        import tomllib as tomli
    except ImportError:
        logger.error("Neither tomli nor tomllib available. Config parsing may fail.")

        # Define a minimal stub that will prevent crashes when referenced
        class TomliStub:
            @staticmethod
            def load(file):
                logger.error("No TOML parser available. Using empty config.")
                return {}

        tomli = TomliStub()

# Import web app, config, and logger with error handling
try:
    from app.web_app import app, get_config_value

    logger.info("Successfully imported web app")
except ImportError as e:
    logger.error(f"Failed to import app.web_app: {e}")
    sys.exit(1)

try:
    from app.config import config

    logger.info("Successfully imported config")
except ImportError as e:
    logger.error(f"Failed to import app.config: {e}")
    logger.warning("Using fallback configuration")
    config = {
        "system": {"max_tokens_limit": 8192, "max_concurrent_requests": 2},
        "web": {"port": 5000, "debug": False},
    }

# Try to use the logger from app.logger, but fall back to basic logging
try:
    from app.logger import setup_logger

    logger = setup_logger("web_dashboard")
    logger.info("Using configured logger from app.logger")
except ImportError as e:
    logger.warning(f"Could not import setup_logger: {e}")
    logger.info("Using basic logger")


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
        # Get the port and debug configuration
        port = get_config_value("web", "port", 5000)
        debug = get_config_value("web", "debug", False)

        # Log startup information
        logger.info(f"Starting OpenManus Web UI Dashboard on port {port}")
        logger.info(f"Debug mode: {debug}")

        # Start the Flask app
        app.run(host="0.0.0.0", port=port, debug=debug)
    except Exception as e:
        logger.exception(f"Error starting OpenManus Web UI Dashboard: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
