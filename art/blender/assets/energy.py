"""Энергетика: бензиновый генератор, фермерский ветряк."""

import math

from mathutils import Vector


def gen_petrol(k, root):
    body = k.empty("Body", (0, 0, 0), root)
    # трубчатая рама с закруглёнными углами
    for side in (-1, 1):
        x = side * 1.1
        pts = [(x, -1.05, 0.25), (x, 1.05, 0.25), (x, 1.1, 1.85), (x, -1.1, 1.85), (x, -1.05, 0.25)]
        k.tube(f"FrameLoop{side}", pts, 0.08, "Black", parent=body)
    for y in (-1.08, 1.08):
        for z in (0.25, 1.85):
            k.tube(f"FrameBar{y}{z}", [(-1.1, y, z), (1.1, y, z)], 0.07, "Black", parent=body, smooth_path=False)
    # бак
    k.box("Tank", (1.9, 1.35, 0.62), (0, 0.05, 1.62), "Red", bevel=0.22, segments=3, parent=body)
    k.cylinder("TankCap", 0.17, 0.14, (0.55, -0.2, 2.0), "Chrome", verts=20, bevel=0.03, parent=body)
    k.cylinder("FuelGauge", 0.13, 0.05, (-0.45, -0.25, 1.95), "White", verts=20, bevel=0.0, parent=body)
    k.torus("FuelGaugeRim", 0.13, 0.025, (-0.45, -0.25, 1.98), "Chrome", parent=body)
    # двигатель с рёбрами охлаждения
    k.box("Engine", (1.0, 0.95, 0.8), (-0.35, 0.05, 0.75), "MetalDark", bevel=0.08, parent=body)
    for f in range(6):
        k.box(f"Fin{f}", (1.06, 0.06, 0.62), (-0.35, -0.3 + f * 0.13, 1.0), "Grey", bevel=0.02, parent=body)
    k.cylinder("StarterHousing", 0.36, 0.22, (-0.98, 0.05, 0.85), "Red", rot=(0, 90, 0), verts=28, bevel=0.06,
               parent=body)
    k.box("StarterHandle", (0.12, 0.35, 0.1), (-1.15, 0.05, 0.85), "Black", bevel=0.04, parent=body)
    k.box("AirFilter", (0.5, 0.4, 0.35), (-0.35, 0.65, 1.12), "Black", bevel=0.08, parent=body)
    # альтернатор и глушитель
    k.cylinder("Alternator", 0.38, 0.75, (0.55, 0.15, 0.72), "Red", rot=(0, 90, 0), verts=28, bevel=0.08, parent=body)
    k.cylinder("Muffler", 0.2, 0.75, (0.55, 0.8, 0.55), "Chrome", rot=(0, 90, 0), verts=20, bevel=0.06, parent=body)
    k.box("HeatShield", (0.8, 0.12, 0.36), (0.55, 1.0, 0.55), "MetalDark", bevel=0.04, parent=body)
    k.tube("Exhaust", [(0.95, 0.8, 0.55), (1.2, 0.85, 0.6)], 0.07, "MetalDark", parent=body, smooth_path=False)
    # панель управления спереди
    k.box("Panel", (1.1, 0.1, 0.6), (0.4, -0.75, 0.85), "MetalDark", bevel=0.04, parent=body)
    for i, x in enumerate((0.15, 0.55)):
        k.box(f"Outlet{i}", (0.24, 0.06, 0.24), (x, -0.81, 0.78), "White", bevel=0.04, parent=body)
        for hx in (-0.05, 0.05):
            k.box(f"OutletHole{i}{hx}", (0.03, 0.02, 0.07), (x + hx, -0.845, 0.8), "Black", bevel=0.0, parent=body)
    k.box("Switch", (0.12, 0.08, 0.18), (0.82, -0.82, 0.95), "Red", bevel=0.03, parent=body)
    k.lens("RunLamp", 0.06, (0.82, -0.83, 0.72), "NeonGreen", rot=(90, 0, 0), parent=body)
    k.cylinder("Voltmeter", 0.12, 0.04, (0.35, -0.83, 1.02), "White", rot=(90, 0, 0), verts=20, bevel=0.0, parent=body)
    # колёса и ручка
    for side in (-1, 1):
        k.torus(f"Tyre{side}", 0.24, 0.1, (side * 1.25, 0.8, 0.34), "Rubber", rot=(0, 90, 0), parent=root)
        k.cylinder(f"Hub{side}", 0.15, 0.12, (side * 1.25, 0.8, 0.34), "MetalDark", rot=(0, 90, 0), verts=16,
                   bevel=0.02, parent=root)
        k.box(f"Foot{side}", (0.3, 0.3, 0.12), (side * 0.9, -0.9, 0.06), "Rubber", bevel=0.04, parent=root)
    k.tube("Handle", [(-1.1, -1.1, 1.85), (-1.1, -1.45, 2.05), (1.1, -1.45, 2.05), (1.1, -1.1, 1.85)], 0.06, "Black",
           parent=root)
    # лёгкая вибрация работающего мотора
    k.tag(body, k.slide(body, "X", distance=0.012, cycles=12))


