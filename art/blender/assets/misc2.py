"""Центральная площадь и мир: статуя основателя, зал славы, ворота Rebirth, пьедестал золотого клубня,
капсула криосна, уличный фонарь, контейнер переработки, скамейка, робот-помощник, ель.

Точка Roblox (x, y, z) здесь пишется как (x, -z, y).
"""

import math
import random

from mathutils import Vector


def fluted_column(k, name, radius, height, loc, key, parent, flutes=12):
    """Колонна с каннелюрами: тело вращения с волнистым сечением."""
    obj = k.lathe(name, [(radius * 1.15, 0), (radius * 1.15, 0.25), (radius, 0.35), (radius, height - 0.35),
                         (radius * 1.15, height - 0.25), (radius * 1.15, height), (0.0, height)], loc, key,
                  segments=flutes * 4, parent=parent, sharp=60)
    for v in obj.data.vertices:
        r = math.hypot(v.co.x, v.co.y)
        if 0.3 < v.co.z < height - 0.3 and r > 1e-4:
            a = math.atan2(v.co.y, v.co.x)
            f = 1 - 0.06 * max(0.0, math.cos(a * flutes))
            v.co.x *= f
            v.co.y *= f
    return obj


# ----------------------------------------------------------------------
# Статуя основателя: мраморный картофельный магнат с лопатой и золотым клубнем
# ----------------------------------------------------------------------
def founder_statue(k, root):
    k.lathe("Plinth", [(4.5, 0), (4.5, 0.9), (4.3, 1.2), (0.0, 1.2)], (0, 0, 0), "StoneLight", segments=64,
            parent=root)
    k.lathe("Pedestal", [(3.25, 0), (3.25, 1.4), (3.0, 1.6), (0.0, 1.6)], (0, 0, 1.2), "Marble", segments=64,
            parent=root)
    s = k.empty("Founder", (0, 0, 2.8), root)
    k.blob("Body", (3.2, 2.8, 5.0), (0, 0, 2.6), "Marble", parent=s, jitter=0.04, seed=5, segments=10, rings=8)
    for x in (-0.6, 0.6):
        k.lens(f"Eye{x}", 0.3, (x, -1.36, 3.6), "Marble", rot=(90, 0, 0), parent=s, height=0.4)
        k.blob(f"Leg{x}", (0.9, 1.1, 1.0), (x * 1.1, -0.2, 0.35), "Marble", parent=s, jitter=0.05, seed=2)
    k.tube("Moustache", [(-0.7, -1.4, 3.0), (-0.3, -1.5, 3.15), (0.0, -1.48, 3.05), (0.3, -1.5, 3.15),
                         (0.7, -1.4, 3.0)], 0.12, "Marble", parent=s, radii=[0.5, 1.0, 0.8, 1.0, 0.5])
    k.lathe("TopHat", [(0.0, 0.0), (1.4, 0.0), (1.4, 0.12), (0.9, 0.16), (0.85, 1.4), (0.95, 1.5), (0.0, 1.5)],
            (0, 0.1, 4.9), "Marble", segments=32, parent=s)
    # рука с поднятым золотым клубнем и рука на лопате
    k.tube("ArmUp", [(1.4, -0.2, 3.0), (2.4, -0.4, 4.0), (2.9, -0.6, 5.2)], 0.3, "Marble", parent=s,
           radii=[1.0, 0.9, 0.8])
    k.potato("GoldenTuber", (3.0, -0.65, 5.9), 1.9, parent=s, key="Gold", seed=8, rot=(10, 70, 20))
    k.tube("ArmDown", [(-1.4, -0.2, 2.8), (-2.0, -0.5, 2.2), (-2.2, -0.6, 1.6)], 0.3, "Marble", parent=s,
           radii=[1.0, 0.9, 0.8])
    k.lathe("ShovelShaft", [(0.12, 0), (0.12, 3.2), (0.0, 3.2)], (-2.25, -0.6, 0.0), "Marble", segments=12,
            parent=s)
    k.box("ShovelHandle", (0.8, 0.22, 0.22), (-2.25, -0.6, 3.3), "Marble", bevel=0.08, parent=s)
    k.box("ShovelBlade", (1.0, 0.15, 1.1), (-2.25, -0.6, -0.2), "Marble", bevel=0.08, parent=s)
    plaque = k.empty("Plaque", (0, -3.26, 2.0), root, rot=(0, 0, 0))
    k.box("PlaquePlate", (4.4, 0.08, 0.9), (0, 0, 0), "Gold", bevel=0.03, parent=plaque)
    k.text("PlaqueText", "FOUNDER OF THE POTATO EMPIRE", 0.24, (0, -0.06, 0), "Black", extrude=0.01,
           parent=plaque, max_width=4.1)


