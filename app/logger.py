import sys
import os
import logging
from datetime import datetime
from pathlib import Path

# Try to import loguru, but provide a fallback if it's not available
try:
    from loguru import logger as _logger

    LOGURU_AVAILABLE = True
except ImportError:
    LOGURU_AVAILABLE = False
    # Set up a basic logger as fallback
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )
    _logger = logging.getLogger("openmanusguiplus")

# Try to import from config, but provide fallback if it fails
try:
    from app.config import PROJECT_ROOT
except ImportError:
    # Fallback if config import fails
    def get_project_root():
        return Path(__file__).resolve().parent.parent

    PROJECT_ROOT = get_project_root()

_print_level = "INFO"


def define_log_level(print_level="INFO", logfile_level="DEBUG", name: str = None):
    """Adjust the log level to above level"""
    global _print_level
    _print_level = print_level

    current_date = datetime.now()
    formatted_date = current_date.strftime("%Y%m%d%H%M%S")
    log_name = (
        f"{name}_{formatted_date}" if name else formatted_date
    )  # name a log with prefix name

    # Ensure the logs directory exists
    log_dir = PROJECT_ROOT / "logs"
    log_dir.mkdir(exist_ok=True)

    if LOGURU_AVAILABLE:
        _logger.remove()
        _logger.add(sys.stderr, level=print_level)
        _logger.add(PROJECT_ROOT / f"logs/{log_name}.log", level=logfile_level)
    else:
        # Configure the standard logging module
        handler = logging.FileHandler(PROJECT_ROOT / f"logs/{log_name}.log")
        handler.setLevel(getattr(logging, logfile_level))
        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )
        handler.setFormatter(formatter)
        _logger.addHandler(handler)

        # Set console level
        _logger.setLevel(getattr(logging, print_level))

    return _logger


def setup_logger(name=None, print_level="INFO", logfile_level="DEBUG"):
    """
    Set up and configure the logger for the application.

    Args:
        name (str, optional): Name prefix for the log file. Defaults to None.
        print_level (str, optional): Log level for console output. Defaults to "INFO".
        logfile_level (str, optional): Log level for file output. Defaults to "DEBUG".

    Returns:
        Logger: Configured logger instance
    """
    return define_log_level(
        print_level=print_level, logfile_level=logfile_level, name=name
    )


logger = define_log_level()


if __name__ == "__main__":
    logger.info("Starting application")
    logger.debug("Debug message")
    logger.warning("Warning message")
    logger.error("Error message")
    logger.critical("Critical message")

    try:
        raise ValueError("Test error")
    except Exception as e:
        logger.exception(f"An error occurred: {e}")
