"""Агро-блок: грядки, лоток скупщика, авто-вышка, авто-грядка, спринклер."""

import math
import random

from mathutils import Vector, noise


# ----------------------------------------------------------------------
# Общие детали грядок
# ----------------------------------------------------------------------
def soil_surface(k, parent, w, d, z, seed=0):
    """Неровная почва с двумя бороздами вдоль Y."""
    nx, ny = 14, 20
    verts, faces = [], []
    for j in range(ny + 1):
        for i in range(nx + 1):
            x = -w / 2 + w * i / nx
            y = -d / 2 + d * j / ny
            ridge = 0.12 * math.cos(x / (w / 2) * math.pi * 1.5) ** 2
            edge = min(1.0, (w / 2 - abs(x)) * 6, (d / 2 - abs(y)) * 6)
            h = (ridge + noise.noise(Vector((x * 2.1 + seed, y * 2.1, 0.0))) * 0.05) * edge
            verts.append((x, y, h))
    for j in range(ny):
        for i in range(nx):
            a = j * (nx + 1) + i
            faces.append([a, a + 1, a + nx + 2, a + nx + 1])
    k.mesh_from("Soil", verts, faces, (0, 0, z), "Soil", parent=parent, smooth=True)
    k.box("SoilBase", (w, d, 0.3), (0, 0, z - 0.17), "SoilDark", bevel=0.02, parent=parent)


def plants_and_tubers(k, root, d, z, seed=0, scale=1.0):
    """Три куста картофеля («Bush») и клубни у их основания («Tubers»)."""
    bush = k.empty("Bush", (0, 0, z), root)
    tubers = k.empty("Tubers", (0, 0, z), root)
    rnd = random.Random(seed)
    for i, y in enumerate((-d / 3, 0, d / 3)):
        # внешняя пустышка не повёрнута — ось покачивания совпадает с осью модели в игре
        sway = k.empty(f"Plant{i}", (rnd.uniform(-0.1, 0.1), y, 0.05), bush)
        plant = k.potato_plant(f"PlantBody{i}", (0, 0, 0), sway, seed=seed * 10 + i, scale=scale)
        plant.rotation_euler[2] = rnd.uniform(0, math.tau)
        k.tag(sway, k.swing(sway, "X", degrees=2.5, cycles=1, phase=0.15 + i * 0.3))
        for t in range(3):
            a = t / 3 * math.tau + rnd.uniform(-0.4, 0.4)
            k.potato(f"Tuber{i}_{t}", (math.cos(a) * 0.7, y + math.sin(a) * 0.55, 0.06), rnd.uniform(0.42, 0.55),
                     parent=tubers, seed=seed * 100 + i * 10 + t)
    return bush, tubers


# ----------------------------------------------------------------------
# Грядки этапа 1
# ----------------------------------------------------------------------
def bed_wood(k, root):
    rnd = random.Random(11)
    w, d = 4.0, 6.0
    t = 0.3
    for row, z in enumerate((0.22, 0.62)):
        for side in (-1, 1):
            k.box(f"PlankL{row}{side}", (t, d - 0.3, 0.38), (side * (w / 2 - t / 2), 0, z),
                  "Wood" if (row + side) % 2 else "WoodLight", bevel=0.05,
                  rot=(rnd.uniform(-1, 1), 0, rnd.uniform(-0.6, 0.6)), parent=root)
            k.box(f"PlankS{row}{side}", (w - 0.62, t, 0.38), (0, side * (d / 2 - t / 2), z),
                  "WoodLight" if (row + side) % 2 else "Wood", bevel=0.05,
                  rot=(0, rnd.uniform(-1, 1), rnd.uniform(-0.6, 0.6)), parent=root)
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.box(f"Post{sx}{sy}", (0.38, 0.38, 0.95), (sx * (w / 2 - 0.19), sy * (d / 2 - 0.19), 0.475), "WoodDark",
                  bevel=0.07, parent=root)
            k.lathe(f"PostCap{sx}{sy}", [(0.27, 0), (0.27, 0.04), (0.0, 0.16)], (sx * (w / 2 - 0.19), sy * (d / 2 - 0.19), 0.95),
                    "WoodDark", segments=4, rot=(0, 0, 45), parent=root, sharp=30)
            for nz in (0.22, 0.62):
                k.lens(f"Nail{sx}{sy}{nz}", 0.035, (sx * (w / 2 - 0.42), sy * (d / 2 + 0.005), nz), "MetalDark",
                       rot=(-90 * sy, 0, 0), parent=root)
    soil_surface(k, root, w - 0.6, d - 0.6, 0.72, seed=1)
    plants_and_tubers(k, root, d, 0.8, seed=1)


