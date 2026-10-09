"""Агро-блок, часть 3: гидропоника, аэропоника, теплицы, удобрения, датчики, ионизатор, купол, флаг, маскот.

Точка Roblox (x, y, z) здесь пишется как (x, -z, y).
"""

import math
import random

from mathutils import Vector

from .agro2 import solar_panel


# ----------------------------------------------------------------------
# Гидропоника
# ----------------------------------------------------------------------
def hydro_tray(k, parent, name, w, d, z, rnd, cols=4, rows=5, scale=1.0):
    """Лоток с раствором и рассадой в стаканчиках (верх лотка на высоте z)."""
    g = k.empty(name, (0, 0, z), parent)
    k.box("Tray", (w, d, 0.3), (0, 0, -0.15), "White", bevel=0.06, parent=g)
    k.box("Solution", (w - 0.24, d - 0.24, 0.04), (0, 0, -0.02), "Water", bevel=0.01, parent=g)
    for c in range(cols):
        for r in range(rows):
            x = -w / 2 + w * (c + 0.5) / cols
            y = -d / 2 + d * (r + 0.5) / rows
            k.seedling(f"Seedling{c}{r}", (x + rnd.uniform(-0.05, 0.05), y + rnd.uniform(-0.05, 0.05), 0.0), g, rnd,
                       scale=scale * rnd.uniform(0.85, 1.15))
    return g


def hydro_tray_item(k, root):
    rnd = random.Random(51)
    for x in (-1.6, 1.6):
        for y in (-2.6, 2.6):
            k.box(f"Leg{x}{y}", (0.16, 0.16, 1.35), (x, y, 0.67), "Chrome", bevel=0.03, parent=root)
            k.lathe(f"Foot{x}{y}", [(0.14, 0), (0.14, 0.05), (0.0, 0.05)], (x, y, 0), "Rubber", parent=root)
    for y in (-2.6, 2.6):
        k.box(f"Brace{y}", (3.2, 0.08, 0.08), (0, y, 0.45), "Chrome", bevel=0.02, parent=root)
    hydro_tray(k, root, "TrayTop", 3.6, 5.6, 1.65, rnd)
    k.tube("Drain", [(1.75, -2.75, 1.4), (1.85, -2.95, 0.9), (1.85, -3.2, 0.15)], 0.07, "White", parent=root)
    k.lathe("Reservoir", [(0.0, 0.0), (0.4, 0.0), (0.42, 0.5), (0.36, 0.56), (0.0, 0.56)], (1.5, -3.35, 0), "BlueDark",
            parent=root)


def hydro_rack(k, root, tiers):
    rnd = random.Random(52 + tiers)
    h = tiers * 2 + 1.05
    for x in (-2.2, 2.2):
        for y in (-2.7, 2.7):
            k.box(f"Post{x}{y}", (0.2, 0.2, h), (x, y, h / 2), "Chrome", bevel=0.04, parent=root)
            k.lathe(f"Foot{x}{y}", [(0.16, 0), (0.16, 0.05), (0.0, 0.05)], (x, y, 0), "Rubber", parent=root)
    for t in range(1, tiers + 1):
        z = t * 2 - 0.9
        hydro_tray(k, root, f"Tier{t}", 4.2, 5.6, z + 0.15, rnd, cols=4, rows=5, scale=0.9)
        k.box(f"LampHousing{t}", (3.8, 5.0, 0.12), (0, 0, z + 1.82), "MetalDark", bevel=0.04, parent=root)
        for s in range(4):
            k.box(f"Grow{t}{s}", (3.4, 0.3, 0.05), (0, -1.8 + s * 1.2, z + 1.74), "NeonPurple", bevel=0.01,
                  parent=root)
        for x in (-2.2, 2.2):
            k.box(f"Shelf{t}{x}", (0.12, 5.6, 0.12), (x, 0, z - 0.05), "Chrome", bevel=0.03, parent=root)
    k.tube("Riser", [(2.35, 2.85, 0.2), (2.35, 2.85, h - 0.6)], 0.06, "White", parent=root, smooth_path=False)
    k.box("Pump", (0.6, 0.5, 0.5), (1.6, 3.15, 0.25), "BlueDark", bevel=0.08, parent=root)


