"""Завод: слайсер-цех чипсов (6x5). Общая станина модулей — factory2.machine."""

import math
import random


def chip(k, name, loc, radius, parent, rnd):
    """Чипс: тонкая волнистая пластинка (седло), а не диск."""
    verts, faces = [], []
    rings, seg = 3, 14
    verts.append((0, 0, 0))
    bend = rnd.uniform(0.25, 0.4) * radius
    for r in range(1, rings + 1):
        rr = radius * r / rings
        for i in range(seg):
            a = math.tau * i / seg
            wob = 1 + 0.08 * math.sin(a * 3 + rnd.uniform(0, 1))
            x, y = rr * math.cos(a) * wob, rr * math.sin(a) * wob
            verts.append((x, y, bend * ((x / radius) ** 2 - (y / radius) ** 2)))
    for i in range(seg):
        faces.append([0, 1 + i, 1 + (i + 1) % seg])
    for r in range(rings - 1):
        a, b = 1 + r * seg, 1 + (r + 1) * seg
        for i in range(seg):
            j = (i + 1) % seg
            faces.append([a + i, b + i, b + j, a + j])
    obj = k.mesh_from(name, verts, faces, loc, "Yellow", parent=parent, smooth=True,
                      rot=(rnd.uniform(-20, 20), rnd.uniform(-20, 20), rnd.uniform(0, 360)))
    mod = obj.modifiers.new("Solid", "SOLIDIFY")
    mod.thickness = 0.02
    mod.offset = 0
    return obj


def slicer(k, root):
    rnd = random.Random(5)
    from .factory2 import machine

    top = machine(k, root, "Yellow", "Red", h=0.6, label="CHIPS x2.5", label_key="NeonYellow")
    # бункер с картошкой
    hopper = k.cylinder("Hopper", 1.0, 1.1, (-1.6, 0.4, top + 0.85), "Steel", radius2=0.45, rot=(180, 0, 0), verts=4,
                        bevel=0.06)
    hopper.parent = root
    hopper.rotation_euler[2] = math.radians(45)
    for p in range(7):
        k.potato(f"HopperPotato{p}", (-1.6 + rnd.uniform(-0.4, 0.4), 0.4 + rnd.uniform(-0.4, 0.4), top + 1.32), 0.36,
                 parent=root, seed=200 + p, low=True)
    k.box("Chute", (0.5, 0.5, 0.5), (-0.95, 0.4, top + 0.25), "Steel", bevel=0.06, parent=root)
    # режущая голова с окном и вращающимся диском
    k.cylinder("HeadHousing", 1.0, 0.6, (0.1, 0.35, top + 0.35), "Chrome", verts=36, bevel=0.08, parent=root)
    k.cylinder("HeadWindow", 0.82, 0.08, (0.1, 0.35, top + 0.68), "Glass", verts=36, bevel=0.0, parent=root)
    blade_group = k.empty("BladeDisc", (0.1, 0.35, top + 0.6), root)
    k.cylinder("Disc", 0.72, 0.06, (0, 0, 0), "MetalDark", verts=36, bevel=0.0, parent=blade_group)
    for i in range(6):
        a = i * 60
        k.box(f"Knife{i}", (0.65, 0.12, 0.04), (math.cos(math.radians(a)) * 0.36, math.sin(math.radians(a)) * 0.36, 0.05),
              "Chrome", bevel=0.01, rot=(0, 0, a + 12), parent=blade_group)
    k.cylinder("Spindle", 0.1, 0.12, (0, 0, 0.08), "Gold", verts=16, bevel=0.02, parent=blade_group)
    k.tag(blade_group, k.spin(blade_group, "Z", turns=4))
    k.motor("Motor", (0.1, 1.1, top + 0.42), parent=root, key="GreenDark", radius=0.34, height=0.9, rot=(-90, 0, 0))
    k.tube("Cable", [(0.1, 2.0, top + 0.2), (0.6, 2.25, top - 0.6), (1.6, 2.3, 0.4)], 0.05, "Black", parent=root)
    # выходной конвейер с чипсами
    k.box("ConveyorBed", (3.0, 0.9, 0.18), (1.85, -0.75, top + 0.05), "Steel", bevel=0.04, parent=root)
    k.box("Belt", (2.9, 0.8, 0.06), (1.85, -0.75, top + 0.17), "Rubber", bevel=0.02, parent=root)
    for side in (-1, 1):
        k.box(f"Guard{side}", (3.0, 0.06, 0.22), (1.85, -0.75 + side * 0.45, top + 0.28), "Chrome", bevel=0.02,
              parent=root)
    for r, x in enumerate((0.45, 3.25)):
        k.cylinder(f"Roller{r}", 0.13, 0.9, (x, -0.75, top + 0.08), "Chrome", rot=(90, 0, 0), verts=16, bevel=0.0,
                   parent=root)
    chips = k.empty("Chips", (0, 0, 0), root)
    for c in range(14):
        chip(k, f"Chip{c}", (0.6 + c * 0.19 + rnd.uniform(-0.05, 0.05), -0.75 + rnd.uniform(-0.25, 0.25), top + 0.23),
             rnd.uniform(0.11, 0.15), chips, rnd)
    k.tag(chips, k.slide(chips, "X", distance=0.19, cycles=2))
    # корзина чипсов в конце линии
    k.lathe("Bin", [(0.0, 0.0), (0.42, 0.0), (0.46, 0.04), (0.55, 0.7), (0.58, 0.72), (0.58, 0.76), (0.5, 0.76),
                    (0.43, 0.08), (0.0, 0.08)], (2.5, -1.9, 0.4), "Blue", segments=28, parent=root, sharp=60)
    for c in range(12):
        a = rnd.uniform(0, math.tau)
        r = rnd.uniform(0, 0.36)
        chip(k, f"BinChip{c}", (2.5 + math.cos(a) * r, -1.9 + math.sin(a) * r, 1.05 + rnd.uniform(0, 0.08)), 0.13,
             root, rnd)
