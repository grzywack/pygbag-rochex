#!/bin/bash
# Game launcher script for Simple Space Shooter

echo "🎮 Simple Space Shooter - Game Launcher"
echo "========================================"
echo ""
echo "Choose how to run the game:"
echo "1) Native Version (runs directly on your system)"
echo "2) Web Version (runs in browser via pygbag)"
echo "3) Exit"
echo ""

# Activate virtual environment
source venv/bin/activate

read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "🚀 Starting Native Version..."
        echo "Close the game window or press ESC to quit"
        python simple_game/main.py
        ;;
    2)
        echo ""
        echo "🌐 Starting Web Version..."
        echo "Game will be available at: http://localhost:8080"
        echo "Press Ctrl+C to stop the server"
        echo ""
        echo "Note: If port 8080 is busy, you can manually run:"
        echo "  python -m pygbag --port 8081 simple_game"
        python -m pygbag --port 8080 simple_game
        ;;
    3)
        echo "Goodbye! 👋"
        exit 0
        ;;
    *)
        echo "Invalid choice. Please run the script again."
        exit 1
        ;;
esac