def hydro_rack2(k, root):
    hydro_rack(k, root, 2)


def hydro_rack3(k, root):
    hydro_rack(k, root, 3)


def hydro_tower(k, root):
    rnd = random.Random(55)
    k.lathe("Basin", [(0.0, 0.0), (1.7, 0.0), (1.8, 0.1), (1.82, 1.1), (1.7, 1.2), (1.6, 1.2), (1.6, 1.0),
                      (0.0, 1.0)], (0, 0, 0), "Blue", segments=40, parent=root)
    k.lathe("BasinWater", [(1.6, 0), (1.6, 0.02), (0.0, 0.02)], (0, 0, 1.02), "Water", segments=40, parent=root)
    tower = k.empty("Tower", (0, 0, 1.0), root)
    k.lathe("Column", [(0.75, 0.0), (0.72, 4.0), (0.66, 8.2), (0.5, 8.45), (0.0, 8.5)], (0, 0, 0), "White",
            segments=32, parent=tower)
    for i in range(16):
        a = math.radians(i * 67)
        z = 0.9 + i * 0.47
        pos = Vector((math.cos(a) * 0.72, math.sin(a) * 0.72, z))
        pocket = k.empty(f"Pocket{i}", tuple(pos), tower, rot=(0, 55, math.degrees(a)))
        k.lathe("Cup", [(0.0, -0.1), (0.2, -0.1), (0.24, 0.12), (0.2, 0.14), (0.0, 0.1)], (0, 0, 0), "White",
                segments=14, parent=pocket)
        k.seedling("Plant", (0, 0, 0.1), pocket, rnd, scale=1.4, leaves=6, cup="White")
    k.tag(tower, k.spin(tower, "Z", turns=0.067))
    k.lathe("TopLight", [(0.0, 0.0), (0.3, 0.02), (0.36, 0.2), (0.25, 0.42), (0.0, 0.5)], (0, 0, 9.5), "NeonCyan",
            parent=root)


# ----------------------------------------------------------------------
# Аэропонная капсула (5x6)
# ----------------------------------------------------------------------
def aeroponic(k, root):
    rnd = random.Random(56)
    k.box("Base", (4.4, 4.4, 0.4), (0, 0, 0.2), "MetalDark", bevel=0.08, parent=root)
    pod = [(0.0, 0.4), (1.6, 0.4), (1.9, 0.6), (2.05, 1.2), (2.05, 2.6), (1.85, 3.6), (1.4, 4.2), (0.7, 4.55),
           (0.0, 4.65)]
    k.lathe("Pod", pod, (0, 0, 0), "White", segments=40, parent=root, sharp=70)

    def pod_r(z):
        for (r0, z0), (r1, z1) in zip(pod, pod[1:]):
            if z0 <= z <= z1:
                return r0 + (r1 - r0) * (z - z0) / max(z1 - z0, 1e-6)
        return 0.0

    zw0, zw1 = 1.6, 3.4
    k.shell("Window", 1.0, zw0, zw1, 205, 335, (0, 0, 0), "Glass", parent=root, thickness=0.03, rows=6, cols=12,
            profile=lambda t: pod_r(zw0 + (zw1 - zw0) * t) + 0.02)
    k.shell("WindowFrame", 1.0, zw0 - 0.08, zw0, 200, 340, (0, 0, 0), "MetalDark", parent=root, thickness=0.05,
            rows=1, cols=12, profile=lambda t: pod_r(zw0) + 0.02)
    k.shell("WindowFrameTop", 1.0, zw1, zw1 + 0.08, 200, 340, (0, 0, 0), "MetalDark", parent=root, thickness=0.05,
            rows=1, cols=12, profile=lambda t: pod_r(zw1) + 0.02)
    k.lathe("Ring", [(2.06, 1.15), (2.1, 1.18), (2.1, 1.32), (2.06, 1.35)], (0, 0, 0), "NeonCyan", segments=40,
            parent=root)
    k.lathe("Vent", [(0.45, 0), (0.45, 0.12), (0.3, 0.2), (0.0, 0.2)], (0, 0, 4.55), "MetalDark", parent=root)
    # растения на полке внутри, видны в окно
    k.lathe("Shelf", [(1.5, 0), (1.5, 0.08), (0.0, 0.08)], (0, 0, 1.75), "Chrome", parent=root)
    for i in range(7):
        a = math.radians(210 + i * 20)
        k.seedling(f"Plant{i}", (math.cos(a) * 1.15, math.sin(a) * 1.15, 1.85), root, rnd, scale=1.5, leaves=6)
    k.box("Panel", (0.6, 0.12, 0.8), (1.25, -1.65, 1.0), "MetalDark", bevel=0.05, rot=(0, 0, 35), parent=root)
    led = k.lens("PanelLed", 0.05, (1.32, -1.75, 1.2), "NeonGreen", rot=(90, 0, 35), parent=root)
    k.tag(led, "pulse_2")


