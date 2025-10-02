# Simple Space Shooter Game

A basic 2D space shooter game built with pygame and pygbag, demonstrating WebAssembly compatibility.

## Game Features

🚀 **Enhanced Space Shooter Gameplay:**
- **Dual Control Modes**: Switch between keyboard and mouse control
- **Smooth Mouse Movement**: Ship follows cursor with fluid motion
- Control a green triangular spaceship
- Shoot yellow bullets 
- Destroy colorful enemy rectangles
- Avoid enemies or take damage
- Starfield background animation
- Health system with visual health bar
- Score tracking
- Game over and restart functionality
- Real-time control mode indicator

## Controls

### Keyboard Mode (Default)
- **WASD** or **Arrow Keys**: Move the spaceship
- **Spacebar**: Shoot bullets

### Mouse Mode
- **Mouse Movement**: Move spaceship smoothly to cursor position
- **Left Click**: Shoot bullets (hold for continuous fire)

### General Controls
- **M**: Toggle between Keyboard and Mouse control modes
- **R**: Restart game (when game over)
- **ESC**: Quit game

## Game Mechanics

- **Health**: Start with 100 health
- **Scoring**: +10 points per enemy destroyed
- **Damage**: -20 health on collision, -5 health per escaped enemy
- **Enemies**: Spawn randomly from the top, move downward at varying speeds
- **Bullets**: Rapid fire with slight delay between shots

## Running the Game

### Option 1: Web Version (Recommended)
```bash
# Run with pygbag for web deployment
pygbag simple_game
```
Then open your browser to: http://localhost:8000

### Option 2: Native Version
```bash
# Run directly with Python
python simple_game/main.py
```

## Technical Details

- **Framework**: pygame + pygbag
- **Resolution**: 800x600 pixels
- **Target FPS**: 60 FPS
- **WebAssembly Compatible**: Uses async/await pattern for browser compatibility
- **Cross-Platform**: Runs natively or in web browsers

## Code Structure

- `main.py`: Complete game implementation
- `pygbag.toml`: Configuration file for pygbag builds
- Async game loop compatible with WebAssembly
- Object-oriented design with Player, Bullet, Enemy, and Star classes
- Collision detection and game state management

## Development Notes

This game demonstrates key concepts for pygbag development:
- Proper async/await usage with `await asyncio.sleep(0)`
- Event handling compatible with web browsers
- Frame rate control using pygame.time.Clock
- Simple 2D graphics using pygame primitives
- Game state management and restart functionality