def hall_of_fame(k, root):
    """Рама вокруг табло (само табло с живым списком — процедурная деталь 8.6 x 6.4 на высоте 4.4)."""
    k.box("Base", (10.0, 2.0, 0.6), (0, 0, 0.3), "Marble", bevel=0.08, parent=root)
    k.box("Step", (10.6, 2.6, 0.2), (0, 0, 0.1), "StoneLight", bevel=0.05, parent=root)
    for x in (-4.6, 4.6):
        fluted_column(k, f"Column{x}", 0.32, 7.6, (x, 0, 0.6), "Gold", root, flutes=10)
        k.lathe(f"Finial{x}", [(0.0, 0.0), (0.35, 0.05), (0.42, 0.3), (0.3, 0.6), (0.0, 0.75)], (x, 0, 8.2), "Gold",
                parent=root)
    t = 0.2
    cz, bw, bh = 4.4, 8.6, 6.4
    k.box("FrameTop", (bw + 2 * t, 0.6, t), (0, 0, cz + bh / 2 + t / 2), "Gold", bevel=0.06, parent=root)
    k.box("FrameBottom", (bw + 2 * t, 0.6, t), (0, 0, cz - bh / 2 - t / 2), "Gold", bevel=0.06, parent=root)
    for x in (-1, 1):
        k.box(f"FrameSide{x}", (t, 0.6, bh), (x * (bw / 2 + t / 2), 0, cz), "Gold", bevel=0.06, parent=root)
    # кубок наверху
    cup = [(0.0, 0.0), (0.5, 0.0), (0.5, 0.1), (0.15, 0.2), (0.12, 0.6), (0.3, 0.75), (0.6, 1.1), (0.65, 1.5),
           (0.58, 1.5), (0.0, 1.05)]
    k.lathe("Trophy", cup, (0, 0, cz + bh / 2 + t), "Gold", segments=32, parent=root, sharp=60)
    for x in (-1, 1):
        k.torus(f"TrophyHandle{x}", 0.25, 0.05, (x * 0.68, 0, cz + bh / 2 + t + 1.15), "Gold", rot=(90, 0, 0),
                parent=root)
    star = k.lathe("TrophyStar", [(0.0, -0.18), (0.14, -0.12), (0.18, 0.0), (0.14, 0.12), (0.0, 0.18)],
                   (0, 0, cz + bh / 2 + t + 1.75), "NeonYellow", segments=12, parent=root)
    k.tag(star, "pulse_1.5")


