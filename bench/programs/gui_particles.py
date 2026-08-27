import os
import warnings

os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
warnings.filterwarnings("ignore")

import pygame


class Particle:
    def __init__(self, i):
        self.x = (i * 37) % 800
        self.y = (i * 53) % 600
        self.vx = ((i * 17) % 5) - 2
        self.vy = ((i * 13) % 5) - 2
        self.r = (i * 7) % 256
        self.g = (i * 11) % 256
        self.b = (i * 13) % 256

    def update(self):
        self.x = self.x + self.vx
        self.y = self.y + self.vy
        if self.x > 800:
            self.x = self.x - 800
        if self.x < 0:
            self.x = self.x + 800
        if self.y > 600:
            self.y = self.y - 600
        if self.y < 0:
            self.y = self.y + 600

    def draw(self, screen):
        pygame.draw.circle(screen, (self.r, self.g, self.b), (int(self.x), int(self.y)), 3)


def main():
    pygame.init()
    screen = pygame.display.set_mode((800, 600))
    pygame.display.set_caption("Particle Simulation")

    particles = []
    for i in range(1000):
        particles.append(Particle(i))

    for _ in range(500):
        pygame.event.pump()
        screen.fill((0, 0, 0))

        for i in range(1000):
            particles[i].update()
            particles[i].draw(screen)

        pygame.display.flip()

    pygame.quit()
    print(500)


if __name__ == "__main__":
    main()
