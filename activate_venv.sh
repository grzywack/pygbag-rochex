#!/bin/bash
# Activation script for pygbag virtual environment

echo "🚀 Activating pygbag virtual environment..."
source venv/bin/activate

echo "✅ Virtual environment activated!"
echo ""
echo "📦 Available commands:"
echo "  pygbag test                    - Run the test game with pygbag"
echo "  python test/main.py            - Run the test game directly"
echo "  python -m pygbag --help test  - Show pygbag help"
echo ""
echo "🌐 When running pygbag, the game will be available at:"
echo "   http://localhost:8000"
echo ""
echo "📝 To deactivate the virtual environment, run: deactivate"