def rebirth_gate(k, root):
    k.box("Base", (9.0, 3.0, 0.5), (0, 0, 0.25), "NeonPurple", bevel=0.1, parent=root)
    k.box("BaseTop", (8.8, 2.8, 0.1), (0, 0, 0.52), "Black", bevel=0.03, parent=root)
    for x in (-3.8, 3.8):
        k.box(f"Pillar{x}", (1.2, 1.2, 9.0), (x, 0, 4.5), "Black", bevel=0.12, segments=3, parent=root)
        for z in (0.9, 8.1):
            k.box(f"PillarRing{x}{z}", (1.36, 1.36, 0.22), (x, 0, z), "Gold", bevel=0.05, parent=root)
        for i in range(4):
            rune = k.box(f"Rune{x}{i}", (0.5, 0.06, 0.5), (x, -0.62, 2.4 + i * 1.5), "NeonPurple", bevel=0.05,
                         rot=(0, 45, 0), parent=root)
            k.tag(rune, f"pulse_{1 + i * 0.3:g}")
    k.box("Lintel", (9.0, 1.4, 1.2), (0, 0, 9.4), "Black", bevel=0.15, segments=3, parent=root)
    k.box("LintelTrim", (9.2, 1.5, 0.15), (0, 0, 8.85), "Gold", bevel=0.04, parent=root)
    k.box("Plaque", (5.0, 0.1, 0.8), (0, -0.75, 9.4), "Black", bevel=0.04, parent=root)
    k.text("PlaqueText", "REBIRTH", 0.55, (0, -0.82, 9.4), "NeonPurple", extrude=0.02, parent=root, max_width=4.4, logo=True)
    swirl = k.empty("Swirl", (0, 0, 4.7), root)
    for i in range(6):
        a = i / 6 * math.tau
        pts = []
        for j in range(9):
            t = j / 8
            r = 0.3 + t * 2.8
            ang = a + t * 2.2
            pts.append((math.cos(ang) * r, 0, math.sin(ang) * r))
        k.tube(f"Arm{i}", pts, 0.09, "NeonCyan", parent=swirl, radii=[0.4, 0.8, 1.0, 1.0, 0.9, 0.8, 0.6, 0.4, 0.2],
               steps=4)
    k.tag(swirl, k.spin(swirl, "Y", turns=-0.33))


def golden_pedestal(k, root):
    fluted_column(k, "Column", 1.05, 2.4, (0, 0, 0), "Marble", root, flutes=14)
    k.lathe("Top", [(1.3, 0), (1.3, 0.2), (1.2, 0.3), (0.0, 0.3)], (0, 0, 2.4), "Gold", segments=48, parent=root)
    tuber = k.empty("Tuber", (0, 0, 3.6), root)
    k.potato("Golden", (0, 0, 0), 1.8, parent=tuber, key="Gold", seed=12, rot=(5, 10, 30))
    k.tag(tuber, k.bob(tuber, amplitude=0.3, cycles=1))
    for i in range(6):
        a = i / 6 * math.tau
        k.lathe(f"Spark{i}", [(0.0, -0.08), (0.06, 0.0), (0.0, 0.08)], (math.cos(a) * 1.1, math.sin(a) * 1.1, 3.8),
                "NeonYellow", segments=6, parent=root)


def cryo_capsule(k, root):
    k.box("Base", (2.6, 5.0, 0.6), (0, 0, 0.3), "MetalDark", bevel=0.1, parent=root)
    led = k.box("Led", (1.6, 0.06, 0.1), (0, -2.52, 0.4), "NeonCyan", bevel=0.02, parent=root)
    k.tag(led, "pulse_0.8")
    pill = [(0.0, -2.3), (0.6, -2.2), (0.95, -1.9), (1.1, -1.4), (1.15, 0.0), (1.1, 1.4), (0.95, 1.9), (0.6, 2.2),
            (0.0, 2.3)]
    k.lathe("Glass", pill, (0, 0, 1.4), "Glass", segments=32, rot=(90, 0, 0), parent=root, scale=(1.0, 0.9, 1.0))
    k.lathe("Bed", [(0.0, -2.2), (0.95, -2.0), (1.05, 0.0), (0.95, 2.0), (0.0, 2.2)], (0, 0, 0.75), "White",
            segments=24, rot=(90, 0, 0), parent=root, scale=(1.0, 0.25, 1.0))
    for y in (-1.6, 0.0, 1.6):
        k.lathe(f"Hoop{y}", [(1.16, 0), (1.22, 0.03), (1.22, 0.12), (1.16, 0.15)], (0, y, 1.4), "Chrome",
                segments=32, rot=(90, 0, 0), parent=root, scale=(1.0, 0.9, 1.0))
    for x in (-1.1, 1.1):
        k.tube(f"Coolant{x}", [(x, 2.3, 0.6), (x * 1.2, 2.6, 1.2), (x, 2.2, 1.9)], 0.07, "Blue", parent=root)


