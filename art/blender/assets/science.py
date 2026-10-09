"""НИИ квантовой селекции и космодром: лаборатория ДНК, центрифуга, мутагенез, инкубатор, квантовый
облучатель, голотерминал, крио-хранилище, монумент, пусковая вышка, маяк, спутник, терминал звёзд.

Точка Roblox (x, y, z) здесь пишется как (x, -z, y).
"""

import math
import random

from .agro2 import solar_panel


def flask(k, name, loc, liquid, parent, h=0.5, r=0.14):
    """Колба: стекло + светящаяся жидкость."""
    k.lathe(name, [(r * 0.9, 0), (r, 0.05), (r, h * 0.55), (r * 0.45, h * 0.8), (r * 0.45, h), (r * 0.4, h),
                   (r * 0.4, h * 0.8), (r * 0.9, h * 0.55), (r * 0.9, 0.04), (0.0, 0.04)], loc, "Glass", segments=16,
            parent=parent, sharp=60)
    k.lathe(name + "Liquid", [(0.0, 0.0), (r * 0.88, 0.0), (r * 0.88, h * 0.45), (0.0, h * 0.45)],
            (loc[0], loc[1], loc[2] + 0.04), liquid, segments=16, parent=parent)


def star_profile(r_out, r_in, n=5):
    pts = []
    for i in range(n * 2):
        a = math.pi / 2 + i * math.pi / n
        r = r_out if i % 2 == 0 else r_in
        pts.append((math.cos(a) * r, math.sin(a) * r))
    return pts


def dna(k, name, loc, height, radius, parent, turns=1.5, keys=("NeonCyan", "NeonPurple")):
    """Двойная спираль ДНК: две трубки и перекладины-основания."""
    steps = 24
    for s, key in enumerate(keys):
        pts = []
        for i in range(steps + 1):
            t = i / steps
            a = t * turns * math.tau + s * math.pi
            pts.append((loc[0] + math.cos(a) * radius, loc[1] + math.sin(a) * radius, loc[2] + t * height))
        k.tube(f"{name}Strand{s}", pts, radius * 0.12, key, parent=parent, resolution=2, steps=6)
    for i in range(1, 10):
        t = i / 10
        a = t * turns * math.tau
        p = (loc[0] + math.cos(a) * radius, loc[1] + math.sin(a) * radius, loc[2] + t * height)
        q = (loc[0] - math.cos(a) * radius, loc[1] - math.sin(a) * radius, loc[2] + t * height)
        k.tube(f"{name}Base{i}", [p, q], radius * 0.06, "White", parent=parent, smooth_path=False)