# ----------------------------------------------------------------------
# Теплицы
# ----------------------------------------------------------------------
def greenhouse_small(k, root):
    rnd = random.Random(57)
    w, d, h = 5.0, 6.0, 2.6
    k.box("Base", (w + 0.2, d + 0.2, 0.3), (0, 0, 0.15), "Concrete", bevel=0.05, parent=root)
    # каркас: стойки, обвязка, стропила (конёк вдоль Y, скаты к ±X)
    ridge = h + w / 2 * math.tan(math.radians(28))
    for x in (-w / 2, w / 2):
        for y in (-d / 2, -d / 6, d / 6, d / 2):
            k.box(f"Stud{x}{y}", (0.14, 0.14, h), (x, y, 0.3 + h / 2), "WoodDark", bevel=0.03, parent=root)
        k.box(f"Plate{x}", (0.16, d + 0.16, 0.14), (x, 0, 0.3 + h), "WoodDark", bevel=0.03, parent=root)
        k.box(f"Sill{x}", (0.16, d + 0.16, 0.14), (x, 0, 0.37), "WoodDark", bevel=0.03, parent=root)
    for y in (-d / 2, d / 2):
        for x in (-w / 6, w / 6):
            k.box(f"EndStud{x}{y}", (0.12, 0.12, h), (x, y, 0.3 + h / 2), "WoodDark", bevel=0.03, parent=root)
    slope = math.degrees(math.atan2(ridge - h, w / 2))
    run = math.hypot(w / 2, ridge - h)
    for y in (-d / 2, -d / 6, d / 6, d / 2):
        for side in (-1, 1):
            k.box(f"Rafter{y}{side}", (run + 0.1, 0.12, 0.12), (side * w / 4, y, 0.3 + (h + ridge) / 2), "WoodDark",
                  bevel=0.03, rot=(0, side * slope, 0), parent=root)
    k.box("Ridge", (0.16, d + 0.3, 0.16), (0, 0, 0.3 + ridge), "WoodDark", bevel=0.04, parent=root)
    # стёкла
    for x in (-w / 2, w / 2):
        k.box(f"GlassSide{x}", (0.04, d - 0.1, h - 0.2), (x, 0, 0.3 + h / 2 + 0.03), "Glass", bevel=0.0, parent=root)
    for side in (-1, 1):
        k.box(f"GlassRoof{side}", (run - 0.05, d - 0.05, 0.04), (side * w / 4, 0, 0.3 + (h + ridge) / 2 + 0.06),
              "Glass", bevel=0.0, rot=(0, side * slope, 0), parent=root)
    for y in (-d / 2, d / 2):
        gable = [(-w / 2, h), (w / 2, h), (0, ridge)]
        k.prism(f"GlassGable{y}", [(x, z + 0.3) for x, z in gable], 0.04, (0, y, 0), "Glass", parent=root, bevel=0.0)
        k.box(f"GlassEnd{y}", (w - 0.1, 0.04, h - 0.2), (0, y, 0.3 + h / 2 + 0.03), "Glass", bevel=0.0, parent=root)
    # дверь спереди (-Y)
    k.box("DoorFrame", (1.3, 0.16, 2.2), (0, -d / 2 - 0.04, 1.4), "WoodDark", bevel=0.03, parent=root)
    k.box("DoorGlass", (1.0, 0.06, 1.9), (0, -d / 2 - 0.08, 1.4), "Glass", bevel=0.0, parent=root)
    k.lens("DoorKnob", 0.05, (0.42, -d / 2 - 0.14, 1.35), "Gold", rot=(90, 0, 0), parent=root)
    # грядка с рассадой внутри
    k.box("Bed", (w - 1.0, d - 1.2, 0.55), (0, 0.1, 0.55), "WoodLight", bevel=0.05, parent=root)
    k.box("BedSoil", (w - 1.2, d - 1.4, 0.05), (0, 0.1, 0.84), "Soil", bevel=0.01, parent=root)
    for c in range(4):
        for r in range(5):
            k.seedling(f"Seedling{c}{r}", (-1.5 + c * 1.0, -1.8 + 0.1 + r * 0.95, 0.86), root, rnd, scale=1.3,
                       leaves=6, cup="SoilDark")


