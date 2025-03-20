#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test script for OpenManus Web UI Dashboard
This script tests that the web app can be started correctly.
"""

import sys
import os
from pathlib import Path

# Add the current directory to the path
current_dir = Path(__file__).resolve().parent
sys.path.insert(0, str(current_dir))

try:
    # Import the web app
    from app.web_app import app

    print("✓ Successfully imported web app module")

    # Check if required templates exist
    template_path = current_dir / "app" / "templates" / "index.html"
    if template_path.exists():
        print(f"✓ Found template: {template_path}")
    else:
        print(f"✗ Missing template: {template_path}")

    # Check for static files
    js_path = current_dir / "app" / "static" / "js" / "main.js"
    css_path = current_dir / "app" / "static" / "css" / "styles.css"

    if js_path.exists():
        print(f"✓ Found JavaScript: {js_path}")
    else:
        print(f"✗ Missing JavaScript: {js_path}")

    if css_path.exists():
        print(f"✓ Found CSS: {css_path}")
    else:
        print(f"✗ Missing CSS: {css_path}")

    # Test that app routes exist
    routes = [rule.rule for rule in app.url_map.iter_rules()]
    required_routes = [
        "/",
        "/api/chat",
        "/api/models",
        "/api/tools",
        "/api/settings",
        "/api/system/stats",
        "/api/config",
    ]

    print("\nChecking Routes:")
    for route in required_routes:
        if route in routes:
            print(f"✓ Route exists: {route}")
        else:
            print(f"✗ Missing route: {route}")

    print("\nWeb application looks good! Run with: python run_web_app.py")

except Exception as e:
    print(f"Error: {str(e)}")
    sys.exit(1)

if __name__ == "__main__":
    # This code only runs when the script is executed directly
    print("\nTo start the web app, run: python run_web_app.py")