# ----------------------------------------------------------------------
# Лаборатория ДНК 12x8 (вход спереди, стеклянные стены — отдельные детали)
# ----------------------------------------------------------------------
def lab(k, root):
    rnd = random.Random(71)
    k.box("Floor", (12.0, 8.0, 0.3), (0, 0, 0.15), "Marble", bevel=0.05, parent=root)
    for x in (-5.9, 5.9):
        for y in (-3.9, 3.9):
            k.box(f"Pillar{x}{y}", (0.32, 0.32, 4.5), (x, y, 2.4), "White", bevel=0.06, parent=root)
    walls = [("GlassBack", (12.0, 0.12, 4.2), (0, 3.9, 2.4)), ("GlassLeft", (0.12, 8.0, 4.2), (-5.9, 0, 2.4)),
             ("GlassRight", (0.12, 8.0, 4.2), (5.9, 0, 2.4)), ("GlassFrontL", (4.5, 0.12, 4.2), (-3.6, -3.9, 2.4)),
             ("GlassFrontR", (4.5, 0.12, 4.2), (3.6, -3.9, 2.4))]
    for name, size, loc in walls:
        k.solo(k.box(name, size, loc, "Glass", bevel=0.0, parent=root))
    for x in (-1.35, 1.35):
        k.box(f"DoorJamb{x}", (0.2, 0.3, 4.2), (x, -3.9, 2.4), "White", bevel=0.04, parent=root)
    k.box("Transom", (2.9, 0.3, 0.6), (0, -3.9, 4.2), "White", bevel=0.04, parent=root)
    for y in (-3.9, 3.9):
        k.box(f"Mullions{y}", (12.0, 0.18, 0.12), (0, y, 1.0), "White", bevel=0.03, parent=root)
    k.solo(k.box("Roof", (12.4, 8.4, 0.4), (0, 0, 4.75), "White", bevel=0.1, parent=root))
    k.box("RoofEdge", (12.5, 8.5, 0.1), (0, 0, 4.98), "Blue", bevel=0.03, parent=root)
    sign = k.empty("Sign", (0, -4.2, 5.45), root)
    k.box("SignBox", (5.4, 0.15, 0.95), (0, 0, 0), "White", bevel=0.08, parent=sign)
    k.text("SignText", "ЛАБОРАТОРИЯ ДНК", 0.42, (0.45, -0.09, 0), "Blue", extrude=0.02, parent=sign, max_width=4.2)
    dna(k, "SignDna", (-2.3, -0.1, -0.38), 0.76, 0.14, sign, turns=1.2)
    k.box("Scanner", (0.4, 0.1, 0.6), (1.65, -4.0, 1.8), "Black", bevel=0.04, parent=root)
    scan = k.box("ScanPad", (0.25, 0.04, 0.3), (1.65, -4.06, 1.8), "NeonGreen", bevel=0.02, parent=root)
    k.tag(scan, "pulse_2")
    # лабораторный стол с колбами и микроскоп
    k.box("BenchTop", (4.0, 1.4, 0.12), (-3.2, 2.8, 1.3), "White", bevel=0.03, parent=root)
    k.box("BenchBody", (3.9, 1.2, 1.0), (-3.2, 2.8, 0.75), "Grey", bevel=0.05, parent=root)
    for i, key in enumerate(("NeonGreen", "NeonCyan", "NeonPurple", "NeonOrange")):
        flask(k, f"Flask{i}", (-4.8 + i * 0.45, 2.6 + rnd.uniform(-0.15, 0.15), 1.36), key, root,
              h=0.45 + rnd.uniform(0, 0.15))
    k.box("ScopeBase", (0.8, 0.6, 0.12), (-1.8, 2.8, 1.42), "White", bevel=0.04, parent=root)
    k.box("ScopeArm", (0.2, 0.25, 0.9), (-1.8, 3.0, 1.9), "White", bevel=0.06, parent=root)
    k.lathe("ScopeTube", [(0.09, 0), (0.12, 0.25), (0.12, 0.55), (0.07, 0.7), (0.0, 0.7)], (-1.8, 2.75, 1.75),
            "MetalDark", rot=(20, 0, 0), parent=root)
    # серверный шкаф нейросети
    k.box("Server", (1.4, 1.2, 3.4), (4.8, 2.9, 1.9), "Black", bevel=0.06, parent=root)
    for i in range(7):
        led = k.box(f"ServerLed{i}", (1.0, 0.04, 0.06), (4.8, 2.28, 0.8 + i * 0.4), "NeonCyan", bevel=0.01,
                    parent=root)
        k.tag(led, f"pulse_{1 + i * 0.3:g}")
    # лазерный стимулятор
    k.box("LaserUnit", (1.4, 1.0, 1.0), (2.6, 2.8, 0.8), "Steel", bevel=0.08, parent=root)
    beam = k.tube("Laser", [(2.6, 2.3, 1.3), (2.6, 1.2, 1.3)], 0.04, "NeonRed", parent=root, smooth_path=False)
    k.tag(beam, "pulse_6")
    # терминал исследований (подсказка — на процедурном терминале в той же точке)
    k.box("TerminalPost", (0.3, 0.3, 1.2), (0, -1.4, 0.75), "Steel", bevel=0.05, parent=root)
    term = k.empty("Terminal", (0, -1.4, 1.8), root, rot=(20, 0, 0))
    k.box("TerminalBox", (1.6, 0.2, 1.2), (0, 0, 0), "Black", bevel=0.06, parent=term)
    k.box("TerminalScreen", (1.4, 0.02, 1.0), (0, -0.11, 0), "NeonGreen", bevel=0.0, parent=term)
    k.text("TerminalText", "СОРТА", 0.26, (0, -0.13, 0), "Black", extrude=0.005, parent=term, max_width=1.2)
    # голограмма ДНК в центре
    holo = k.empty("Helix", (-0.5, 1.0, 0.3), root)
    k.lathe("HoloBase", [(0.5, 0), (0.5, 0.15), (0.35, 0.2), (0.0, 0.2)], (0, 0, 0), "Black", parent=holo)
    dna(k, "Holo", (0, 0, 0.3), 2.4, 0.35, holo, turns=2.0)
    k.tag(holo, k.spin(holo, "Z", turns=0.25))


