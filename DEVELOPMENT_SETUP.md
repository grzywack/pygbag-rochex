# pygbag Development Environment

## Setup Complete! ✅

Your pygbag development environment has been successfully set up with:

### ✅ Virtual Environment Created
- Location: `./venv/`
- Python version: 3.12.3
- All dependencies installed

### ✅ Dependencies Installed
- **Core pygbag dependencies**: token_utils, pyparsing, packaging, installer, black
- **pygame**: For game development and testing
- **Optional simulation tools**: aioconsole, aiohttp, asyncio_socks_server
- **pygbag**: Installed in development mode

## Quick Start

### 1. Activate the virtual environment:
```bash
source activate_venv.sh
```
Or manually:
```bash
source venv/bin/activate
```

### 2. Run the test game:
```bash
# Using pygbag (recommended for web deployment)
pygbag test

# Or run directly for native testing
python test/main.py
```

### 3. Access the web game:
When using pygbag, open your browser to:
- **http://localhost:8000**

## Available Commands

### pygbag Commands:
```bash
# Run with default settings
pygbag test

# Show help
python -m pygbag --help test

# Build only (no server)
pygbag --build test

# Custom port
pygbag --port 8080 test

# Archive for itch.io
pygbag --archive test
```

### Development Commands:
```bash
# Run native version
python test/main.py

# Check pygbag version
python -c "import pygbag; print(pygbag.VERSION)"

# Deactivate virtual environment
deactivate
```

## Project Structure
```
pygbag-rochex/
├── venv/                 # Virtual environment
├── src/pygbag/          # Main pygbag source code
├── test/                # Test game
│   ├── main.py         # Test game entry point
│   └── img/            # Game assets
├── static/             # Web templates
└── activate_venv.sh    # Environment activation script
```

## Notes
- The test game requires pygame and demonstrates WebAssembly compatibility
- pygbag converts Python games to run in web browsers
- The virtual environment contains all necessary dependencies
- Use `pygbag` for web deployment, `python test/main.py` for native testing

## Troubleshooting
- If commands don't work, ensure the virtual environment is activated
- Check that all dependencies are installed with `pip list`
- Ensure pygame works with `python -c "import pygame; print('OK')"`