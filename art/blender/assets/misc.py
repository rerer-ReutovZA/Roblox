"""Дрон-сборщик, колорадский жук, стартовая площадка и шаттл."""

import math

from mathutils import Vector


def facing(normal):
    """Поворот (градусы), направляющий локальную +Z объекта по нормали."""
    e = Vector(normal).normalized().to_track_quat("Z", "Y").to_euler()
    return tuple(math.degrees(a) for a in e)


# ----------------------------------------------------------------------
# Дрон-сборщик (квадрокоптер с клешнёй)
# ----------------------------------------------------------------------
def propeller(k, name, parent, loc, cw=True):
    prop = k.empty(name, loc, parent)
    k.lathe("PropHub", [(0.07, 0), (0.07, 0.05), (0.05, 0.08), (0.0, 0.09)], (0, 0, -0.03), "MetalDark", parent=prop)
    frame = k.empty("PropFrame", (0, 0, 0), prop, rot=(90, 0, 0))
    for i in (0, 1):
        k.airfoil(f"PropBlade{i}", 0.32, 0.13, 0.06, 18 if cw else -18, "Black", frame, hub=0.04, thick=0.022,
                  angle=i * 180)
    k.tag(prop, k.spin(prop, "Z", turns=8 if cw else -8))
    return prop


def drone(k, root):
    body = k.empty("DroneBody", (0, 0, 1.6), root)
    squash = (1, 1.3, 1)
    k.lathe("Hull", [(0.0, -0.2), (0.3, -0.2), (0.42, -0.15), (0.5, -0.05), (0.51, 0.0)], (0, 0, 0), "Grey",
            parent=body, scale=squash)
    k.lathe("Canopy", [(0.51, 0.0), (0.5, 0.06), (0.45, 0.16), (0.33, 0.26), (0.17, 0.31), (0.0, 0.32)], (0, 0, 0),
            "White", parent=body, scale=squash)
    k.lathe("Seam", [(0.515, -0.03), (0.525, -0.01), (0.525, 0.03), (0.515, 0.05)], (0, 0, 0), "Orange",
            parent=body, scale=squash)
    k.box("Battery", (0.42, 0.62, 0.12), (0, 0.1, 0.33), "MetalDark", bevel=0.05, parent=body)
    # камера на подвесе
    k.lathe("GimbalMount", [(0.1, 0), (0.1, 0.06), (0.0, 0.06)], (0, -0.42, -0.24), "MetalDark", parent=body)
    k.lathe("Gimbal", [(0.0, 0.0), (0.09, 0.01), (0.14, 0.06), (0.15, 0.14), (0.14, 0.24), (0.11, 0.28), (0.0, 0.29)],
            (0, -0.3, -0.38), "Black", rot=(90, 0, 0), parent=body, sharp=70)
    k.lens("Lens", 0.075, (0, -0.585, -0.38), "Glass", rot=(90, 0, 0), parent=body, height=0.5)
    k.lens("LedFront", 0.045, (0, -0.64, 0.02), "NeonGreen", rot=(90, 0, 0), parent=body)
    k.lens("LedBack", 0.045, (0, 0.655, 0.02), "NeonRed", rot=(-90, 0, 0), parent=body)
    for i, (sx, sy) in enumerate(((-1, -1), (1, -1), (1, 1), (-1, 1))):
        tip = Vector((sx * 0.98, sy * 0.98, 0.04))
        k.tube(f"Arm{i}", [(sx * 0.28, sy * 0.36, -0.02), tip], 0.065, "Grey", parent=body, smooth_path=False,
               radii=[1.25, 0.8])
        k.lathe(f"Motor{i}", [(0.12, 0), (0.13, 0.03), (0.13, 0.17), (0.1, 0.21), (0.0, 0.21)],
                tip + Vector((0, 0, -0.04)), "MetalDark", parent=body)
        k.lens(f"ArmLed{i}", 0.035, tip + Vector((0, 0, -0.09)), "NeonGreen" if sy < 0 else "NeonRed",
               rot=(180, 0, 0), parent=body)
        k.torus(f"Guard{i}", 0.44, 0.028, tip + Vector((0, 0, 0.19)), "White", parent=body)
        for g in range(3):
            a = math.radians(45 + g * 120 + (0 if sx * sy > 0 else 60))
            k.tube(f"GuardStrut{i}{g}", [tip + Vector((0, 0, 0.1)),
                                         tip + Vector((math.cos(a) * 0.44, math.sin(a) * 0.44, 0.19))],
                   0.018, "White", parent=body, smooth_path=False)
        propeller(k, f"Prop{i}", body, tip + Vector((0, 0, 0.22)), cw=(i % 2 == 0))
    # посадочные лыжи
    for sx in (-1, 1):
        k.tube(f"Skid{sx}", [(sx * 0.25, -0.3, -0.18), (sx * 0.42, -0.32, -0.52), (sx * 0.44, -0.45, -0.58)], 0.03,
               "Grey", parent=body)
        k.tube(f"SkidBack{sx}", [(sx * 0.25, 0.35, -0.18), (sx * 0.42, 0.37, -0.52), (sx * 0.44, 0.5, -0.58)], 0.03,
               "Grey", parent=body)
        k.tube(f"SkidRail{sx}", [(sx * 0.44, -0.62, -0.55), (sx * 0.44, -0.45, -0.58), (sx * 0.44, 0.5, -0.58),
                                 (sx * 0.44, 0.66, -0.55)], 0.035, "Rubber", parent=body)
    # клешня
    k.cylinder("ClawRod", 0.04, 0.42, (0, 0.12, -0.42), "Chrome", verts=12, bevel=0.0, parent=body)
    claw = k.empty("Claw", (0, 0.12, -0.66), body)
    k.lathe("ClawHub", [(0.0, -0.06), (0.1, -0.06), (0.13, -0.02), (0.13, 0.04), (0.06, 0.06), (0.0, 0.06)], (0, 0, 0),
            "MetalDark", parent=claw)
    for f in range(3):
        a = math.radians(f * 120 + 90)
        c, s = math.cos(a), math.sin(a)
        k.tube(f"Finger{f}", [(c * 0.1, s * 0.1, -0.03), (c * 0.24, s * 0.24, -0.16), (c * 0.2, s * 0.2, -0.34),
                              (c * 0.1, s * 0.1, -0.42)], 0.032, "Chrome", parent=claw, radii=[1.2, 1.0, 0.8, 0.45])
    k.potato("CarriedPotato", (0, 0, -0.27), 0.36, parent=claw, seed=11)
    k.tag(body, k.bob(body, amplitude=0.12, cycles=1))
    k.tag(claw, k.swing(claw, "X", degrees=6, cycles=1, phase=0.25))


