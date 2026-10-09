"""art/palette.json → src/shared/Config/Palette.luau (палитра для игры).

Запускается из build.py при каждой сборке ассетов или отдельно: python3 art/blender/palette_luau.py
"""

import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))


def write(root=ROOT):
    palette = json.load(open(os.path.join(root, "art", "palette.json"), encoding="utf-8"))
    lines = [
        "-- Палитра моделей из Blender: ключ → цвет и материал Roblox.",
        "-- Сгенерировано из art/palette.json (art/blender/palette_luau.py) — правьте JSON, а не этот файл.",
        "",
        "export type Spec = { color: Color3, material: Enum.Material, transparency: number? }",
        "",
        "local Palette: { [string]: Spec } = {",
    ]
    for key, spec in palette.items():
        if key.startswith("_"):
            continue
        r, g, b = spec["color"]
        extra = f", transparency = {spec['transparency']}" if "transparency" in spec else ""
        lines.append(f"\t{key} = {{ color = Color3.fromRGB({r}, {g}, {b}), material = Enum.Material.{spec['roblox']}{extra} }},")
    lines += ["}", "", "return Palette", ""]
    path = os.path.join(root, "src", "shared", "Config", "Palette.luau")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    return path


if __name__ == "__main__":
    print(write())
