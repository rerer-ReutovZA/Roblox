#!/usr/bin/env python3
"""Проверка экспортированных FBX (art/export/fbx/*.fbx) — то, что увидит 3D Importer Roblox.

Имена объектов читаются прямо из двоичного FBX и сверяются с правилами игры:
  * корень — пустышка с именем файла (BedWood.fbx → BedWood);
  * ровно по одному калибровочному маркеру Origin__Pivot, Origin__AxisX, Origin__AxisZ;
  * детали «Путь/Группы__КлючПалитры[~n][!надпись]», ключ есть в art/palette.json;
  * не длиннее 50 символов (Importer обрезает длинные имена посередине);
  * без суффиксов Blender «.001» и без повторов;
  * группы из src/shared/Config/AssetMeta.luau существуют в файле, надписи — в ModelText.luau.

    python3 tools/check_fbx.py            # все файлы
    python3 tools/check_fbx.py BedWood    # выборочно
"""

import json
import os
import re
import struct
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
FBX_DIR = os.path.join(ROOT, "art", "export", "fbx")
MAX_NAME = 50
NAME = re.compile(r"^(?P<path>[A-Za-z0-9_\-/]+?)__(?P<key>[A-Za-z0-9]+)(?:~(?P<dup>\d+))?(?:!(?P<label>\d+))?$")


def fbx_models(path):
    """Пары (имя, тип) узлов Model: свойство-строка «Имя\\x00\\x01Model», за ним строка типа (Null, Mesh…)."""
    data = open(path, "rb").read()
    if not data.startswith(b"Kaydara FBX Binary"):
        raise ValueError("не двоичный FBX")
    out = []
    for m in re.finditer(rb"\x00\x01Model", data):
        end = m.start()
        # перед именем: 'S' + uint32 длина (имя + 7 байт «\x00\x01Model»)
        for start in range(end, max(end - 300, 0), -1):
            if data[start - 5:start - 4] == b"S" and struct.unpack("<I", data[start - 4:start])[0] == end - start + 7:
                name = data[start:end].decode("utf-8", "replace")
                after = m.end()
                kind = ""
                if data[after:after + 1] == b"S":
                    n = struct.unpack("<I", data[after + 1:after + 5])[0]
                    kind = data[after + 5:after + 5 + n].decode("utf-8", "replace")
                out.append((name, kind))
                break
    return out


def asset_meta():
    """Config/AssetMeta.luau → {ключ модели: {путь группы}}."""
    text = open(os.path.join(ROOT, "src", "shared", "Config", "AssetMeta.luau"), encoding="utf-8").read()
    meta, current = {}, None
    for line in text.splitlines():
        m = re.match(r"^\t(\w+) = \{$", line)
        if m:
            current = meta.setdefault(m.group(1), set())
            continue
        m = re.match(r'^\t\t\["([^"]*)"\] = \{ anim = "([^"]+)"', line)
        if m and current is not None:
            current.add(m.group(1))
    return meta


def model_text():
    """Config/ModelText.luau → {ключ модели: {номера надписей}}."""
    text = open(os.path.join(ROOT, "src", "shared", "Config", "ModelText.luau"), encoding="utf-8").read()
    labels, current = {}, None
    for line in text.splitlines():
        m = re.match(r"^\t(\w+) = \{$", line)
        if m:
            current = labels.setdefault(m.group(1), set())
            continue
        m = re.match(r"^\t\t\[(\d+)\] = ", line)
        if m and current is not None:
            current.add(int(m.group(1)))
    return labels


def check(key, palette, meta, texts):
    errors = []
    models = fbx_models(os.path.join(FBX_DIR, f"{key}.fbx"))
    names = [n for n, _ in models]
    nulls = [n for n, kind in models if kind == "Null"]
    meshes = [n for n, kind in models if kind == "Mesh"]
    if nulls != [key]:
        errors.append(f"корень должен быть одной пустышкой «{key}», а не {nulls}")
    for marker in ("Origin__Pivot", "Origin__AxisX", "Origin__AxisZ"):
        if meshes.count(marker) != 1:
            errors.append(f"{marker}: {meshes.count(marker)} шт. (нужен ровно один)")
    seen, paths, labels = set(), set(), set()
    for name in names:
        if name in seen:
            errors.append(f"повтор имени: {name}")
        seen.add(name)
        if len(name) > MAX_NAME:
            errors.append(f"длиннее {MAX_NAME} символов ({len(name)}): {name}")
        if re.search(r"\.\d+$", name):
            errors.append(f"суффикс Blender: {name}")
    for name in meshes:
        if name.startswith("Origin__"):
            continue
        m = NAME.match(name)
        if not m:
            errors.append(f"имя не в формате Путь__Ключ[~n][!n]: {name}")
            continue
        if m.group("key") not in palette:
            errors.append(f"ключа {m.group('key')} нет в art/palette.json: {name}")
        path = m.group("path")
        paths.add("" if path == "Body" else path)
        # промежуточные группы тоже существуют (DroneBody для DroneBody/Prop0)
        parts = path.split("/")
        for i in range(1, len(parts)):
            paths.add("/".join(parts[:i]))
        if m.group("label"):
            labels.add(int(m.group("label")))
    for group in sorted(meta.get(key, ())):
        if group not in paths:
            errors.append(f"группа {group} из AssetMeta.luau не найдена среди деталей")
    for n in sorted(labels):
        if n not in texts.get(key, ()):
            errors.append(f"надпись !{n} без текста в ModelText.luau")
    return len(meshes), errors


def main():
    palette = json.load(open(os.path.join(ROOT, "art", "palette.json"), encoding="utf-8"))
    meta, texts = asset_meta(), model_text()
    keys = sys.argv[1:] or sorted(f[:-4] for f in os.listdir(FBX_DIR) if f.endswith(".fbx"))
    bad, total = 0, 0
    for key in keys:
        count, errors = check(key, palette, meta, texts)
        total += count
        if errors:
            bad += 1
            print(f"✗ {key}")
            for e in errors[:12]:
                print(f"    {e}")
            if len(errors) > 12:
                print(f"    … ещё {len(errors) - 12}")
    missing = sorted(set(meta) - set(keys)) if not sys.argv[1:] else []
    for key in missing:
        bad += 1
        print(f"✗ {key}: есть в AssetMeta.luau, но нет FBX")
    print(f"{'✓' if not bad else '✗'} FBX: {len(keys)} файлов, {total} деталей, с ошибками: {bad}")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