# ----------------------------------------------------------------------
# Колорадский жук (вредитель события). Длина ~2.6 стада.
# ----------------------------------------------------------------------
def elytra_stripe(k, name, x0, a, b, c, parent, z0, width=0.05):
    """Чёрная полоса на надкрыльях: повторяет купол и сходится к концам, как у настоящего жука."""
    verts, faces = [], []
    rows = 24
    for r in range(rows + 1):
        t = -0.9 + 1.8 * r / rows
        y = t * b
        taper = (1 - t * t) ** 0.35
        w = width * (0.35 + 0.65 * taper)
        for x in (x0 * taper - w, x0 * taper + w):
            q = 1 - (x / a) ** 2 - (y / b) ** 2
            z = c * math.sqrt(max(q, 0.0)) + 0.006
            verts.append((x, y, z))
    for r in range(rows):
        i = r * 2
        faces.append([i, i + 1, i + 3, i + 2])
    obj = k.mesh_from(name, verts, faces, (0, 0, z0), "Black", parent=parent, smooth=True)
    mod = obj.modifiers.new("Solid", "SOLIDIFY")
    mod.thickness = 0.012
    mod.offset = 1
    return obj


def ellipsoid_point(center, radii, x, y):
    """Точка и нормаль на верхней половине эллипсоида над (x, y) относительно центра."""
    a, b, c = radii
    q = max(1 - (x / a) ** 2 - (y / b) ** 2, 0.0)
    z = c * math.sqrt(q)
    p = Vector(center) + Vector((x, y, z))
    n = Vector((x / a ** 2, y / b ** 2, z / c ** 2 + 1e-6))
    return p, n


