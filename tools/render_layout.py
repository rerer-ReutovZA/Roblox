"""Рисует план базы 80x80 сверху (docs/layout.png) по выводу tools/layout.luau.

Использование: python3 tools/render_layout.py [путь к luau]
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SCALE = 12  # пикселей на стад
MARGIN = 40
SECTORS = [
    ("СЕКТОР 1: АГРО-БЛОК", 14, 40, (120, 175, 90)),
    ("СЕКТОР 3: ЭНЕРГЕТИКА И ДРОНЫ", -2, 14, (110, 112, 120)),
    ("СЕКТОР 2: ЗАВОД ПЕРЕРАБОТКИ", -22, -2, (175, 175, 170)),
    ("СЕКТОР 4: НАУКА И КОСМОДРОМ", -40, -22, (215, 222, 235)),
]
COLORS = {
    "Agro": (60, 140, 60),
    "Energy": (40, 110, 190),
    "Factory": (200, 120, 40),
    "Science": (140, 80, 200),
}


def font(size):
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                 "/usr/share/fonts/dejavu/DejaVuSans.ttf"):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def to_px(x, z):
    # вход (z = +40) снизу картинки, как на схеме в ГДД
    return MARGIN + (x + 40) * SCALE, MARGIN + (z + 40) * SCALE


def main():
    luau = sys.argv[1] if len(sys.argv) > 1 else "luau"
    out = subprocess.run([luau, str(ROOT / "tools/layout.luau"), "-a", "dump"], capture_output=True, text=True,
                         check=True).stdout
    size = 80 * SCALE + MARGIN * 2
    img = Image.new("RGB", (size, size + 30), (40, 44, 52))
    draw = ImageDraw.Draw(img)
    small, mid = font(10), font(14)
    for name, z0, z1, color in SECTORS:
        x0, y0 = to_px(-40, z0)
        x1, y1 = to_px(40, z1)
        draw.rectangle([x0, y0, x1, y1], fill=color)
        draw.text((x0 + 6, y0 + 4), name, fill=(30, 30, 30), font=mid)
    px0, py0 = to_px(-3, -40)
    px1, py1 = to_px(3, 40)
    draw.rectangle([px0, py0, px1, py1], fill=(140, 140, 145))
    for line in out.splitlines():
        parts = line.split()
        if parts[0] != "RECT":
            continue
        kind, ident = parts[1], parts[2]
        x0, z0, x1, z1 = map(float, parts[3:7])
        sector = parts[7]
        a = to_px(x0, z0)
        b = to_px(x1, z1)
        if kind == "item":
            draw.rectangle([a, b], fill=COLORS.get(sector, (90, 90, 90)), outline=(20, 20, 20))
            draw.text((a[0] + 2, a[1] + 2), ident, fill=(255, 255, 255), font=small)
        elif kind == "overlay":
            draw.rectangle([a, b], outline=(255, 255, 255), width=1)
        elif kind == "button":
            draw.rectangle([a, b], outline=(60, 230, 90), width=2)
        elif kind == "vip":
            draw.rectangle([a, b], outline=(255, 205, 40), width=2)
    draw.text((MARGIN, size + 4), "ВХОД ДЛЯ ИГРОКА ↓   зелёные рамки — кнопки покупки, жёлтые — VIP", fill=(255, 255, 255),
              font=mid)
    target = ROOT / "docs/layout.png"
    target.parent.mkdir(exist_ok=True)
    img.save(target)
    print(f"Сохранено: {target}")


if __name__ == "__main__":
    main()