def greenhouse_pro(k, root):
    rnd = random.Random(58)
    length, radius = 14.0, 3.0
    k.box("Base", (length, 6.0, 0.3), (0, 0, 0.15), "Concrete", bevel=0.06, parent=root)
    # поликарбонатный тоннель: полуцилиндр вдоль X
    k.shell("Tunnel", radius, -length / 2 + 0.2, length / 2 - 0.2, 0, 180, (0, 0, 0.3), "Glass", parent=root,
            thickness=0.04, rows=1, cols=24, rot=(0, 90, 0))
    for i in range(6):
        x = -6.5 + i * 2.6
        k.shell(f"Arch{i}", radius + 0.04, x - 0.08, x + 0.08, 0, 180, (0, 0, 0.3), "Chrome", parent=root,
                thickness=0.08, rows=1, cols=24, rot=(0, 90, 0))
    # торцы с дверями
    for side in (-1, 1):
        x = side * (length / 2 - 0.2)
        verts = [(0, 0, 0)] + [(0, radius * math.cos(math.pi * i / 16), radius * math.sin(math.pi * i / 16))
                               for i in range(17)]
        faces = [[0, i + 1, i + 2] for i in range(16)]
        end = k.mesh_from(f"EndWall{side}", verts, faces, (x, 0, 0.3), "Glass", parent=root, smooth=False)
        mod = end.modifiers.new("Solid", "SOLIDIFY")
        mod.thickness = 0.05
        k.box(f"Door{side}", (0.1, 1.4, 2.2), (x + side * 0.02, 0, 1.4), "White", bevel=0.04, parent=root)
        k.box(f"DoorWindow{side}", (0.12, 1.0, 1.0), (x + side * 0.03, 0, 1.9), "Glass", bevel=0.02, parent=root)
    # грядки и растения
    for y in (-1.2, 1.2):
        k.box(f"Bed{y}", (12.6, 1.6, 0.5), (0, y, 0.55), "WoodLight", bevel=0.05, parent=root)
        k.box(f"BedSoil{y}", (12.4, 1.4, 0.05), (0, y, 0.8), "Soil", bevel=0.01, parent=root)
        for i in range(12):
            k.seedling(f"Plant{y}{i}", (-5.8 + i * 1.05, y + rnd.uniform(-0.25, 0.25), 0.82), root, rnd, scale=1.8,
                       leaves=6, cup="SoilDark")
    k.box("Path", (12.8, 0.7, 0.04), (0, 0, 0.32), "StoneLight", bevel=0.01, parent=root)
    for x in (-4.5, 0.0, 4.5):
        lamp = k.lathe(f"Lamp{x}", [(0.0, 0.0), (0.18, 0.0), (0.22, -0.08), (0.0, -0.1)], (x, 0, 3.2), "NeonWhite",
                       parent=root)
        k.tube(f"LampWire{x}", [(x, 0, 3.2), (x, 0, 3.3)], 0.02, "Black", parent=root, smooth_path=False)
        del lamp