def bed_stone(k, root):
    rnd = random.Random(21)
    w, d = 4.0, 6.0
    keys = ("Stone", "StoneLight", "StoneDark")
    n = 0

    def stone(x, y, z, length, along_y):
        nonlocal n
        size = (0.52, length, 0.5) if along_y else (length, 0.52, 0.5)
        k.blob(f"Stone{n}", size, (x, y, z), rnd.choice(keys), parent=root, jitter=0.12, seed=n, segments=8,
               rings=5, levels=1, rot=(rnd.uniform(-4, 4), rnd.uniform(-4, 4), rnd.uniform(-3, 3)))
        n += 1

    for course, (z, offset) in enumerate(((0.25, 0.0), (0.7, 0.45))):
        for side in (-1, 1):
            y = -d / 2 + offset
            while y < d / 2 - 0.25:
                length = min(rnd.uniform(0.95, 1.35), d / 2 - y)
                stone(side * (w / 2 - 0.26), y + length / 2, z, length + 0.08, True)
                y += length
            x = -w / 2 + 0.52 + offset * 0.5
            while x < w / 2 - 0.6:
                length = min(rnd.uniform(0.85, 1.2), w / 2 - 0.52 - x)
                stone(x + length / 2, side * (d / 2 - 0.26), z, length + 0.08, False)
                x += length
    soil_surface(k, root, w - 1.0, d - 1.0, 0.88, seed=2)
    plants_and_tubers(k, root, d - 0.4, 0.96, seed=2)


def bed_metal(k, root):
    w, d, h = 4.0, 6.0, 1.1
    for side in (-1, 1):
        k.box(f"WallL{side}", (0.14, d, h), (side * (w / 2 - 0.07), 0, h / 2), "Steel", bevel=0.03, parent=root)
        k.box(f"WallS{side}", (w - 0.28, 0.14, h), (0, side * (d / 2 - 0.07), h / 2), "Steel", bevel=0.03, parent=root)
        k.box(f"HeatGrill{side}", (0.06, d - 0.8, 0.26), (side * (w / 2 + 0.01), 0, 0.42), "MetalDark", bevel=0.02,
              parent=root)
        for g in range(9):
            k.box(f"HeatGlow{side}{g}", (0.04, 0.42, 0.14), (side * (w / 2 + 0.03), -2.2 + g * 0.55, 0.42),
                  "NeonOrange", bevel=0.01, parent=root)
        for r in range(7):
            k.lens(f"Rivet{side}{r}", 0.05, (side * (w / 2 + 0.005), -2.7 + r * 0.9, 0.95), "Chrome",
                   rot=(0, 90 * side, 0), parent=root)
    k.tube("Rim", [(-w / 2, -d / 2, h), (w / 2, -d / 2, h), (w / 2, d / 2, h), (-w / 2, d / 2, h), (-w / 2, -d / 2, h)],
           0.08, "MetalDark", parent=root, smooth_path=False)
    k.box("ControlBox", (0.9, 0.4, 0.7), (1.1, -d / 2 - 0.2, 0.55), "MetalDark", bevel=0.06, parent=root)
    k.cylinder("Gauge", 0.2, 0.06, (1.1, -d / 2 - 0.42, 0.62), "White", rot=(90, 0, 0), verts=24, bevel=0.0, parent=root)
    k.torus("GaugeRim", 0.21, 0.035, (1.1, -d / 2 - 0.43, 0.62), "Chrome", rot=(90, 0, 0), parent=root)
    k.box("GaugeNeedle", (0.03, 0.02, 0.17), (1.13, -d / 2 - 0.46, 0.66), "Red", bevel=0.0, rot=(0, -35, 0), parent=root)
    lamp = k.lens("HeatLamp", 0.08, (0.8, -d / 2 - 0.4, 0.35), "NeonOrange", rot=(90, 0, 0), parent=root)
    k.tag(lamp, "pulse_2")
    soil_surface(k, root, w - 0.3, d - 0.3, 1.0, seed=3)
    plants_and_tubers(k, root, d, 1.08, seed=3)


