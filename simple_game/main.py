"""
Simple 2D Game for pygbag
A basic space shooter game demonstrating pygame functionality in WebAssembly
"""

import asyncio
import pygame
import random
import math

# Initialize pygame
pygame.init()

# Game constants
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
FPS = 60

# Colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (255, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)
YELLOW = (255, 255, 0)
CYAN = (0, 255, 255)


class Player:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.width = 30
        self.height = 30
        self.speed = 5
        self.health = 100
        self.score = 0
        self.mouse_control = False  # Toggle between keyboard and mouse control
        
    def update(self, keys, mouse_pos=None):
        if self.mouse_control and mouse_pos:
            # Mouse control - smooth movement towards mouse position
            mouse_x, mouse_y = mouse_pos
            
            # Calculate target position (center ship on mouse)
            target_x = mouse_x - self.width // 2
            target_y = mouse_y - self.height // 2
            
            # Smooth movement towards mouse position
            dx = target_x - self.x
            dy = target_y - self.y
            
            # Move a fraction of the distance each frame for smooth movement
            move_factor = 0.15
            self.x += dx * move_factor
            self.y += dy * move_factor
            
            # Boundary checking
            self.x = max(0, min(SCREEN_WIDTH - self.width, self.x))
            self.y = max(0, min(SCREEN_HEIGHT - self.height, self.y))
        else:
            # Keyboard control (original)
            if keys[pygame.K_LEFT] or keys[pygame.K_a]:
                self.x = max(0, self.x - self.speed)
            if keys[pygame.K_RIGHT] or keys[pygame.K_d]:
                self.x = min(SCREEN_WIDTH - self.width, self.x + self.speed)
            if keys[pygame.K_UP] or keys[pygame.K_w]:
                self.y = max(0, self.y - self.speed)
            if keys[pygame.K_DOWN] or keys[pygame.K_s]:
                self.y = min(SCREEN_HEIGHT - self.height, self.y + self.speed)
                
    def toggle_control_mode(self):
        self.mouse_control = not self.mouse_control
        
    def draw(self, screen):
        # Draw player as a triangle (spaceship)
        points = [(self.x + self.width // 2, self.y), (self.x, self.y + self.height), (self.x + self.width, self.y + self.height)]
        pygame.draw.polygon(screen, GREEN, points)

    def get_rect(self):
        return pygame.Rect(self.x, self.y, self.width, self.height)


class Bullet:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.width = 4
        self.height = 10
        self.speed = 8

    def update(self):
        self.y -= self.speed

    def draw(self, screen):
        pygame.draw.rect(screen, YELLOW, (self.x, self.y, self.width, self.height))

    def get_rect(self):
        return pygame.Rect(self.x, self.y, self.width, self.height)

    def is_off_screen(self):
        return self.y < 0


class Enemy:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.width = 25
        self.height = 25
        self.speed = random.uniform(1, 3)
        self.color = random.choice([RED, BLUE, CYAN])

    def update(self):
        self.y += self.speed

    def draw(self, screen):
        pygame.draw.rect(screen, self.color, (self.x, self.y, self.width, self.height))

    def get_rect(self):
        return pygame.Rect(self.x, self.y, self.width, self.height)

    def is_off_screen(self):
        return self.y > SCREEN_HEIGHT


class Star:
    def __init__(self):
        self.x = random.randint(0, SCREEN_WIDTH)
        self.y = random.randint(0, SCREEN_HEIGHT)
        self.speed = random.uniform(0.5, 2)
        self.size = random.randint(1, 3)

    def update(self):
        self.y += self.speed
        if self.y > SCREEN_HEIGHT:
            self.y = 0
            self.x = random.randint(0, SCREEN_WIDTH)

    def draw(self, screen):
        pygame.draw.circle(screen, WHITE, (int(self.x), int(self.y)), self.size)


class Game:
    def __init__(self):
        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
        pygame.display.set_caption("Simple Space Shooter - pygbag Demo")

        self.clock = pygame.time.Clock()
        self.font = pygame.font.Font(None, 36)
        self.small_font = pygame.font.Font(None, 24)

        # Game objects
        self.player = Player(SCREEN_WIDTH // 2, SCREEN_HEIGHT - 50)
        self.bullets = []
        self.enemies = []
        self.stars = [Star() for _ in range(50)]

        # Game state
        self.game_over = False
        self.last_shot = 0
        self.last_enemy_spawn = 0
        self.shoot_delay = 200  # milliseconds
        self.enemy_spawn_delay = 1000  # milliseconds
        self.mouse_shooting = False  # Track mouse button state
        
    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r and self.game_over:
                    self.restart_game()
                elif event.key == pygame.K_ESCAPE:
                    return False
                elif event.key == pygame.K_m:  # Toggle mouse control
                    self.player.toggle_control_mode()
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:  # Left mouse button
                    self.mouse_shooting = True
            elif event.type == pygame.MOUSEBUTTONUP:
                if event.button == 1:  # Left mouse button
                    self.mouse_shooting = False
        return True
        
    def update(self):
        if self.game_over:
            return

        current_time = pygame.time.get_ticks()
        keys = pygame.key.get_pressed()
        mouse_pos = pygame.mouse.get_pos()
        
        # Update player (pass mouse position for mouse control)
        self.player.update(keys, mouse_pos)
        
        # Shooting (keyboard or mouse)
        should_shoot = (keys[pygame.K_SPACE] or 
                       (self.player.mouse_control and self.mouse_shooting))
        
        if should_shoot and current_time - self.last_shot > self.shoot_delay:
            bullet_x = self.player.x + self.player.width // 2 - 2
            bullet_y = self.player.y
            self.bullets.append(Bullet(bullet_x, bullet_y))
            self.last_shot = current_time        # Spawn enemies
        if current_time - self.last_enemy_spawn > self.enemy_spawn_delay:
            enemy_x = random.randint(0, SCREEN_WIDTH - 25)
            self.enemies.append(Enemy(enemy_x, -25))
            self.last_enemy_spawn = current_time

        # Update stars
        for star in self.stars:
            star.update()

        # Update bullets
        for bullet in self.bullets[:]:
            bullet.update()
            if bullet.is_off_screen():
                self.bullets.remove(bullet)

        # Update enemies
        for enemy in self.enemies[:]:
            enemy.update()
            if enemy.is_off_screen():
                self.enemies.remove(enemy)
                self.player.health -= 5  # Lose health if enemy escapes

        # Check collisions
        self.check_collisions()

        # Check game over
        if self.player.health <= 0:
            self.game_over = True

    def check_collisions(self):
        # Bullet-enemy collisions
        for bullet in self.bullets[:]:
            for enemy in self.enemies[:]:
                if bullet.get_rect().colliderect(enemy.get_rect()):
                    self.bullets.remove(bullet)
                    self.enemies.remove(enemy)
                    self.player.score += 10
                    break

        # Player-enemy collisions
        player_rect = self.player.get_rect()
        for enemy in self.enemies[:]:
            if player_rect.colliderect(enemy.get_rect()):
                self.enemies.remove(enemy)
                self.player.health -= 20

    def draw(self):
        # Clear screen with space background
        self.screen.fill(BLACK)

        # Draw stars
        for star in self.stars:
            star.draw(self.screen)

        if not self.game_over:
            # Draw game objects
            self.player.draw(self.screen)

            for bullet in self.bullets:
                bullet.draw(self.screen)

            for enemy in self.enemies:
                enemy.draw(self.screen)

        # Draw UI
        self.draw_ui()

        pygame.display.flip()

    def draw_ui(self):
        # Health bar
        health_width = int((self.player.health / 100) * 200)
        health_color = GREEN if self.player.health > 50 else (RED if self.player.health > 25 else RED)
        pygame.draw.rect(self.screen, health_color, (10, 10, health_width, 20))
        pygame.draw.rect(self.screen, WHITE, (10, 10, 200, 20), 2)

        # Score
        score_text = self.small_font.render(f"Score: {self.player.score}", True, WHITE)
        self.screen.blit(score_text, (10, 40))

        # Instructions and control mode
        if not self.game_over:
            control_mode = "Mouse" if self.player.mouse_control else "Keyboard"
            if self.player.mouse_control:
                controls_text = self.small_font.render(f"Mode: {control_mode} | Mouse: Move, Left Click: Shoot, M: Toggle, ESC: Quit", True, WHITE)
            else:
                controls_text = self.small_font.render(f"Mode: {control_mode} | WASD/Arrows: Move, Space: Shoot, M: Toggle, ESC: Quit", True, WHITE)
            self.screen.blit(controls_text, (10, SCREEN_HEIGHT - 30))
        else:
            # Game over screen
            game_over_text = self.font.render("GAME OVER!", True, RED)
            score_text = self.font.render(f"Final Score: {self.player.score}", True, WHITE)
            restart_text = self.small_font.render("Press R to restart or ESC to quit", True, WHITE)

            # Center the text
            go_rect = game_over_text.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 - 50))
            score_rect = score_text.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2))
            restart_rect = restart_text.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 50))

            self.screen.blit(game_over_text, go_rect)
            self.screen.blit(score_text, score_rect)
            self.screen.blit(restart_text, restart_rect)

    def restart_game(self):
        self.player = Player(SCREEN_WIDTH // 2, SCREEN_HEIGHT - 50)
        self.bullets = []
        self.enemies = []
        self.game_over = False
        self.last_shot = 0
        self.last_enemy_spawn = 0


async def main():
    game = Game()
    running = True

    print("🚀 Starting Simple Space Shooter!")
    print("Controls:")
    print("  Keyboard Mode (default):")
    print("    WASD or Arrow Keys - Move")
    print("    Spacebar - Shoot")
    print("  Mouse Mode:")
    print("    Mouse - Move ship to cursor")
    print("    Left Click - Shoot")
    print("  General:")
    print("    M - Toggle between Keyboard/Mouse control")
    print("    R - Restart (when game over)")
    print("    ESC - Quit")

    while running:
        # Handle events
        running = game.handle_events()

        # Update game state
        game.update()

        # Draw everything
        game.draw()

        # Control frame rate
        game.clock.tick(FPS)

        # Essential for pygbag - yield control to browser
        await asyncio.sleep(0)

    pygame.quit()


# Run the game
if __name__ == "__main__":
    asyncio.run(main())