def centrifuge(k, root):
    k.lathe("Body", [(0.0, 0.0), (1.6, 0.0), (1.7, 0.1), (1.7, 1.45), (1.6, 1.6), (1.3, 1.6), (1.3, 1.3),
                     (0.0, 1.3)], (0, 0, 0), "White", segments=48, parent=root, sharp=60)
    k.lathe("Rim", [(1.705, 0), (1.75, 0.03), (1.75, 0.15), (1.705, 0.18)], (0, 0, 1.3), "Steel", segments=48,
            parent=root)
    rotor = k.empty("Rotor", (0, 0, 1.4), root)
    k.lathe("Hub", [(0.35, 0), (0.35, 0.2), (0.15, 0.3), (0.0, 0.3)], (0, 0, 0), "Chrome", parent=rotor)
    for i in range(6):
        a = i / 6 * math.tau
        holder = k.empty(f"Holder{i}", (math.cos(a) * 0.95, math.sin(a) * 0.95, 0.2), rotor,
                         rot=(0, 35, math.degrees(a)))
        k.lathe("Tube", [(0.0, -0.3), (0.14, -0.25), (0.15, 0.25), (0.12, 0.3), (0.0, 0.3)], (0, 0, 0), "NeonCyan",
                segments=12, parent=holder)
    k.tag(rotor, k.spin(rotor, "Z", turns=4))
    lid = [(1.3, 0.0), (1.25, 0.25), (1.05, 0.5), (0.7, 0.68), (0.0, 0.74)]
    k.lathe("Lid", lid + [(0.0, 0.7), (0.68, 0.64), (1.02, 0.47), (1.21, 0.24), (1.26, 0.0)], (0, 0, 1.6), "Glass",
            segments=40, parent=root, sharp=70)
    k.box("Panel", (0.9, 0.06, 0.4), (0, -1.68, 0.95), "Black", bevel=0.03, rot=(-8, 0, 0), parent=root)
    led = k.box("PanelLed", (0.6, 0.03, 0.18), (0, -1.71, 0.97), "NeonGreen", bevel=0.01, rot=(-8, 0, 0),
                parent=root)
    k.tag(led, "pulse_2")


def mutagenesis(k, root):
    k.box("Chamber", (4.6, 4.6, 3.6), (0, 0, 1.8), "MetalDark", bevel=0.2, segments=3, parent=root)
    k.box("Cap", (4.8, 4.8, 0.4), (0, 0, 3.8), "Yellow", bevel=0.1, parent=root)
    for i in range(10):
        k.box(f"Stripe{i}", (0.25, 4.82, 0.42), (-2.1 + i * 0.47, 0, 3.8), "Black", bevel=0.0, rot=(0, 35, 0),
              parent=root)
    k.box("WindowFrame", (2.2, 0.2, 1.8), (0, -2.3, 2.0), "Steel", bevel=0.08, parent=root)
    k.box("Window", (1.8, 0.1, 1.4), (0, -2.36, 2.0), "NeonGreen", bevel=0.04, parent=root)
    sign = k.empty("Trefoil", (0, -2.33, 3.05), root)
    k.box("SignPlate", (1.0, 0.04, 1.0), (0, 0, 0), "Yellow", bevel=0.04, parent=sign)
    for i in range(3):
        a0 = math.radians(90 + i * 120 - 30)
        a1 = math.radians(90 + i * 120 + 30)
        prof = [(math.cos(a0) * 0.1, math.sin(a0) * 0.1)]
        prof += [(math.cos(a0 + (a1 - a0) * t / 6) * 0.42, math.sin(a0 + (a1 - a0) * t / 6) * 0.42) for t in range(7)]
        prof += [(math.cos(a1) * 0.1, math.sin(a1) * 0.1)]
        k.prism(f"Blade{i}", prof, 0.02, (0, -0.03, 0), "Black", parent=sign, bevel=0.0)
    k.lathe("Dot", [(0.07, 0), (0.07, 0.02), (0.0, 0.02)], (0, -0.03, 0), "Black", rot=(90, 0, 0), parent=sign)
    for x in (-2.0, 2.0):
        k.tube(f"Pipe{x}", [(x, 2.3, 0.6), (x, 2.7, 0.6), (x, 2.7, 3.5)], 0.14, "Steel", parent=root,
               smooth_path=False)
    lamp = k.lathe("Warning", [(0.15, 0), (0.17, 0.05), (0.15, 0.3), (0.0, 0.35)], (1.8, -1.8, 4.0), "NeonGreen",
                   parent=root)
    k.tag(lamp, "pulse_2")