# ----------------------------------------------------------------------
# Лоток скупщика (7x6). Скупщика игра ставит отдельно — настоящий аватар Roblox.
# ----------------------------------------------------------------------
def crate(k, name, loc, parent, w=1.4, d=1.0, h=0.7, seed=0, potatoes=True):
    c = k.empty(name, loc, parent)
    rnd = random.Random(seed)
    for side in (-1, 1):
        for s in range(2):
            z = 0.15 + s * 0.32
            k.box(f"SlatF{side}{s}", (w, 0.08, 0.24), (0, side * (d / 2 - 0.04), z), "WoodLight", bevel=0.025,
                  parent=c, rot=(0, 0, rnd.uniform(-0.8, 0.8)))
            k.box(f"SlatS{side}{s}", (0.08, d - 0.16, 0.24), (side * (w / 2 - 0.04), 0, z), "WoodLight", bevel=0.025,
                  parent=c)
        for x in (-1, 1):
            k.box(f"Corner{side}{x}", (0.12, 0.12, h), (x * (w / 2 - 0.06), side * (d / 2 - 0.06), h / 2), "Wood",
                  bevel=0.03, parent=c)
    k.box("Bottom", (w - 0.1, d - 0.1, 0.06), (0, 0, 0.05), "Wood", bevel=0.01, parent=c)
    if potatoes:
        n = 0
        for cols, rows, z in ((4, 3, 0.4), (3, 2, 0.6), (2, 1, 0.78)):
            for i in range(cols):
                for j in range(rows):
                    x = (i - (cols - 1) / 2) * (w - 0.3) / max(cols, 2) * 1.05
                    y = (j - (rows - 1) / 2) * (d - 0.3) / max(rows, 2) * 1.05
                    k.potato(f"P{n}", (x + rnd.uniform(-0.05, 0.05), y + rnd.uniform(-0.05, 0.05), z),
                             rnd.uniform(0.32, 0.4), parent=c, seed=seed * 50 + n, low=True)
                    n += 1
    return c