def bug(k, root):
    body = k.empty("BugBody", (0, 0, 0), root)
    a, b, c = 0.8, 1.05, 0.66
    z0 = 0.42
    yc = 0.2
    # надкрылья: гладкий купол-эллипсоид с небольшой юбкой и брюшко снизу
    dome = [(1.0, -0.06), (1.0, 0.0)] + [(math.cos(t), math.sin(t)) for t in
                                         [math.pi / 2 * i / 10 for i in range(1, 10)]] + [(0.0, 1.0)]
    k.lathe("Elytra", dome, (0, yc, z0), "Shell", segments=40, parent=body, scale=(a, b, c), sharp=80)
    k.lathe("Belly", [(0.0, -0.3), (0.55, -0.27), (0.85, -0.15), (0.95, -0.05), (0.95, 0.0)], (0, yc, z0), "Black",
            segments=32, parent=body, scale=(a, b, 1.0))
    stripes = k.empty("Stripes", (0, yc, 0), body)
    elytra_stripe(k, "Suture", 0.0, a, b, c, stripes, z0, width=0.02)
    for i, x0 in enumerate((0.14, 0.3, 0.45, 0.58, 0.69)):
        for side in (-1, 1):
            elytra_stripe(k, f"Stripe{i}{side}", side * x0, a, b, c, stripes, z0, width=0.035 if i < 4 else 0.03)
    # переднеспинка с чёрными пятнами
    pc, pr = (0, -0.95, z0 - 0.02), (0.5, 0.3, 0.42)
    k.lathe("Pronotum", [(1.0, -0.15), (1.0, 0.0)] + [(math.cos(t), math.sin(t)) for t in
                                                       [math.pi / 2 * i / 8 for i in range(1, 8)]] + [(0.0, 1.0)],
            pc, "BugOrange", segments=32, parent=body, scale=pr, sharp=80)
    for i, (x, y, r) in enumerate(((0.0, -0.02, 0.07), (-0.2, 0.06, 0.055), (0.2, 0.06, 0.055), (-0.3, -0.1, 0.05),
                                   (0.3, -0.1, 0.05), (-0.1, -0.16, 0.04), (0.1, -0.16, 0.04))):
        p, n = ellipsoid_point(pc, pr, x, y)
        k.lens(f"Spot{i}", r, p - n.normalized() * 0.012, "Black", rot=facing(n), parent=body, height=0.25)
    # голова, глаза, усики
    head = k.empty("HeadGroup", (0, -1.28, z0 - 0.02), body)
    k.blob("Head", (0.62, 0.42, 0.42), (0, 0, 0), "BugOrange", parent=head, jitter=0.0, segments=10, rings=6)
    k.lens("HeadSpot", 0.08, (0, -0.06, 0.2), "Black", rot=(-15, 0, 0), parent=head, height=0.25)
    for side in (-1, 1):
        k.lens(f"Eye{side}", 0.075, (side * 0.25, -0.1, 0.06), "Black", rot=facing((side, -0.5, 0.2)), parent=head,
               height=0.7)
        pts = [(side * 0.14, -0.18, 0.1), (side * 0.3, -0.42, 0.28), (side * 0.42, -0.62, 0.32),
               (side * 0.5, -0.78, 0.3)]
        k.tube(f"Antenna{side}", pts, 0.022, "Black", parent=head, radii=[1.0, 0.85, 1.1, 1.5])
    k.tag(head, k.swing(head, "Z", degrees=8, cycles=2))
    # 6 коротких крепких лап: бедро (оранжевое), голень и лапка (чёрные), походка «треногой»
    for i, y in enumerate((-0.72, -0.25, 0.25)):
        for side in (-1, 1):
            hip = k.empty(f"Hip{i}{side}", (side * 0.5, y, 0.32), body)
            spread = (-0.4, 0.0, 0.45)[i]
            knee = Vector((side * 0.42, spread * 0.45, 0.2))
            ankle = Vector((side * 0.66, spread * 0.8, -0.18))
            foot = Vector((side * 0.76, spread * 0.95, -0.3))
            k.tube(f"Femur{i}{side}", [(0, 0, 0), (side * 0.2, spread * 0.22, 0.16), knee], 0.085, "BugOrange",
                   parent=hip, radii=[1.0, 1.1, 0.8])
            k.tube(f"Tibia{i}{side}", [knee, (knee + ankle) / 2 + Vector((side * 0.04, 0, 0.02)), ankle], 0.06,
                   "Black", parent=hip, radii=[1.05, 0.95, 0.7])
            k.tube(f"Tarsus{i}{side}", [ankle, foot], 0.04, "Black", parent=hip, smooth_path=False, radii=[1.0, 0.7])
            phase = 0.0 if (i % 2 == 0) == (side > 0) else 0.5
            k.tag(hip, k.swing(hip, "Z", degrees=14, cycles=4, phase=phase))
    k.tag(body, k.bob(body, amplitude=0.03, cycles=8))