# ----------------------------------------------------------------------
# Удобрения, биогумус, туман, датчик, ионизатор, силовой купол
# ----------------------------------------------------------------------
def fertilizer(k, root):
    k.box("Base", (2.6, 2.6, 0.25), (0, 0, 0.12), "MetalDark", bevel=0.05, parent=root)
    k.lathe("Tank", [(0.0, 0.0), (0.82, 0.0), (0.9, 0.08), (0.92, 1.9), (0.8, 2.12), (0.0, 2.15)], (-0.3, 0.2, 0.25),
            "White", segments=36, parent=root)
    k.lathe("Lid", [(0.4, 0), (0.4, 0.14), (0.34, 0.18), (0.0, 0.18)], (-0.3, 0.2, 2.38), "Blue", parent=root)
    k.lathe("Level", [(0.07, 0), (0.07, 1.5), (0.0, 1.5)], (-0.3 + 0.55, 0.2 - 0.72, 0.4), "Glass", segments=10,
            parent=root)
    k.lathe("LevelFluid", [(0.05, 0), (0.05, 0.9), (0.0, 0.9)], (-0.3 + 0.55, 0.2 - 0.72, 0.42), "Green",
            segments=10, parent=root)
    k.box("Doser", (0.9, 0.7, 0.9), (0.8, -0.7, 0.7), "Blue", bevel=0.1, parent=root)
    k.box("DoserScreen", (0.5, 0.04, 0.28), (0.8, -1.07, 0.85), "Black", bevel=0.02, parent=root)
    led = k.lens("DoserLed", 0.05, (0.62, -1.08, 0.6), "NeonGreen", rot=(90, 0, 0), parent=root)
    k.tag(led, "pulse_4")
    k.tube("Hose", [(0.8, -1.0, 0.5), (0.85, -1.3, 0.3), (0.9, -1.6, 0.15)], 0.07, "Black", parent=root)
    k.tube("FeedPipe", [(0.6, 0.2, 0.5), (0.4, -0.4, 0.5)], 0.06, "White", parent=root)


def biohumus_tank(k, root):
    tank = [(0.0, 0.0), (1.2, 0.0), (1.3, 0.1), (1.3, 2.9), (1.36, 2.95), (1.36, 3.05), (1.2, 3.05), (1.2, 2.85),
            (0.0, 2.85)]
    k.lathe("Tank", tank, (0, 0, 0), "WoodDark", segments=40, parent=root, sharp=60)
    for z in (0.6, 1.4, 2.2):
        k.lathe(f"Hoop{z}", [(1.305, 0), (1.34, 0.03), (1.34, 0.12), (1.305, 0.15)], (0, 0, z), "MetalDark",
                segments=40, parent=root)
    k.blob("Humus", (2.3, 2.3, 0.5), (0, 0, 2.86), "SoilDark", parent=root, jitter=0.15, seed=7, squash_bottom=0.0)
    for i in range(3):
        a = i * 2.1
        k.tube(f"Worm{i}", [(math.cos(a) * 0.5, math.sin(a) * 0.5, 2.9), (math.cos(a) * 0.55, math.sin(a) * 0.55, 3.08),
                            (math.cos(a + 0.3) * 0.62, math.sin(a + 0.3) * 0.62, 3.1)], 0.04, "Skin", parent=root,
               radii=[1.0, 1.0, 0.7])
    # лестница сбоку (+X)
    for y in (-0.25, 0.25):
        k.tube(f"LadderRail{y}", [(1.42, y, 0.0), (1.42, y, 3.2), (1.25, y, 3.35)], 0.04, "Chrome", parent=root,
               smooth_path=False)
    for i in range(6):
        k.tube(f"Rung{i}", [(1.42, -0.25, 0.4 + i * 0.5), (1.42, 0.25, 0.4 + i * 0.5)], 0.03, "Chrome", parent=root,
               smooth_path=False)
    k.lathe("Tap", [(0.08, 0), (0.08, 0.2), (0.0, 0.2)], (0, -1.3, 0.3), "Copper", rot=(90, 0, 0), parent=root)