def sell_stand(k, root):
    rnd = random.Random(31)
    counter = k.empty("CounterGroup", (0, -2.2, 0), root)
    for i in range(11):
        x = -3.1 + i * 0.62
        k.box(f"Board{i}", (0.6, 0.12, 1.35), (x, -0.62, 0.72), "WoodLight" if i % 2 else "Wood", bevel=0.04,
              rot=(rnd.uniform(-1, 1), 0, 0), parent=counter)
    k.box("Counter", (6.6, 1.3, 1.3), (0, 0, 0.7), "Wood", bevel=0.05, parent=counter)
    k.box("CounterTop", (6.9, 1.55, 0.16), (0, -0.05, 1.42), "WoodDark", bevel=0.05, parent=counter)
    k.box("SignBoard", (4.2, 0.1, 0.62), (0, -0.72, 0.95), "Yellow", bevel=0.05, parent=counter)
    k.text("SignText", "СКУПКА КАРТОФЕЛЯ", 0.36, (0, -0.79, 0.93), "WoodDark", extrude=0.03, parent=counter,
           max_width=3.9)
    # весы и касса
    k.lathe("ScaleBase", [(0.36, 0), (0.36, 0.06), (0.28, 0.16), (0.08, 0.2), (0.0, 0.2)], (-2.3, -0.1, 1.5),
            "MetalDark", parent=counter)
    k.cylinder("ScaleColumn", 0.06, 0.55, (-2.3, -0.1, 1.95), "Chrome", verts=12, bevel=0.0, parent=counter)
    pan = k.empty("ScalePan", (-2.3, -0.1, 2.22), counter)
    k.lathe("Pan", [(0.0, 0), (0.25, 0.0), (0.45, 0.06), (0.52, 0.14), (0.5, 0.15), (0.43, 0.08), (0.0, 0.03)],
            (0, 0, 0), "Chrome", parent=pan, sharp=70)
    for p in range(3):
        k.potato(f"PanPotato{p}", ((p - 1) * 0.22, (p % 2) * 0.1, 0.16), 0.34, parent=pan, seed=70 + p, low=True)
    k.tag(pan, k.bob(pan, amplitude=0.03, cycles=2))
    k.box("Register", (0.8, 0.6, 0.45), (2.2, 0.1, 1.73), "BlueDark", bevel=0.1, parent=counter)
    k.box("RegisterScreen", (0.5, 0.06, 0.2), (2.2, -0.21, 1.86), "NeonGreen", bevel=0.02, rot=(-20, 0, 0),
          parent=counter)
    for r in range(2):
        for c in range(3):
            k.box(f"Key{r}{c}", (0.1, 0.1, 0.04), (2.05 + c * 0.15, -0.05 - r * 0.13, 1.97), "White", bevel=0.015,
                  parent=counter)
    # столбы и навес
    front_h, back_h = 5.1, 5.7
    for x in (-3.15, 3.15):
        k.box(f"PostFront{x}", (0.3, 0.3, front_h), (x, -2.85, front_h / 2), "WoodDark", bevel=0.06, parent=root)
        k.box(f"PostBack{x}", (0.3, 0.3, back_h), (x, 2.6, back_h / 2), "WoodDark", bevel=0.06, parent=root)
        k.tube(f"Beam{x}", [(x, -3.0, front_h - 0.05), (x, 2.75, back_h - 0.05)], 0.11, "Wood", parent=root,
               smooth_path=False)
        k.lathe(f"PostTop{x}", [(0.2, 0), (0.2, 0.04), (0.0, 0.18)], (x, -2.85, front_h), "WoodDark", segments=4,
                rot=(0, 0, 45), parent=root, sharp=30)
    stripes = 9
    sw = 7.2 / stripes
    for s in range(stripes):
        x = -3.6 + sw * (s + 0.5)
        key = "FabricRed" if s % 2 == 0 else "FabricWhite"
        verts, faces = [], []
        rows = 8
        for r in range(rows + 1):
            t = r / rows
            y = -3.25 + t * 6.0
            z = front_h + 0.08 + t * 0.6 - math.sin(t * math.pi) * 0.16
            verts += [(-sw / 2, y, z), (sw / 2, y, z)]
        for r in range(rows):
            a = r * 2
            faces.append([a, a + 1, a + 3, a + 2])
        # фестон: полукруглый язычок свисает спереди
        base_z = front_h + 0.08
        arc = [(math.cos(a) * sw / 2, math.sin(a) * 0.32) for a in [math.pi * i / 8 for i in range(9)]]
        start = len(verts)
        for ax, az in arc:
            verts.append((ax, -3.25, base_z - az))
        center = len(verts)
        verts.append((0, -3.25, base_z))
        for i in range(8):
            faces.append([center, start + i + 1, start + i])
        canvas = k.mesh_from(f"Awning{s}", verts, faces, (x, 0, 0), key, parent=root, smooth=True)
        mod = canvas.modifiers.new("Solid", "SOLIDIFY")
        mod.thickness = 0.06
    # ящики, мешки
    crate(k, "Crate1", (-2.1, 1.3, 0), root, seed=1)
    crate(k, "Crate2", (-0.4, 1.4, 0), root, seed=2)
    crate(k, "Crate3", (-1.2, 1.35, 0.72), root, seed=3, w=1.2, d=0.9)
    for i, (x, y) in enumerate(((2.2, 1.5), (2.95, 0.55))):
        k.sack(f"Sack{i}", (x, y, 0), 1.6, parent=root, seed=i)
        for p in range(3):
            k.potato(f"SackPotato{i}{p}", (x + (p - 1) * 0.16, y + (p % 2) * 0.1, 1.82), 0.3, parent=root,
                     seed=80 + i * 5 + p, low=True)
    # меловая доска с ценой
    board = k.empty("PriceBoardGroup", (2.75, -3.05, 1.2), root, rot=(-12, 0, 0))
    k.box("PriceBoard", (1.3, 0.08, 0.9), (0, 0, 0), "Black", bevel=0.03, parent=board)
    k.box("PriceFrame", (1.42, 0.06, 1.02), (0, 0.04, 0), "Wood", bevel=0.03, parent=board)
    k.text("PriceText", "$1 / шт", 0.3, (0, -0.06, 0), "White", extrude=0.02, parent=board, max_width=1.1)
    for x in (-0.5, 0.5):
        k.box(f"EaselLeg{x}", (0.08, 0.08, 1.6), (x, 0.1, -0.42), "WoodDark", bevel=0.02, parent=board)