# ----------------------------------------------------------------------
# Стартовая площадка (14x14) и шаттл
# ----------------------------------------------------------------------
def launch_pad(k, root):
    s = 14.0
    k.box("Slab", (s, s, 0.8), (0, 0, 0.4), "Concrete", bevel=0.25, segments=2, parent=root)
    k.box("SlabTop", (s - 1.2, s - 1.2, 0.2), (0, 0, 0.9), "StoneLight", bevel=0.08, parent=root)
    # газоотводная решётка в центре
    k.box("TrenchFrame", (4.6, 4.6, 0.12), (0, 0, 1.02), "MetalDark", bevel=0.05, parent=root)
    k.box("TrenchHole", (4.0, 4.0, 0.1), (0, 0, 1.03), "Black", bevel=0.0, parent=root)
    for g in range(9):
        k.box(f"Grate{g}", (0.12, 4.0, 0.12), (-1.8 + g * 0.45, 0, 1.06), "Steel", bevel=0.02, parent=root)
    # разметка
    for r in (5.4, 6.2):
        for side in (-1, 1):
            k.box(f"MarkX{r}{side}", (2 * r, 0.22, 0.03), (0, side * r, 1.01), "Yellow", bevel=0.0, parent=root)
            k.box(f"MarkY{r}{side}", (0.22, 2 * r, 0.03), (side * r, 0, 1.01), "Yellow", bevel=0.0, parent=root)
    for i in range(12):
        x = -6.0 + i * 1.1
        k.box(f"Chevron{i}", (0.5, 0.3, 0.03), (x, -6.75, 0.81), "Black" if i % 2 else "Yellow", bevel=0.0,
              rot=(0, 0, 35), parent=root)
    # держатели и огни
    for sx in (-1, 1):
        k.box(f"Clamp{sx}", (0.7, 0.9, 0.9), (sx * 2.6, 0.6, 1.45), "Steel", bevel=0.1, parent=root)
        k.box(f"ClampJaw{sx}", (0.3, 0.6, 0.3), (sx * 2.15, 0.6, 1.75), "Yellow", bevel=0.06, parent=root)
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * 6.4, sy * 6.4
            k.lathe(f"LightPost{sx}{sy}", [(0.22, 0), (0.22, 0.08), (0.12, 0.14), (0.1, 1.35), (0.16, 1.4),
                                           (0.16, 1.48), (0.0, 1.48)], (x, y, 1.0), "MetalDark", parent=root)
            lamp = k.lathe(f"Lamp{sx}{sy}", [(0.15, 0), (0.15, 0.12), (0.13, 0.26), (0.07, 0.34), (0.0, 0.36)],
                           (x, y, 2.48), "NeonRed", parent=root)
            k.tag(lamp, "pulse_1.5")
            k.lathe(f"LampCage{sx}{sy}", [(0.17, 0), (0.17, 0.03), (0.0, 0.03)], (x, y, 2.6), "MetalDark",
                    parent=root)
    # трубопроводы топлива
    k.tube("FuelPipe1", [(6.9, 3, 0.95), (4.5, 3, 0.95), (3.2, 1.2, 1.2)], 0.14, "Chrome", parent=root)
    k.tube("FuelPipe2", [(6.9, 3.5, 0.95), (4.5, 3.5, 0.95), (3.3, 1.8, 1.25)], 0.12, "White", parent=root)
    for i, x in enumerate((5.2, 6.2)):
        k.lathe(f"PipeFlange{i}", [(0.2, 0), (0.2, 0.08), (0.0, 0.08)], (x, 3, 0.95), "MetalDark", rot=(0, 90, 0),
                parent=root)