def fogger(k, root):
    k.box("Body", (1.4, 1.4, 1.0), (0, 0, 0.5), "White", bevel=0.2, segments=3, parent=root)
    k.box("Tank", (1.0, 0.06, 0.5), (0, -0.7, 0.45), "Glass", bevel=0.04, parent=root)
    k.box("TankWater", (0.9, 0.04, 0.3), (0, -0.69, 0.36), "Water", bevel=0.02, parent=root)
    k.lathe("Nozzle", [(0.32, 0), (0.32, 0.08), (0.18, 0.4), (0.22, 0.48), (0.16, 0.5), (0.0, 0.5)], (0, 0, 1.0),
            "Chrome", parent=root)
    strip = k.box("Strip", (0.5, 0.04, 0.08), (0, -0.71, 0.82), "NeonCyan", bevel=0.01, parent=root)
    k.tag(strip, "pulse_1")
    # сам туман в игре — частицы процедурной модели над соплом


def soil_sensor(k, root):
    k.blob("Mound", (1.0, 1.0, 0.3), (0, 0, 0), "Soil", parent=root, jitter=0.12, seed=5, squash_bottom=0.0)
    k.lathe("Stake", [(0.06, 0.0), (0.06, 1.35), (0.0, 1.35)], (0, 0, 0), "Chrome", segments=12, parent=root)
    k.box("Display", (0.9, 0.28, 0.7), (0, 0, 1.6), "White", bevel=0.1, parent=root)
    k.box("Screen", (0.68, 0.04, 0.42), (0, -0.15, 1.62), "NeonGreen", bevel=0.02, parent=root)
    k.text("Reading", "pH 6.5", 0.2, (0, -0.17, 1.62), "Black", extrude=0.01, parent=root, max_width=0.6, logo=True)
    solar_panel(k, "Solar", 0.8, 0.5, (0, 0.05, 2.02), -20, root)
    for x in (-0.12, 0.12):
        k.lathe(f"Prong{x}", [(0.025, 0.0), (0.025, -0.4), (0.0, -0.45)], (x, 0, 0.1), "Chrome", segments=8,
                parent=root)


def ionizer(k, root):
    k.lathe("Base", [(1.2, 0), (1.2, 0.15), (1.0, 0.3), (0.4, 0.42), (0.0, 0.42)], (0, 0, 0), "MetalDark",
            segments=36, parent=root)
    k.lathe("Column", [(0.28, 0), (0.24, 3.0), (0.32, 3.15), (0.32, 3.25), (0.0, 3.25)], (0, 0, 0.4), "Copper",
            segments=20, parent=root)
    for i in range(10):
        k.torus(f"Coil{i}", 0.3, 0.035, (0, 0, 0.8 + i * 0.12), "Copper", parent=root, seg=24, ring=8)
    rings = k.empty("Rings", (0, 0, 2.0), root)
    for i, z in enumerate((-0.9, -0.2, 0.5)):
        k.torus(f"Ring{i}", 0.8 - i * 0.1, 0.05, (0, 0, z), "NeonCyan", parent=rings, seg=40, ring=8)
    k.tag(rings, k.spin(rings, "Z", turns=0.25))
    orb = k.lathe("Orb", [(0.0, -0.4), (0.25, -0.33), (0.38, -0.15), (0.4, 0.0), (0.38, 0.15), (0.25, 0.33),
                          (0.0, 0.4)], (0, 0, 4.1), "NeonCyan", segments=24, parent=root)
    k.tag(orb, "pulse_2")
    for i in range(3):
        a = i / 3 * math.tau
        k.tube(f"Claw{i}", [(math.cos(a) * 0.22, math.sin(a) * 0.22, 3.6), (math.cos(a) * 0.45, math.sin(a) * 0.45, 3.9),
                            (math.cos(a) * 0.3, math.sin(a) * 0.3, 4.3)], 0.04, "Copper", parent=root)