# ----------------------------------------------------------------------
# Авто-вышка сбора (6x6, ~14 стадов)
# ----------------------------------------------------------------------
def harvest_tower(k, root):
    h = 10.5
    base, top = 2.45, 1.3
    legs = {}
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.box(f"Footing{sx}{sy}", (0.9, 0.9, 0.35), (sx * base, sy * base, 0.17), "Concrete", bevel=0.06, parent=root)
            a = Vector((sx * base, sy * base, 0.3))
            b = Vector((sx * top, sy * top, h))
            k.tube(f"Leg{sx}{sy}", [a, b], 0.17, "RedMetal", parent=root, smooth_path=False)
            legs[(sx, sy)] = (a, b)

    def lerp(a, b, t):
        return a + (b - a) * t

    sections = (0.0, 0.34, 0.66, 1.0)
    faces = [((-1, -1), (1, -1)), ((1, -1), (1, 1)), ((1, 1), (-1, 1)), ((-1, 1), (-1, -1))]
    for fi, (p, q) in enumerate(faces):
        la, lb = legs[p], legs[q]
        for si in range(3):
            t0, t1 = sections[si], sections[si + 1]
            a0, a1 = lerp(*la, t0), lerp(*la, t1)
            b0, b1 = lerp(*lb, t0), lerp(*lb, t1)
            k.tube(f"BraceA{fi}{si}", [a0, b1], 0.06, "White", parent=root, smooth_path=False)
            k.tube(f"BraceB{fi}{si}", [b0, a1], 0.06, "White", parent=root, smooth_path=False)
            k.tube(f"Ring{fi}{si}", [a1, b1], 0.08, "White", parent=root, smooth_path=False)
    for x in (-0.35, 0.35):
        k.tube(f"LadderRail{x}", [(x, 2.6, 0.3), (x, 1.38, h)], 0.045, "MetalDark", parent=root, smooth_path=False)
    for r in range(17):
        t = (r + 0.5) / 17
        k.tube(f"Rung{r}", [(-0.35, 2.6 - 1.22 * t, 0.3 + (h - 0.3) * t), (0.35, 2.6 - 1.22 * t, 0.3 + (h - 0.3) * t)],
               0.03, "MetalDark", parent=root, smooth_path=False)
    # площадка, перила
    k.box("Deck", (3.6, 3.6, 0.25), (0, 0, h + 0.1), "Steel", bevel=0.05, parent=root)
    corners = [(-1.75, -1.75), (1.75, -1.75), (1.75, 1.75), (-1.75, 1.75)]
    for i, (x, y) in enumerate(corners):
        k.tube(f"RailPost{i}", [(x, y, h + 0.2), (x, y, h + 1.1)], 0.045, "Yellow", parent=root, smooth_path=False)
    k.tube("Rail", [(x, y, h + 1.1) for x, y in corners + corners[:1]], 0.05, "Yellow", parent=root, smooth_path=False)
    k.tube("RailMid", [(x, y, h + 0.65) for x, y in corners + corners[:1]], 0.035, "Yellow", parent=root,
           smooth_path=False)
    # кабина оператора с рамами окон
    k.box("Cabin", (2.3, 2.3, 1.7), (0, 0.15, h + 1.1), "White", bevel=0.12, parent=root)
    k.box("CabinWindows", (2.36, 2.0, 0.6), (0, 0.15, h + 1.42), "Glass", bevel=0.04, parent=root)
    for x in (-0.6, 0.0, 0.6):
        k.box(f"Mullion{x}", (0.08, 2.4, 0.6), (x, 0.15, h + 1.42), "White", bevel=0.02, parent=root)
    k.box("CabinRoof", (2.8, 2.8, 0.22), (0, 0.15, h + 2.06), "RedMetal", bevel=0.08, parent=root)
    k.box("CabinDoor", (0.7, 0.08, 1.2), (0.6, 1.33, h + 0.85), "MetalDark", bevel=0.03, parent=root)
    k.cylinder("Mast", 0.08, 1.0, (0, 0.15, h + 2.6), "Chrome", verts=12, bevel=0.0, parent=root)
    # сканер урожая: параболическая тарелка + противовес (центр вращения — мачта)
    radar = k.empty("Radar", (0, 0.15, h + 3.05), root)
    k.lathe("RadarHub", [(0.2, 0), (0.2, 0.2), (0.12, 0.3), (0.0, 0.3)], (0, 0, -0.1), "MetalDark", parent=radar)
    dish_prof = [(0.0, 0.0)] + [(0.75 * i / 8, 0.28 * (i / 8) ** 2) for i in range(1, 9)] + [(0.73, 0.3), (0.0, 0.05)]
    k.lathe("RadarDish", dish_prof, (0.5, 0, 0.25), "White", rot=(0, 70, 0), parent=radar, sharp=60)
    k.tube("RadarFeedArm", [(0.55, 0, 0.27), (0.95, 0, 0.42)], 0.03, "Chrome", parent=radar, smooth_path=False)
    k.lens("RadarFeed", 0.07, (0.95, 0, 0.42), "MetalDark", rot=(0, -110, 0), parent=radar)
    k.box("RadarWeight", (0.4, 0.36, 0.36), (-0.55, 0, 0.12), "MetalDark", bevel=0.09, parent=radar)
    k.tube("RadarArm", [(-0.55, 0, 0.12), (0.45, 0, 0.2)], 0.05, "MetalDark", parent=radar, smooth_path=False)
    k.tag(radar, k.spin(radar, "Z", turns=0.5))
    beacon = k.lathe("Beacon", [(0.16, 0), (0.18, 0.1), (0.17, 0.3), (0.1, 0.42), (0.0, 0.45)], (0, 0.15, h + 3.12),
                     "NeonRed", parent=root)
    k.tag(beacon, "pulse_3")
    k.lathe("BeaconBase", [(0.2, 0), (0.2, 0.08), (0.17, 0.1), (0.0, 0.1)], (0, 0.15, h + 3.05), "MetalDark",
            parent=root)
    # баннер контракта
    k.box("Banner", (3.4, 0.1, 0.95), (0, -2.4, 2.6), "Blue", bevel=0.05, parent=root)
    k.box("BannerStripe", (3.42, 0.11, 0.12), (0, -2.4, 2.2), "Yellow", bevel=0.02, parent=root)
    k.text("BannerText", "АВТО-ПРОДАЖА", 0.42, (0, -2.47, 2.65), "White", extrude=0.03, parent=root, max_width=3.1)
    for x in (-1.5, 1.5):
        k.tube(f"BannerTie{x}", [(x, -2.36, 3.0), (x * 0.95, -2.2, 3.05)], 0.025, "MetalDark", parent=root,
               smooth_path=False)