def street_light(k, root):
    k.lathe("Base", [(0.5, 0), (0.5, 0.25), (0.3, 0.45), (0.2, 0.8), (0.0, 0.8)], (0, 0, 0), "MetalDark",
            segments=24, parent=root)
    k.lathe("Pole", [(0.17, 0), (0.12, 8.2), (0.0, 8.2)], (0, 0, 0.8), "MetalDark", segments=16, parent=root)
    k.tube("Arm", [(0, 0, 8.7), (0, -0.4, 9.2), (0, -1.2, 9.25), (0, -1.8, 9.05)], 0.1, "MetalDark", parent=root)
    k.lathe("Head", [(0.0, 0.25), (0.35, 0.22), (0.62, 0.05), (0.66, -0.05), (0.0, -0.05)], (0, -1.8, 8.85),
            "MetalDark", segments=28, parent=root)
    k.lathe("Lamp", [(0.0, 0.0), (0.5, 0.0), (0.0, -0.12)], (0, -1.8, 8.8), "NeonYellow", segments=28, parent=root)
    k.lathe("Finial", [(0.14, 0), (0.14, 0.1), (0.0, 0.35)], (0, 0, 9.0), "MetalDark", parent=root)


def trash_bin(k, root):
    k.box("Body", (2.2, 1.4, 1.5), (0, 0, 0.8), "Green", bevel=0.12, segments=3, parent=root)
    k.box("Rim", (2.3, 1.5, 0.12), (0, 0, 1.58), "GreenDark", bevel=0.04, parent=root)
    lid = k.empty("Lid", (0, 0.72, 1.65), root, rot=(-10, 0, 0))
    k.box("LidPanel", (2.3, 1.5, 0.12), (0, -0.75, 0.0), "GreenDark", bevel=0.05, parent=lid)
    k.box("LidHandle", (0.8, 0.12, 0.1), (0, -1.45, 0.08), "Black", bevel=0.03, parent=lid)
    k.lathe("Badge", [(0.42, 0), (0.42, 0.04), (0.0, 0.04)], (0, -0.71, 0.9), "White", rot=(90, 0, 0), parent=root)
    for i in range(3):
        a = math.radians(90 + i * 120)
        pts = []
        for j in range(5):
            t = a + math.radians(-25 + j * 15)
            pts.append((math.cos(t) * 0.24, -0.76, 0.9 + math.sin(t) * 0.24))
        k.tube(f"Arrow{i}", pts, 0.04, "Green", parent=root, steps=3)
        tip = pts[-1]
        d = Vector(pts[-1]) - Vector(pts[-2])
        rot_y = -math.degrees(math.atan2(d.z, d.x)) + 90
        k.lathe(f"ArrowHead{i}", [(0.08, 0), (0.0, 0.14)], tip, "Green", segments=8, rot=(0, rot_y, 0), parent=root)
    for x in (-0.8, 0.8):
        for y in (-0.5, 0.5):
            k.lathe(f"Wheel{x}{y}", [(0.12, 0), (0.12, 0.08), (0.0, 0.08)], (x, y, 0.12), "Rubber", rot=(0, 90, 0),
                    parent=root)


def bench(k, root):
    for x in (-1.7, 1.7):
        k.tube(f"Leg{x}", [(x, 0.45, 0.0), (x, 0.35, 0.6), (x, 0.4, 1.05), (x, 0.55, 1.8), (x, 0.62, 2.3)], 0.07,
               "Black", parent=root)
        k.tube(f"FrontLeg{x}", [(x, -0.45, 0.0), (x, -0.4, 0.6), (x, -0.45, 1.05), (x, -0.6, 1.4)], 0.07, "Black",
               parent=root)
        k.tube(f"SeatRail{x}", [(x, -0.55, 1.02), (x, 0.45, 1.02)], 0.06, "Black", parent=root, smooth_path=False)
        k.tube(f"ArmRest{x}", [(x, -0.62, 1.4), (x, 0.0, 1.55), (x, 0.5, 1.5)], 0.06, "Black", parent=root)
    for i in range(4):
        k.box(f"Seat{i}", (4.0, 0.24, 0.08), (0, -0.42 + i * 0.28, 1.1), "Wood" if i % 2 else "WoodLight",
              bevel=0.03, parent=root)
    for i in range(3):
        z = 1.5 + i * 0.28
        k.box(f"Back{i}", (4.0, 0.08, 0.22), (0, 0.48 + i * 0.05, z), "WoodLight" if i % 2 else "Wood", bevel=0.03,
              rot=(-12, 0, 0), parent=root)