def force_dome(k, root):
    k.lathe("Base", [(1.3, 0), (1.3, 0.2), (1.1, 0.35), (0.5, 0.5), (0.0, 0.5)], (0, 0, 0), "MetalDark", segments=36,
            parent=root)
    k.lathe("Column", [(0.42, 0), (0.36, 2.6), (0.5, 2.9), (0.6, 3.1), (0.0, 3.1)], (0, 0, 0.45), "Black",
            segments=24, parent=root)
    for i in range(4):
        a = i / 4 * math.tau
        k.tube(f"Fin{i}", [(math.cos(a) * 0.4, math.sin(a) * 0.4, 0.5), (math.cos(a) * 0.75, math.sin(a) * 0.75, 1.2),
                           (math.cos(a) * 0.4, math.sin(a) * 0.4, 2.2)], 0.06, "MetalDark", parent=root)
        k.tube(f"Prong{i}", [(math.cos(a) * 0.5, math.sin(a) * 0.5, 3.45), (math.cos(a) * 0.9, math.sin(a) * 0.9, 4.1),
                             (math.cos(a) * 0.55, math.sin(a) * 0.55, 4.9)], 0.05, "Chrome", parent=root)
    orb = k.lathe("Orb", [(0.0, -0.65), (0.4, -0.52), (0.62, -0.22), (0.65, 0.0), (0.62, 0.22), (0.4, 0.52),
                          (0.0, 0.65)], (0, 0, 4.2), "NeonCyan", segments=28, parent=root)
    k.tag(orb, "pulse_1.5")


# ----------------------------------------------------------------------
# Флагшток и маскот
# ----------------------------------------------------------------------
def flagpole(k, root):
    k.lathe("Base", [(0.7, 0), (0.7, 0.3), (0.5, 0.42), (0.18, 0.45), (0.0, 0.45)], (0, 0, 0), "Concrete",
            segments=32, parent=root)
    k.lathe("Pole", [(0.13, 0), (0.1, 6.0), (0.08, 11.7), (0.0, 11.7)], (0, 0, 0.4), "Chrome", segments=16,
            parent=root)
    k.lathe("Finial", [(0.0, 0.0), (0.16, 0.05), (0.2, 0.2), (0.16, 0.36), (0.0, 0.42)], (0, 0, 12.05), "Gold",
            segments=20, parent=root)
    flag = k.empty("Flag", (0, 0, 11.0), root)
    verts, faces = [], []
    nu, nv = 14, 6
    for i in range(nu + 1):
        u = i / nu
        for j in range(nv + 1):
            v = j / nv
            y = 0.12 + u * 2.8
            x = 0.16 * math.sin(u * 5.5) * u
            verts.append((x, y, -0.9 + v * 1.8 - u * 0.12))
    for i in range(nu):
        for j in range(nv):
            a = i * (nv + 1) + j
            faces.append([a, a + nv + 1, a + nv + 2, a + 1])
    cloth = k.mesh_from("Cloth", verts, faces, (0, 0, 0), "Yellow", parent=flag, smooth=True)
    mod = cloth.modifiers.new("Solid", "SOLIDIFY")
    mod.thickness = 0.04
    mod.offset = 0
    for side in (-1, 1):
        rot = (90, 0, 90) if side > 0 else (90, 0, -90)
        k.text(f"Text{side}", "POTATO INC", 0.32, (side * 0.06 + 0.16 * math.sin(2.75) * 0.5, 1.9, -0.45), "Red",
               rot=rot, extrude=0.015, parent=flag, max_width=2.2, logo=True)
        k.potato(f"Emblem{side}", (side * 0.07 + 0.16 * math.sin(2.2) * 0.4, 1.5, 0.25), 0.6, parent=flag,
                 key="WoodDark", seed=12, rot=(0, 90, 0))
    for z in (-0.85, 0.85):
        k.lathe(f"Clip{z}", [(0.13, 0), (0.13, 0.08), (0.0, 0.08)], (0, 0, z - 0.04), "MetalDark", parent=flag)
    k.tag(flag, k.swing(flag, "Z", degrees=12, cycles=1))