def wind_small(k, root):
    top = 8.6
    k.box("Base", (2.2, 2.2, 0.35), (0, 0, 0.17), "Concrete", bevel=0.08, parent=root)
    legs = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            a = Vector((sx * 0.95, sy * 0.95, 0.35))
            b = Vector((sx * 0.22, sy * 0.22, top))
            k.tube(f"Leg{sx}{sy}", [a, b], 0.07, "Steel", parent=root, smooth_path=False)
            k.box(f"LegPlate{sx}{sy}", (0.34, 0.34, 0.06), (a.x, a.y, 0.37), "MetalDark", bevel=0.02, parent=root)
            legs.append((sx, sy, a, b))
    order = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
    pos = {(sx, sy): (a, b) for sx, sy, a, b in legs}
    for i in range(4):
        p, q = pos[order[i]], pos[order[(i + 1) % 4]]
        for s in range(5):
            t0, t1 = s / 5, (s + 1) / 5
            a0 = p[0] + (p[1] - p[0]) * t0
            b1 = q[0] + (q[1] - q[0]) * t1
            k.tube(f"Zig{i}{s}", [a0, b1], 0.035, "White", parent=root, smooth_path=False)
    # гондола: обтекаемое тело вращения, нос смотрит в -Y
    head = k.empty("Head", (0, 0, top + 0.15), root)
    k.lathe("YawBearing", [(0.36, 0), (0.36, 0.22), (0.3, 0.3), (0.0, 0.3)], (0, 0, -0.05), "MetalDark", parent=head)
    nacelle = [(0.0, 0.0), (0.12, 0.02), (0.24, 0.12), (0.34, 0.35), (0.4, 0.7), (0.41, 1.05), (0.38, 1.4),
               (0.33, 1.6), (0.0, 1.6)]
    k.lathe("Nacelle", nacelle, (0, 1.0, 0.55), "White", rot=(90, 0, 0), parent=head, sharp=80)
    k.lathe("NacelleBand", [(0.417, 0), (0.425, 0.03), (0.425, 0.2), (0.417, 0.23)], (0, 0.08, 0.55), "Red",
            rot=(90, 0, 0), parent=head)
    k.tube("TailBoom", [(0, 0.95, 0.55), (0, 2.1, 0.62)], 0.05, "Steel", parent=head, smooth_path=False)
    k.prism("TailVane", [(0, 0.0), (0.0, 1.0), (0.95, 0.75), (0.95, 0.15)], 0.05, (0, 2.0, 0.2), "Red",
            parent=head, rot=(0, 0, 90), bevel=0.02)
    k.tag(head, k.swing(head, "Z", degrees=6, cycles=1))
    # ротор: ось вдоль -Y
    rotor = k.empty("Rotor", (0, -0.64, 0.55), head)
    k.lathe("Spinner", [(0.3, 0), (0.3, 0.06), (0.27, 0.22), (0.19, 0.38), (0.09, 0.48), (0.0, 0.52)], (0, 0, 0),
            "White", rot=(90, 0, 0), parent=rotor, sharp=80)
    k.lathe("HubPlate", [(0.26, 0), (0.26, 0.1), (0.0, 0.1)], (0, 0.1, 0), "MetalDark", rot=(90, 0, 0), parent=rotor)
    for i in range(3):
        k.airfoil(f"Blade{i}", 2.9, 0.5, 0.16, 22, "White", rotor, t0=0.0, t1=0.86, angle=i * 120)
        k.airfoil(f"BladeTip{i}", 2.9, 0.5, 0.16, 22, "Red", rotor, t0=0.86, t1=1.0, angle=i * 120, sections=2)
    k.tag(rotor, k.spin(rotor, "Y", turns=1))