def ogive(radius, z0, length, steps=10):
    """Профиль носового обтекателя: [(r, z)] от основания радиуса radius до острия."""
    out = []
    for i in range(1, steps + 1):
        t = i / steps
        r = radius * math.cos(t * math.pi / 2) ** 0.75 if i < steps else 0.0
        out.append((r, z0 + length * math.sin(t * math.pi / 2) ** 0.9))
    return out


def ogive_radius(radius, length, dz):
    """Радиус обтекателя на высоте dz над его основанием (обратная к ogive)."""
    s = min(max(dz / length, 0.0), 1.0) ** (1 / 0.9)
    t = math.asin(s) / (math.pi / 2)
    return radius * math.cos(t * math.pi / 2) ** 0.75


def bell(k, name, loc, top_r, bottom_r, height, key, parent, rot=(180, 0, 0)):
    """Сопло-колокол (полое): по умолчанию раструб смотрит вниз."""
    prof = [(top_r * 0.8, -0.02)]
    for i in range(7):
        t = i / 6
        prof.append((top_r + (bottom_r - top_r) * t ** 1.6, height * t))
    prof += [(bottom_r - 0.03, height), (top_r * 0.85 + (bottom_r - top_r) * 0.1 - 0.03, height * 0.15)]
    return k.lathe(name, prof, loc, key, segments=28, rot=rot, parent=parent, sharp=60)