# ----------------------------------------------------------------------
# Авто-грядка Tier 1 со шнековым сбором (4x6)
# ----------------------------------------------------------------------
def auger_blade(k, name, length, r_in, r_out, pitch, key, parent):
    verts, faces = [], []
    steps = int(length / pitch * 24)
    for s in range(steps + 1):
        t = s / steps
        y = -length / 2 + length * t
        a = t * length / pitch * math.tau
        verts.append((r_in * math.cos(a), y, r_in * math.sin(a)))
        verts.append((r_out * math.cos(a), y, r_out * math.sin(a)))
    for s in range(steps):
        i = s * 2
        faces.append([i, i + 1, i + 3, i + 2])
    obj = k.mesh_from(name, verts, faces, (0, 0, 0), key, parent=parent, smooth=True)
    mod = obj.modifiers.new("Solid", "SOLIDIFY")
    mod.thickness = 0.04
    return obj


def auto_bed_t1(k, root):
    w, d = 4.0, 6.0
    for side in (-1, 1):
        k.box(f"FrameL{side}", (0.2, d, 1.0), (side * (w / 2 - 0.1), 0, 0.5), "Yellow", bevel=0.05, parent=root)
        k.box(f"FrameS{side}", (w - 0.4, 0.2, 1.0), (0, side * (d / 2 - 0.1), 0.5), "Yellow", bevel=0.05, parent=root)
        k.box(f"Stripe{side}", (0.22, d - 0.4, 0.12), (side * (w / 2 - 0.1), 0, 0.82), "Black", bevel=0.02, parent=root)
    # U-образное корыто шнека: внешняя дуга, кромки, внутренняя дуга (профиль в плоскости XZ)
    cz, ro, ri, top = 0.66, 0.38, 0.32, 1.02
    outer = [(ro * math.cos(a), cz + ro * math.sin(a)) for a in [math.pi + math.pi * i / 10 for i in range(11)]]
    inner = [(ri * math.cos(a), cz + ri * math.sin(a)) for a in [math.tau - math.pi * i / 10 for i in range(11)]]
    prof = [(-ro, top)] + outer + [(ro, top), (ri, top)] + inner + [(-ri, top)]
    k.prism("Trough", prof, d - 0.4, (1.38, 0, 0), "Steel", parent=root, bevel=0.0)
    auger = k.empty("Auger", (1.38, 0, 0.66), root)
    k.cylinder("AugerShaft", 0.07, d - 0.5, (0, 0, 0), "Chrome", rot=(90, 0, 0), verts=12, bevel=0.0, parent=auger)
    auger_blade(k, "AugerBlade", d - 0.6, 0.07, 0.27, 0.45, "Orange", auger)
    k.tag(auger, k.spin(auger, "Y", turns=2))
    # мотор-редуктор спереди и бункер сзади
    k.box("Gearbox", (0.66, 0.42, 0.62), (1.38, -2.55, 0.86), "GreenDark", bevel=0.08, parent=root)
    k.motor("Motor", (1.38, -2.55, 1.17), parent=root, key="Green", radius=0.2, height=0.55)
    k.lathe("Coupling", [(0.12, 0), (0.12, 0.14), (0.0, 0.14)], (1.38, -2.34, 0.66), "MetalDark", rot=(-90, 0, 0),
            parent=root)
    k.lathe("HopperNeck", [(0.17, 0.0), (0.17, 0.3), (0.0, 0.3)], (1.38, 2.6, 0.75), "Steel", parent=root)
    k.lathe("Hopper", [(0.18, 0), (0.22, 0.06), (0.5, 0.55), (0.52, 0.62), (0.46, 0.62), (0.18, 0.08), (0.0, 0.08)],
            (1.38, 2.6, 1.0), "Steel", parent=root, sharp=60)
    for p in range(3):
        k.potato(f"HopperPotato{p}", (1.38 + (p - 1) * 0.18, 2.6, 1.55), 0.3, parent=root, seed=90 + p, low=True)
    soil_surface(k, root, 2.4, d - 0.4, 0.85, seed=4)
    bush, tubers = plants_and_tubers(k, root, d - 0.3, 0.92, seed=4, scale=0.85)
    bush.location.x = -0.45
    tubers.location.x = -0.45