def incubator(k, root):
    rnd = random.Random(73)
    k.box("Base", (3.6, 4.6, 0.3), (0, 0, 0.15), "White", bevel=0.05, parent=root)
    for x in (-1.75, 1.75):
        for y in (-2.25, 2.25):
            k.box(f"Post{x}{y}", (0.12, 0.12, 3.7), (x, y, 2.15), "White", bevel=0.03, parent=root)
    for name, size, loc in (("GlassF", (3.4, 0.05, 3.6), (0, -2.28, 2.1)), ("GlassB", (3.4, 0.05, 3.6), (0, 2.28, 2.1)),
                            ("GlassL", (0.05, 4.4, 3.6), (-1.78, 0, 2.1)), ("GlassR", (0.05, 4.4, 3.6), (1.78, 0, 2.1))):
        k.box(name, size, loc, "Glass", bevel=0.0, parent=root)
    k.box("Top", (3.7, 4.7, 0.3), (0, 0, 4.05), "White", bevel=0.06, parent=root)
    k.box("Lamp", (3.3, 4.3, 0.06), (0, 0, 3.88), "NeonYellow", bevel=0.02, parent=root)
    for t in range(3):
        z = 1.0 + t
        k.box(f"Shelf{t}", (3.3, 4.3, 0.08), (0, 0, z), "White", bevel=0.02, parent=root)
        for x in (-0.8, 0.8):
            for j in range(5):
                k.seedling(f"Sprout{t}{x}{j}", (x, -1.6 + j * 0.8, z + 0.16), root, rnd, scale=1.1, leaves=5)
    k.box("Panel", (1.0, 0.08, 0.5), (0.9, -2.33, 3.4), "Black", bevel=0.03, parent=root)
    k.text("Temp", "37°", 0.22, (0.9, -2.38, 3.4), "NeonRed", extrude=0.01, parent=root)


def quantum_irradiator(k, root):
    k.lathe("Base", [(2.2, 0), (2.2, 0.3), (1.9, 0.5), (0.0, 0.5)], (0, 0, 0), "MetalDark", segments=48, parent=root)
    k.lathe("Column", [(0.5, 0), (0.42, 3.6), (0.6, 3.9), (0.0, 4.0)], (0, 0, 0.5), "Black", segments=24,
            parent=root)
    rings = k.empty("Rings", (0, 0, 2.8), root)
    for i, z in enumerate((-1.2, 0.0, 1.2)):
        k.torus(f"Ring{i}", 1.25 - i * 0.15, 0.07, (0, 0, z), "NeonCyan", parent=rings, seg=48, ring=8)
    k.tag(rings, k.bob(rings, amplitude=0.4, cycles=1))
    head = k.empty("Head", (0, 0, 4.9), root, rot=(-25, 0, 0))
    k.lathe("Emitter", [(0.0, 0.0), (0.4, 0.0), (1.1, 0.25), (1.2, 0.4), (1.1, 0.45), (0.4, 0.2), (0.0, 0.2)],
            (0, 0, 0), "White", segments=40, parent=head, sharp=60)
    k.lens("Lens", 0.35, (0, 0, 0.1), "NeonCyan", rot=(180, 0, 0), parent=head, height=0.5)
    for i in range(3):
        a = i / 3 * math.tau
        k.tube(f"Strut{i}", [(math.cos(a) * 0.35, math.sin(a) * 0.35, 4.2), (math.cos(a) * 0.7, math.sin(a) * 0.7,
                                                                            4.75)], 0.05, "Steel", parent=root,
               smooth_path=False)