def shuttle(k, root):
    # в игре шаттл ставится поверх стартовой площадки: z = 0 — её верх, сопла стоят на нём
    base = 0.15
    stack = k.empty("Stack", (0, 0, base), root)
    # внешний бак: цилиндр + оживальный нос одним телом
    tank_r = 1.45
    k.lathe("Tank", [(0.0, 0.25), (1.2, 0.25), (1.42, 0.4), (tank_r, 0.6), (tank_r, 10.0)] + ogive(tank_r, 10.0, 2.6),
            (0, 0.65, 0), "Orange", segments=48, parent=stack)
    for z in (2.0, 5.0, 8.0):
        k.lathe(f"TankRib{z}", [(tank_r + 0.005, 0), (tank_r + 0.035, 0.03), (tank_r + 0.035, 0.12),
                                (tank_r + 0.005, 0.15)], (0, 0.65, z), "Copper", segments=48, parent=stack)
    # ускорители
    for side in (-1, 1):
        x = side * 2.2
        k.lathe(f"Booster{side}", [(0.0, 0.5), (0.58, 0.5), (0.62, 0.6), (0.62, 9.7)] + ogive(0.62, 9.7, 1.5),
                (x, 0.65, 0), "White", segments=36, parent=stack)
        for z in (2.5, 7.5):
            k.lathe(f"BoosterBand{side}{z}", [(0.625, 0), (0.66, 0.04), (0.66, 0.2), (0.625, 0.24)], (x, 0.65, z),
                    "Black", segments=36, parent=stack)
        k.lathe(f"BoosterSkirt{side}", [(0.58, 0.6), (0.72, -0.02), (0.75, 0.0), (0.62, 0.6)], (x, 0.65, 0), "White",
                segments=36, parent=stack)
        bell(k, f"BoosterNozzle{side}", (x, 0.65, 0.55), 0.26, 0.46, 0.7, "MetalDark", stack)
        for z in (1.6, 8.5):
            k.tube(f"Strut{side}{z}", [(side * 1.45, 0.65, z), (side * 1.6, 0.65, z)], 0.08, "MetalDark",
                   parent=stack, smooth_path=False)
    # орбитальный корабль «Галактический Картофель» (брюхо смотрит на бак, +Y)
    orb = k.empty("Orbiter", (0, -1.55, 0), stack)
    fr, nose_z, nose_len = 0.95, 7.2, 2.2
    k.lathe("Fuselage", [(0.0, 0.9), (0.85, 0.9), (fr, 1.05), (fr, nose_z)] + ogive(fr, nose_z, nose_len), (0, 0, 0),
            "White", segments=40, parent=orb)
    cap_z = nose_z + nose_len * 0.72
    cap = [(ogive_radius(fr, nose_len, cap_z - nose_z) + 0.012, cap_z)]
    cap += [(r + 0.012 if r > 0 else 0.0, z + 0.004) for r, z in ogive(fr, nose_z, nose_len, steps=20) if z > cap_z]
    k.lathe("NoseCap", cap, (0, 0, 0), "Black", segments=40, parent=orb)

    def belly_profile(t):
        z = 1.0 + (nose_z + 0.6 - 1.0) * t
        return ogive_radius(fr, nose_len, z - nose_z) / fr if z > nose_z else 1.0

    k.shell("BellyTiles", fr + 0.004, 1.0, nose_z + 0.6, 25, 155, (0, 0, 0), "Black", parent=orb, thickness=0.02,
            rows=14, cols=16, profile=belly_profile)
    # окна кабины на верхней стороне (-Y)
    z0, z1 = nose_z + 0.45, nose_z + 0.85

    def win_profile(t):
        return ogive_radius(fr, nose_len, z0 + (z1 - z0) * t - nose_z) / fr

    for i, (a0, a1) in enumerate(((243, 261), (263, 277), (279, 297))):
        k.shell(f"Window{i}", fr + 0.004, z0, z1, a0, a1, (0, 0, 0), "Glass", parent=orb, thickness=0.02, rows=4,
                cols=4, profile=win_profile)
    for side in (-1, 1):
        rot = (0, 0, 0 if side > 0 else 180)
        k.prism(f"Wing{side}", [(0, 0), (2.4, 0.2), (2.4, 0.9), (0, 3.6)], 0.16, (side * 0.8, 0, 1.2), "White",
                parent=orb, rot=rot)
        k.prism(f"WingEdge{side}", [(0, 3.4), (2.3, 0.85), (2.42, 0.95), (0, 3.62)], 0.18, (side * 0.8, 0, 1.2),
                "Black", parent=orb, rot=rot)
        k.lathe(f"OmsPod{side}", [(0.0, 0.0), (0.22, 0.0), (0.24, 0.3), (0.2, 1.4), (0.0, 1.9)],
                (side * 0.55, -0.62, 0.95), "White", segments=20, parent=orb)
    k.prism("TailFin", [(0, 0), (1.5, 0.3), (1.5, 1.0), (0, 2.6)], 0.14, (0, -0.85, 1.3), "White", parent=orb,
            rot=(0, 0, -90))
    k.potato("Emblem", (0.94, -0.2, 5.4), 0.7, parent=orb, key="Gold", seed=7, rot=(0, 90, 0))
    for i, (x, y) in enumerate(((-0.38, -0.25), (0.38, -0.25), (0.0, -0.6))):
        bell(k, f"Engine{i + 1}", (x, y, 0.95), 0.13, 0.3, 0.6, "MetalDark", orb)
    # пламя (в игре показывается только при старте)
    flames = k.empty("Flames", (0, 0, 0), stack)
    for i, (x, y, s) in enumerate(((-2.2, 0.65, 1.0), (2.2, 0.65, 1.0), (0, -1.8, 0.8))):
        flame = k.lathe(f"Flame{i}", [(0.0, 0.0), (0.3 * s, 0.12), (0.44 * s, 0.6), (0.36 * s, 1.5), (0.16 * s, 2.3),
                                      (0.0, 2.8 * s)], (x, y, -0.2), "NeonOrange", segments=20, rot=(180, 0, 0),
                        parent=flames)
        k.lathe(f"FlameCore{i}", [(0.0, 0.0), (0.2 * s, 0.1), (0.25 * s, 0.5), (0.12 * s, 1.2), (0.0, 1.7 * s)],
                (x, y, -0.15), "NeonYellow", segments=16, rot=(180, 0, 0), parent=flames)
        k.wave(flame, "scale", 2, 0.12, cycles=6, phase=i * 0.2)
    # превью: пламя вспыхивает, дрожь перед стартом и подъём
    for f, sc in ((1, 0.001), (10, 0.001), (16, 1.0)):
        flames.scale = (sc, sc, sc)
        flames.keyframe_insert("scale", frame=f)
    for f, z in ((1, 0.0), (14, 0.0), (24, 0.6), (34, 3.0), (48, 9.0)):
        stack.location.z = base + z
        stack.keyframe_insert("location", index=2, frame=f)
    stack.location.z = base