def robot(k, root):
    """Робот-помощник; корпус «Blue» игра перекрашивает в цвет сотрудника."""
    for x in (-0.75, 0.75):
        k.box(f"Track{x}", (0.36, 1.5, 0.55), (x, 0, 0.3), "Rubber", bevel=0.18, segments=3, parent=root)
        for y in (-0.45, 0.0, 0.45):
            k.lathe(f"Wheel{x}{y}", [(0.18, 0), (0.18, 0.06), (0.0, 0.06)], (x + math.copysign(0.18, x), y, 0.3),
                    "MetalDark", rot=(0, 90 * (1 if x > 0 else -1), 0), parent=root)
    k.box("Body", (1.5, 1.3, 1.1), (0, 0, 1.05), "Blue", bevel=0.25, segments=3, parent=root)
    k.box("Chest", (0.8, 0.06, 0.4), (0, -0.66, 1.1), "Black", bevel=0.03, parent=root)
    for i in range(3):
        led = k.lens(f"ChestLed{i}", 0.05, (-0.2 + i * 0.2, -0.7, 1.1), ("NeonGreen", "NeonYellow", "NeonRed")[i],
                     rot=(90, 0, 0), parent=root)
        k.tag(led, f"pulse_{1 + i}")
    head = k.empty("Head", (0, 0, 1.6), root)
    k.lathe("Neck", [(0.15, 0), (0.15, 0.15), (0.0, 0.15)], (0, 0, 0), "MetalDark", parent=head)
    k.box("HeadBox", (1.0, 0.85, 0.65), (0, 0, 0.45), "White", bevel=0.22, segments=3, parent=head)
    visor = k.box("Visor", (0.75, 0.06, 0.22), (0, -0.43, 0.5), "NeonCyan", bevel=0.05, parent=head)
    k.tag(visor, "pulse_2")
    k.lathe("Antenna", [(0.03, 0), (0.03, 0.45), (0.0, 0.45)], (0.3, 0, 0.75), "Chrome", segments=8, parent=head)
    tip = k.lens("AntennaTip", 0.08, (0.3, 0, 1.2), "NeonRed", parent=head, height=0.9)
    del tip
    k.tag(head, k.swing(head, "Z", degrees=20, cycles=1))
    for x in (-1, 1):
        k.tube(f"Arm{x}", [(x * 0.75, 0, 1.2), (x * 1.0, -0.2, 0.95), (x * 0.95, -0.45, 0.8)], 0.08, "MetalDark",
               parent=root)
        k.blob(f"Hand{x}", (0.25, 0.25, 0.25), (x * 0.95, -0.5, 0.75), "White", parent=root, jitter=0.0, seed=1,
               levels=1)


def tree(k, root):
    """Ель: ствол и ярусы хвои с зубчатым краем (без «шаров»)."""
    rnd = random.Random(91)
    k.lathe("Trunk", [(0.45, 0), (0.32, 0.6), (0.25, 3.0), (0.0, 3.0)], (0, 0, 0), "WoodDark", segments=12,
            parent=root)
    tiers = [(3.3, 1.4, 2.6), (2.7, 2.9, 2.4), (2.1, 4.2, 2.2), (1.5, 5.4, 2.0), (0.9, 6.5, 1.8)]
    for i, (r, z, h) in enumerate(tiers):
        prof = [(0.0, -0.1), (r * 0.6, 0.0), (r, 0.18), (r * 0.92, 0.32), (r * 0.45, h * 0.6), (0.0, h)]
        tier = k.lathe(f"Tier{i}", prof, (0, 0, z), "LeafDark" if i % 2 else "Leaf", segments=36, parent=root,
                       sharp=70)
        lobes = 9 + i
        phase = rnd.uniform(0, math.tau)
        for v in tier.data.vertices:
            rr = math.hypot(v.co.x, v.co.y)
            if rr > 1e-4:
                a = math.atan2(v.co.y, v.co.x)
                f = 1 + 0.13 * math.cos(a * lobes + phase) * min(1.0, rr / r)
                v.co.x *= f
                v.co.y *= f
                if v.co.z < 0.35:
                    v.co.z -= 0.15 * max(0.0, math.cos(a * lobes + phase))