def holo_terminal(k, root):
    k.prism("Desk", [(-1.3, 0.0), (1.3, 0.0), (1.3, 1.25), (-1.3, 1.25)], 1.6, (0, 0, 0), "Black", parent=root,
            bevel=0.08)
    k.box("DeskTop", (2.5, 1.5, 0.1), (0, 0, 1.28), "MetalDark", bevel=0.04, parent=root)
    glow = k.box("Projector", (2.3, 1.3, 0.04), (0, 0, 1.34), "NeonCyan", bevel=0.02, parent=root)
    k.tag(glow, "pulse_1")
    holo = k.empty("Holo", (0, 0, 1.4), root)
    k.lathe("Trunk", [(0.07, 0), (0.05, 2.2), (0.0, 2.2)], (0, 0, 0), "NeonCyan", segments=8, parent=holo)
    for i in range(6):
        a = i / 6 * math.tau
        z = 0.4 + i * 0.25
        tip = (math.cos(a) * 0.9, math.sin(a) * 0.9, z + 0.6)
        k.tube(f"Branch{i}", [(0, 0, z), tip], 0.035, "NeonCyan", parent=holo, smooth_path=False)
        k.lathe(f"Node{i}", [(0.0, -0.16), (0.12, -0.12), (0.16, 0.0), (0.12, 0.12), (0.0, 0.16)], tip, "NeonCyan",
                segments=12, parent=holo)
    k.tag(holo, k.spin(holo, "Z", turns=0.22))
    for x in (-0.9, 0.9):
        k.box(f"Key{x}", (0.5, 0.25, 0.04), (x, -0.55, 1.36), "NeonPurple", bevel=0.01, parent=root)


def seed_vault(k, root):
    k.box("Bunker", (3.8, 3.8, 3.4), (0, 0, 1.7), "Concrete", bevel=0.2, segments=3, parent=root)
    k.box("IceCap", (4.0, 4.0, 0.35), (0, 0, 3.55), "Ice", bevel=0.15, parent=root)
    for i in range(6):
        k.lens(f"Icicle{i}", 0.08, (-1.6 + i * 0.64, -2.0, 3.36), "Ice", rot=(180, 0, 0), parent=root, height=2.5)
    k.box("Portal", (2.8, 0.3, 2.8), (0, -1.95, 1.7), "Steel", bevel=0.1, parent=root)
    door = k.empty("Door", (0, -2.1, 1.7), root, rot=(90, 0, 0))
    k.lathe("DoorDisc", [(1.15, 0), (1.15, 0.2), (1.0, 0.28), (0.0, 0.3)], (0, 0, 0), "Chrome", segments=40,
            parent=door)
    for i in range(10):
        a = i / 10 * math.tau
        k.lathe(f"Bolt{i}", [(0.06, 0), (0.06, 0.06), (0.0, 0.08)], (math.cos(a) * 0.95, math.sin(a) * 0.95, 0.2),
                "MetalDark", parent=door)
    k.torus("Handwheel", 0.45, 0.05, (0, 0, 0.45), "MetalDark", parent=door)
    for i in range(3):
        k.box(f"Spoke{i}", (0.9, 0.06, 0.06), (0, 0, 0.45), "MetalDark", bevel=0.02, rot=(0, 0, i * 60),
              parent=door)
    k.text("Label", "ГЕНОФОНД", 0.28, (0, -2.12, 3.0), "Blue", extrude=0.015, parent=root, max_width=2.4)


def god_monument(k, root):
    k.box("Plinth", (4.0, 6.0, 1.0), (0, 0, 0.5), "Marble", bevel=0.1, parent=root)
    k.box("Pedestal", (3.0, 5.0, 1.2), (0, 0, 1.6), "StoneLight", bevel=0.1, parent=root)
    k.box("Cornice", (3.3, 5.3, 0.15), (0, 0, 2.27), "Marble", bevel=0.05, parent=root)
    for x in (-1.6, 1.6):
        k.lathe(f"Candle{x}", [(0.15, 0), (0.15, 0.6), (0.0, 0.62)], (x, -2.6, 1.0), "White", parent=root)
        flame = k.lathe(f"Flame{x}", [(0.0, 0.0), (0.07, 0.06), (0.06, 0.16), (0.0, 0.26)], (x, -2.6, 1.62),
                        "NeonOrange", segments=10, parent=root)
        k.tag(flame, "pulse_3")
    idol = k.empty("Idol", (0, 0, 2.35), root)
    k.blob("Body", (2.6, 2.3, 4.0), (0, 0, 2.2), "Gold", parent=idol, jitter=0.05, seed=9, segments=10, rings=8)
    for x in (-0.5, 0.5):
        k.lens(f"Eye{x}", 0.32, (x, -1.12, 2.9), "White", rot=(90, 0, 0), parent=idol, height=0.45)
        k.lens(f"Pupil{x}", 0.14, (x * 1.05, -1.25, 2.88), "Black", rot=(90, 0, 0), parent=idol, height=0.5)
    k.tube("Smile", [(-0.4, -1.13, 2.3), (0.0, -1.22, 2.12), (0.4, -1.13, 2.3)], 0.06, "Black", parent=idol)
    k.lathe("Crown", [(0.75, 0), (0.75, 0.35), (0.7, 0.4), (0.0, 0.4)], (0, 0, 4.1), "Gold", segments=40,
            parent=idol)
    for i in range(5):
        a = i / 5 * math.tau
        k.lathe(f"Spike{i}", [(0.15, 0), (0.0, 0.5)], (math.cos(a) * 0.62, math.sin(a) * 0.62, 4.45), "Gold",
                segments=8, parent=idol)
        k.lens(f"Gem{i}", 0.08, (math.cos(a) * 0.76, math.sin(a) * 0.76, 4.3), "NeonRed",
               rot=(90, 0, math.degrees(a) + 90), parent=idol)
    k.tag(idol, k.bob(idol, amplitude=0.3, cycles=1))
    k.box("Plaque", (2.4, 0.06, 0.6), (0, -2.53, 1.6), "Gold", bevel=0.02, parent=root)
    k.text("PlaqueText", "КАРТОФЕЛЬНЫЙ БОГ", 0.2, (0, -2.57, 1.6), "Black", extrude=0.01, parent=root,
           max_width=2.2)