# ----------------------------------------------------------------------
# Роторный спринклер (2x2)
# ----------------------------------------------------------------------
def sprinkler(k, root):
    k.lathe("Pad", [(0.85, 0), (0.85, 0.1), (0.75, 0.16), (0.0, 0.16)], (0, 0, 0), "Concrete", parent=root)
    k.cylinder("Pipe", 0.1, 2.0, (0, 0, 1.15), "Copper", verts=16, bevel=0.0, parent=root)
    k.lathe("PipeCollar", [(0.16, 0), (0.16, 0.12), (0.0, 0.12)], (0, 0, 0.16), "Copper", parent=root)
    k.torus("ValveWheel", 0.22, 0.035, (0, -0.25, 0.75), "Red", rot=(90, 0, 0), parent=root)
    for s in range(3):
        k.box(f"ValveSpoke{s}", (0.42, 0.03, 0.03), (0, -0.25, 0.75), "Red", bevel=0.0, rot=(0, s * 60, 0), parent=root)
    k.cylinder("ValveBody", 0.16, 0.3, (0, -0.1, 0.75), "Copper", rot=(90, 0, 0), verts=16, bevel=0.03, parent=root)
    head = k.empty("Head", (0, 0, 2.2), root)
    k.lathe("HeadBody", [(0.12, -0.05), (0.22, 0.0), (0.24, 0.18), (0.16, 0.3), (0.08, 0.36), (0.0, 0.36)], (0, 0, 0),
            "Yellow", parent=head)
    for side in (-1, 1):
        k.tube(f"Arm{side}", [(0, 0, 0.15), (side * 0.55, 0, 0.2), (side * 0.85, 0, 0.3)], 0.05, "Chrome", parent=head)
        k.lathe(f"Nozzle{side}", [(0.07, 0), (0.06, 0.14), (0.035, 0.2), (0.0, 0.2)], (side * 0.85, 0, 0.3), "Black",
                rot=(0, side * 60, 0), parent=head)
        pts = []
        for i in range(9):
            t = i / 8
            pts.append((side * (0.95 + t * 2.2), -t * 0.5 * side, 0.4 + math.sin(t * math.pi * 0.9) * 0.9 - t * 0.6))
        k.tube(f"Jet{side}", pts, 0.04, "Water", parent=head, radii=[1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.42, 0.35, 0.3])
    k.tag(head, k.spin(head, "Z", turns=1))
