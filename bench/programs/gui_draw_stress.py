import os
import warnings

os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
warnings.filterwarnings("ignore")

import pygame


def main():
    pygame.init()
    screen = pygame.display.set_mode((800, 600))
    pygame.display.set_caption("Draw Stress Benchmark")
    font = pygame.font.Font(None, 12)

    for _ in range(300):
        pygame.event.pump()
        screen.fill((0, 0, 0))

        for i in range(2000):
            x = (i * 37) % 800
            y = (i * 53) % 600
            c = i % 256
            pygame.draw.rect(screen, (c, 100, 100), (x, y, 10, 10))

        for i in range(500):
            x = (i * 41) % 800
            y = (i * 67) % 600
            c = i % 256
            pygame.draw.circle(screen, (c, 100, 100), (x, y), 5)

        for i in range(200):
            x = (i * 59) % 780
            y = (i * 71) % 580
            text = font.render("Hi", True, (255, 255, 255))
            screen.blit(text, (x, y))

        pygame.display.flip()

    pygame.quit()
    print(300)


if __name__ == "__main__":
    main()