def launch_tower(k, root):
    k.box("Base", (4.0, 6.0, 0.6), (0, 0, 0.3), "Concrete", bevel=0.08, parent=root)
    h = 22.0
    for x in (-1.2, 1.2):
        for y in (-1.2, 1.2):
            k.box(f"Leg{x}{y}", (0.35, 0.35, h), (x, y, 0.6 + h / 2), "RedMetal", bevel=0.05, parent=root)
    for i in range(1, 11):
        z = 0.6 + i * 2
        for y in (-1.2, 1.2):
            k.tube(f"BraceX{i}{y}", [(-1.2, y, z - 2 + 0.2), (1.2, y, z - 0.2)] if i % 2 else
                   [(1.2, y, z - 2 + 0.2), (-1.2, y, z - 0.2)], 0.07, "RedMetal", parent=root, smooth_path=False)
        k.tube(f"BraceY{i}", [(1.2, -1.2, z - 2 + 0.2), (1.2, 1.2, z - 0.2)], 0.07, "RedMetal", parent=root,
               smooth_path=False)
        k.box(f"Ring{i}", (2.6, 2.6, 0.14), (0, 0, z), "MetalDark", bevel=0.03, parent=root)
    # руки обслуживания к шаттлу (запад, -X)
    for z in (8.0, 14.0, 19.0):
        k.box(f"Arm{z}", (6.0, 1.0, 0.35), (-4.0, 0, z), "MetalDark", bevel=0.06, parent=root)
        k.box(f"ArmRail{z}", (6.0, 0.06, 0.06), (-4.0, -0.48, z + 0.9), "Yellow", bevel=0.01, parent=root)
        k.tube(f"ArmBrace{z}", [(-1.2, 0, z - 1.6), (-4.0, 0, z - 0.15)], 0.08, "MetalDark", parent=root,
               smooth_path=False)
        for j in range(5):
            k.box(f"ArmPost{z}{j}", (0.06, 0.06, 0.9), (-6.8 + j * 1.4, -0.48, z + 0.45), "Yellow", bevel=0.01,
                  parent=root)
    k.tube("Umbilical1", [(-1.2, -0.8, 12.0), (-4.0, -0.8, 10.6), (-7.0, -0.8, 9.0)], 0.22, "Black", parent=root)
    k.tube("Umbilical2", [(-1.2, 0.8, 16.0), (-4.0, 0.8, 14.6), (-7.0, 0.8, 13.0)], 0.22, "Black", parent=root)
    k.box("Elevator", (1.0, 1.0, 1.6), (0.6, -0.6, 6.0), "Yellow", bevel=0.08, parent=root)
    k.tube("ElevatorCable", [(0.6, -0.6, 6.8), (0.6, -0.6, h)], 0.03, "Black", parent=root, smooth_path=False)
    top = k.lathe("TopBeacon", [(0.3, 0), (0.32, 0.1), (0.26, 0.45), (0.0, 0.55)], (0, 0, h + 0.6), "NeonRed",
                  parent=root)
    k.tag(top, "pulse_1")
    k.box("TopPlate", (2.8, 2.8, 0.2), (0, 0, h + 0.5), "MetalDark", bevel=0.04, parent=root)