def mascot(k, root):
    plush = k.empty("Plush", (0, 0, 0), root)
    k.blob("BodyBlob", (2.1, 1.9, 3.2), (0, 0, 1.75), "Potato", parent=plush, jitter=0.05, seed=4, segments=10,
           rings=8)
    for i, (x, z, r) in enumerate(((-0.6, 2.5, 0.07), (0.55, 1.4, 0.06), (0.3, 2.9, 0.05), (-0.35, 1.1, 0.06))):
        k.lens(f"Eye{i}Spot", r, (x, -0.88 + abs(x) * 0.25, z), "PotatoDark", rot=(90, 0, 0), parent=plush,
               height=0.2)
    for x in (-0.38, 0.38):
        k.lens(f"Eye{x}", 0.24, (x, -0.9, 2.45), "White", rot=(90, 0, 0), parent=plush, height=0.45)
        k.lens(f"Pupil{x}", 0.12, (x * 1.05, -1.0, 2.43), "Black", rot=(90, 0, 0), parent=plush, height=0.5)
        k.lens(f"Shine{x}", 0.04, (x * 1.05 - 0.05, -1.06, 2.5), "White", rot=(90, 0, 0), parent=plush)
        k.lens(f"Cheek{x}", 0.13, (x * 1.6, -0.85, 2.05), "FabricRed", rot=(90, 0, x * 40), parent=plush, height=0.2)
    k.tube("Smile", [(-0.32, -0.95, 2.05), (0.0, -1.02, 1.88), (0.32, -0.95, 2.05)], 0.045, "Red", parent=plush)
    # кепка
    k.lathe("Cap", [(0.0, 0.0), (0.82, 0.0), (0.82, 0.08), (0.74, 0.32), (0.5, 0.52), (0.0, 0.58)], (0, 0.05, 3.15),
            "FabricRed", segments=32, parent=plush, rot=(-8, 0, 0))
    k.lathe("CapButton", [(0.09, 0), (0.09, 0.05), (0.0, 0.08)], (0, 0.01, 3.73), "FabricWhite", parent=plush)
    k.box("Visor", (1.15, 0.8, 0.07), (0, -0.85, 3.2), "FabricRed", bevel=0.03, rot=(-12, 0, 0), parent=plush)
    k.text("CapLogo", "P", 0.3, (0, -0.72, 3.38), "FabricWhite", rot=(78, 0, 0), extrude=0.02, parent=plush, logo=True)
    # ручки и ножки
    for side in (-1, 1):
        k.tube(f"Arm{side}", [(side * 0.95, -0.1, 2.0), (side * 1.35, -0.25, 1.6), (side * 1.45, -0.4, 1.25)], 0.12,
               "Potato", parent=plush, radii=[1.0, 0.9, 0.85])
        k.blob(f"Hand{side}", (0.36, 0.32, 0.32), (side * 1.45, -0.42, 1.18), "FabricWhite", parent=plush, jitter=0.0,
               seed=1)
        k.blob(f"Shoe{side}", (0.6, 0.85, 0.36), (side * 0.45, -0.25, 0.18), "Red", parent=plush, jitter=0.03, seed=2,
               squash_bottom=0.16)
    k.tag(plush, k.bob(plush, amplitude=0.25, cycles=1))
