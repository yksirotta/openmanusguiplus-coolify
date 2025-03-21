# OpenManus GUI Plus

A modern, feature-rich web dashboard for the OpenManus AI agent framework.

<p align="center">
  <img src="../assets/logo.jpg" width="200"/>
</p>

English | [中文](README_zh.md) | [한국어](README_ko.md) | [日本語](README_ja.md)

[![GitHub stars](https://img.shields.io/github/stars/mannaandpoem/OpenManus?style=social)](https://github.com/mannaandpoem/OpenManus/stargazers)
&ensp;
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) &ensp;
[![Discord Follow](https://dcbadge.vercel.app/api/server/DYn29wFk9z?style=flat)](https://discord.gg/DYn29wFk9z)

# 👋 OpenManus

Manus is incredible, but OpenManus can achieve any idea without an *Invite Code* 🛫!

Our team members [@Xinbin Liang](https://github.com/mannaandpoem) and [@Jinyu Xiang](https://github.com/XiangJinyu) (core authors), along with [@Zhaoyang Yu](https://github.com/MoshiQAQ), [@Jiayi Zhang](https://github.com/didiforgithub), and [@Sirui Hong](https://github.com/stellaHSR), we are from [@MetaGPT](https://github.com/geekan/MetaGPT). The prototype is launched within 3 hours and we are keeping building!

It's a simple implementation, so we welcome any suggestions, contributions, and feedback!

Enjoy your own agent with OpenManus!

We're also excited to introduce [OpenManus-RL](https://github.com/OpenManus/OpenManus-RL), an open-source project dedicated to reinforcement learning (RL)- based (such as GRPO) tuning methods for LLM agents, developed collaboratively by researchers from UIUC and OpenManus.

## Project Demo

<video src="https://private-user-images.githubusercontent.com/61239030/420168772-6dcfd0d2-9142-45d9-b74e-d10aa75073c6.mp4?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NDEzMTgwNTksIm5iZiI6MTc0MTMxNzc1OSwicGF0aCI6Ii82MTIzOTAzMC80MjAxNjg3NzItNmRjZmQwZDItOTE0Mi00NWQ5LWI3NGUtZDEwYWE3NTA3M2M2Lm1wND9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTAzMDclMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwMzA3VDAzMjIzOVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTdiZjFkNjlmYWNjMmEzOTliM2Y3M2VlYjgyNDRlZDJmOWE3NWZhZjE1MzhiZWY4YmQ3NjdkNTYwYTU5ZDA2MzYmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.UuHQCgWYkh0OQq9qsUWqGsUbhG3i9jcZDAMeHjLt5T4" data-canonical-src="https://private-user-images.githubusercontent.com/61239030/420168772-6dcfd0d2-9142-45d9-b74e-d10aa75073c6.mp4?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NDEzMTgwNTksIm5iZiI6MTc0MTMxNzc1OSwicGF0aCI6Ii82MTIzOTAzMC80MjAxNjg3NzItNmRjZmQwZDItOTE0Mi00NWQ5LWI3NGUtZDEwYWE3NTA3M2M2Lm1wND9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTAzMDclMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwMzA3VDAzMjIzOVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTdiZjFkNjlmYWNjMmEzOTliM2Y3M2VlYjgyNDRlZDJmOWE3NWZhZjE1MzhiZWY4YmQ3NjdkNTYwYTU5ZDA2MzYmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.UuHQCgWYkh0OQq9qsUWqGsUbhG3i9jcZDAMeHjLt5T4" controls="controls" muted="muted" class="d-block rounded-bottom-2 border-top width-fit" style="max-height:640px; min-height: 200px"></video>

## Features

- **Intuitive Web Interface**: Modern, responsive UI to interact with OpenManus agents
- **Full Configuration Management**: Configure all aspects of OpenManus directly through the web UI
- **Simplified LLM Integration**: Easy management of LLM models and API keys
- **System Resource Monitoring**: Real-time CPU, RAM, and disk usage visualization
- **Tool Integration**: Access to all OpenManus tools and capabilities through a user-friendly interface

## System Requirements

- **Disk Space**:
  - Standard installation: Minimum 1.5GB free space (recommended 2GB+)
  - Lightweight installation: Minimum 500MB free space
- **Memory**: 1GB RAM minimum (2GB+ recommended)
- **Python**: Version 3.8 or higher
- **Operating System**: Linux, macOS, or Windows

## Installation

We offer multiple installation methods to suit different system constraints:

### Method 1: One-Line Installation

For the quickest installation experience, you can use our one-line wget command:

```bash
# Download the installer script first
wget https://raw.githubusercontent.com/mhm22332/openmanusguiplus/main/install.sh -O install-openmanus.sh

# Make it executable
chmod +x install-openmanus.sh

# Run the installer (standard mode)
./install-openmanus.sh [/path/to/install/directory]

# OR run in lightweight mode (for limited disk space)
./install-openmanus.sh --lightweight [/path/to/install/directory]
```

#### Installation Options

- `--lightweight` or `-l`: Install with minimal dependencies (no ML libraries)
- `--dir <path>` or `-d <path>`: Specify installation directory

The installer will automatically:
- Check available disk space and recommend lightweight mode if needed
- Clone the repository
- Set up a Python virtual environment
- Install dependencies optimized for your system resources
- Configure basic settings
- Create startup and dependency management scripts

### Method 2: Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/mhm22332/openmanusguiplus.git
cd openmanusguiplus
```

2. Create and activate a virtual environment:
```bash
python -m venv .venv
source .venv/bin/activate  # On Linux/Mac
# OR
.venv\Scripts\activate  # On Windows
```

3. Install the required dependencies:
```bash
# For full installation (requires ~1.5GB disk space)
pip install -r requirements.txt

# For lightweight installation (minimal dependencies)
pip install flask flask-socketio flask-cors psutil tomli tomli_w
```

## Running the Dashboard

### Using the Optimized Startup Script (Recommended)

If you used the installer, an optimized startup script was created for you:

```bash
cd openmanusguiplus
./start.sh
```

This script includes memory optimizations that make the dashboard run more efficiently, especially on low-resource systems.

### Manual Startup

```bash
cd openmanusguiplus
source .venv/bin/activate  # On Linux/Mac
# OR
.venv\Scripts\activate  # On Windows
python run_web_app.py
```

## Managing Dependencies

The installer creates a dependency management script to help with maintaining your installation:

```bash
# Show available commands
./manage_deps.sh

# Install AI dependencies after lightweight installation
./manage_deps.sh install-ai

# Install all dependencies
./manage_deps.sh install-full

# Clean pip cache to free disk space
./manage_deps.sh clean-cache

# Check installed dependencies
./manage_deps.sh check
```

## Memory Management Features

OpenManus GUI Plus includes several memory management features to ensure it runs efficiently on all systems:

- **Automatic garbage collection**: The system periodically cleans up unused memory
- **Concurrent request limiting**: Prevents memory spikes by limiting simultaneous operations
- **Memory usage monitoring**: Tracks and displays real-time memory usage in the dashboard
- **Low-memory mode**: Automatically adapts to low-memory conditions
- **Optimized dependency loading**: Loads only necessary packages for each operation

To configure memory settings, edit the `config/config.toml` file:

```toml
[system]
# Lower these values on low-memory systems
max_tokens_limit = 8192  # Maximum token context size
max_concurrent_requests = 2  # Maximum concurrent API requests
lightweight_mode = false  # Set to true to disable advanced features
```

## Dashboard Components

### LLM Configuration

The dashboard provides a user-friendly interface for managing LLM models:

- Add multiple LLM models (OpenAI, Anthropic, Azure, etc.)
- Configure API endpoints and keys securely
- Set temperature, token limits, and other parameters
- Switch between models easily

### System Monitoring

Monitor system resources in real-time:

- CPU usage (overall and per-core)
- Memory usage
- Disk space utilization
- Detailed performance charts and metrics

### Tool Management

Access and configure all OpenManus tools:

- Web browsing and search
- Code execution
- File operations
- Custom integrations

## Troubleshooting

### Common Installation Issues

- **"No space left on device" error**: Use the lightweight installation option with `--lightweight` flag
- **Missing dependencies**: Run `./manage_deps.sh install-ai` to add specific dependencies after installation
- **Import errors when running**: Check which packages are missing and install them individually
- **High memory usage**: Edit the `config/config.toml` file to lower `max_concurrent_requests` and `max_tokens_limit`

## Contributing

Contributions to improve the dashboard are welcome! Please see our main contribution guidelines in the parent repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Community Group
Join our networking group on Feishu and share your experience with other developers!

<div align="center" style="display: flex; gap: 20px;">
    <img src="assets/community_group.jpg" alt="OpenManus 交流群" width="300" />
</div>

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=mannaandpoem/OpenManus&type=Date)](https://star-history.com/#mannaandpoem/OpenManus&Date)

## Acknowledgement

Thanks to [anthropic-computer-use](https://github.com/anthropics/anthropic-quickstarts/tree/main/computer-use-demo)
and [browser-use](https://github.com/browser-use/browser-use) for providing basic support for this project!

Additionally, we are grateful to [AAAJ](https://github.com/metauto-ai/agent-as-a-judge), [MetaGPT](https://github.com/geekan/MetaGPT), [OpenHands](https://github.com/All-Hands-AI/OpenHands) and [SWE-agent](https://github.com/SWE-agent/SWE-agent).

OpenManus is built by contributors from MetaGPT. Huge thanks to this agent community!

## Cite
```bibtex
@misc{openmanus2025,
  author = {Xinbin Liang and Jinyu Xiang and Zhaoyang Yu and Jiayi Zhang and Sirui Hong},
  title = {OpenManus: An open-source framework for building general AI agents},
  year = {2025},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/mannaandpoem/OpenManus}},
}
```