def beacon(k, root):
    k.lathe("Base", [(0.8, 0), (0.8, 0.3), (0.55, 0.4), (0.0, 0.4)], (0, 0, 0), "Concrete", segments=32, parent=root)
    k.lathe("Mast", [(0.17, 0), (0.12, 10.0), (0.0, 10.0)], (0, 0, 0.4), "White", segments=16, parent=root)
    for z in (2.5, 5.0, 7.5):
        k.lathe(f"Band{z}", [(0.16, 0), (0.16, 0.6), (0.0, 0.6)], (0, 0, z), "Red", segments=16, parent=root)
    k.lathe("LampBase", [(0.3, 0), (0.3, 0.15), (0.0, 0.15)], (0, 0, 10.3), "MetalDark", parent=root)
    lamp = k.lathe("Lamp", [(0.0, 0.0), (0.32, 0.02), (0.36, 0.3), (0.28, 0.6), (0.0, 0.7)], (0, 0, 10.45), "NeonRed",
                   segments=24, parent=root)
    k.tag(lamp, "pulse_1.2")
    k.lathe("LampCap", [(0.32, 0), (0.32, 0.06), (0.0, 0.12)], (0, 0, 11.1), "MetalDark", parent=root)
    solar_panel(k, "Solar", 0.8, 0.6, (0, -0.35, 1.6), -40, root)


def satellite(k, root):
    k.box("Base", (2.6, 2.6, 0.6), (0, 0, 0.3), "Concrete", bevel=0.08, parent=root)
    k.lathe("Pedestal", [(0.3, 0), (0.25, 2.6), (0.35, 2.8), (0.0, 2.8)], (0, 0, 0.6), "Steel", segments=16,
            parent=root)
    dish = k.empty("Dish", (0, 0, 3.4), root)
    k.lathe("Gimbal", [(0.4, -0.2), (0.4, 0.2), (0.0, 0.25)], (0, 0, 0), "MetalDark", parent=dish)
    holder = k.empty("Tilt", (0, 0, 0.3), dish, rot=(40, 0, 0))
    prof = [(0.0, 0.0)] + [(1.6 * i / 8, 0.5 * (i / 8) ** 2) for i in range(1, 9)] + [(1.56, 0.52), (0.0, 0.08)]
    k.lathe("Reflector", prof, (0, 0, 0), "White", segments=40, parent=holder, sharp=60)
    for i in range(3):
        a = i / 3 * math.tau
        k.tube(f"FeedStrut{i}", [(math.cos(a) * 1.4, math.sin(a) * 1.4, 0.45), (0, 0, 1.25)], 0.03, "MetalDark",
               parent=holder, smooth_path=False)
    led = k.lathe("Feed", [(0.12, 0), (0.12, 0.2), (0.0, 0.25)], (0, 0, 1.2), "NeonRed", parent=holder)
    del led
    k.tag(dish, k.spin(dish, "Z", turns=0.083))


def star_terminal(k, root):
    k.box("Base", (2.6, 2.6, 0.4), (0, 0, 0.2), "NeonPurple", bevel=0.06, parent=root)
    k.box("BaseTop", (2.4, 2.4, 0.1), (0, 0, 0.42), "Black", bevel=0.03, parent=root)
    k.box("Kiosk", (1.6, 1.0, 2.4), (0, 0.3, 1.6), "Gold", bevel=0.2, segments=3, parent=root)
    k.box("Screen", (1.4, 0.1, 1.0), (0, -0.22, 2.2), "Black", bevel=0.05, parent=root)
    k.text("ScreenText", "ЗВЁЗДЫ", 0.26, (0, -0.28, 2.2), "NeonYellow", extrude=0.01, parent=root, max_width=1.2)
    star = k.empty("Star", (0, 0.3, 3.45), root)
    k.prism("StarShape", star_profile(0.7, 0.3), 0.25, (0, 0, 0), "NeonYellow", parent=star, bevel=0.06)
    k.tag(star, k.bob(star, amplitude=0.3, cycles=1))
    for i in range(4):
        a = i / 4 * math.tau + math.pi / 4
        k.lathe(f"Light{i}", [(0.08, 0), (0.08, 0.06), (0.0, 0.1)], (math.cos(a) * 1.1, math.sin(a) * 1.1, 0.47),
                "NeonYellow", parent=root)
