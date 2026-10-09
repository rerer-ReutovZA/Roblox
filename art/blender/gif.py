"""Кадры анимации build/frames/<Ключ>/*.png → art/previews/<Ключ>.gif (12 к/с, по кругу).

  python3 art/blender/gif.py Drone Bug ...   (без аргументов — все папки в build/frames)
"""

import os
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
FRAMES = os.path.join(ROOT, "build", "frames")


def make(key):
    folder = os.path.join(FRAMES, key)
    files = sorted(f for f in os.listdir(folder) if f.endswith(".png"))
    frames = [Image.open(os.path.join(folder, f)).convert("RGB") for f in files]
    # общая палитра на весь ролик — без мерцания цветов между кадрами
    palette = frames[len(frames) // 2].quantize(colors=255, method=Image.Quantize.MEDIANCUT)
    out = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
    path = os.path.join(ROOT, "art", "previews", f"{key}.gif")
    out[0].save(path, save_all=True, append_images=out[1:], duration=83, loop=0, optimize=True, disposal=1)
    print(f"{key}: {len(out)} кадров → {os.path.relpath(path, ROOT)} ({os.path.getsize(path) // 1024} КБ)")


if __name__ == "__main__":
    keys = sys.argv[1:] or sorted(os.listdir(FRAMES))
    for k in keys:
        make(k)
