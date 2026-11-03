#!/usr/bin/env python3
"""Writes Deen's Rive animations (assets/rive/*.riv) from code.

The files are drawn here, not in the Rive editor, so they are Deen's own
work under the app's licence. Format: Rive runtime binary v7 (see the rive
package's runtime_header.dart and generated/*_base.dart for the keys).

Run: python3 tool/build_rive.py
"""
import math
import random
import struct
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / 'assets' / 'rive'

# Deen palette (lib/app/theme/app_theme.dart).
BRAND = 0xFF0E6B5C
BRAND_DEEP = 0xFF0A4A3F
IVORY = 0xFFF8F6F1
GOLD = 0xFFC9A24B
GOLD_LIGHT = 0xFFE6C878
TEAL = 0xFF2BA38C
WHITE = 0xFFFFFFFF
ROSE = 0xFFE0876A

# Type keys.
BACKBOARD, ARTBOARD, NODE, SHAPE, ELLIPSE, RECTANGLE = 23, 1, 2, 3, 4, 7
POINTS_PATH, STRAIGHT_VERTEX, STAR = 16, 5, 52
FILL, STROKE, SOLID_COLOR = 20, 24, 18
LINEAR_ANIMATION, KEYED_OBJECT, KEYED_PROPERTY = 31, 25, 26
KEYFRAME_DOUBLE, KEYFRAME_COLOR = 30, 37

# Property keys by field type.
NAME, PARENT = 4, 5
X, Y, ROTATION, SCALE_X, SCALE_Y, OPACITY = 13, 14, 15, 16, 17, 18
STRING = {4, 55, 138}
COLOR = {37, 88, 38}
DOUBLE = {7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 24, 25, 26,
          31, 33, 34, 35, 39, 42, 46, 47, 58, 63, 64, 65, 66, 70, 82, 83, 84,
          85, 86, 87, 123, 124, 126, 127, 161, 162, 163}
# Everything else (ids, enums, flags and bools) is a varuint.


def varuint(n):
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


def encode(key, value):
    if key in STRING:
        raw = value.encode()
        return varuint(key) + varuint(len(raw)) + raw
    if key in COLOR:
        return varuint(key) + struct.pack('<I', value)
    if key in DOUBLE:
        return varuint(key) + struct.pack('<f', value)
    return varuint(key) + varuint(int(value))


class Riv:
    """One artboard; components get ids in the order they are added."""

    def __init__(self, name, width, height):
        self.objects = [(BACKBOARD, {})]
        self.artboard = [(ARTBOARD, {NAME: name, 7: width, 8: height})]
        self.animations = []

    def add(self, type_key, parent=0, props=None):
        p = {PARENT: parent}
        p.update(props or {})
        self.artboard.append((type_key, p))
        return len(self.artboard) - 1

    def node(self, parent=0, x=0.0, y=0.0):
        return self.add(NODE, parent, {X: x, Y: y})

    def shape(self, parent=0, x=0.0, y=0.0, opacity=1.0, rotation=0.0,
              scale=1.0):
        return self.add(SHAPE, parent, {X: x, Y: y, OPACITY: opacity,
                                          ROTATION: rotation, SCALE_X: scale,
                                          SCALE_Y: scale})

    def fill(self, shape, color):
        f = self.add(FILL, shape)
        return self.add(SOLID_COLOR, f, {37: color})

    def stroke(self, shape, color, width, round_cap=True):
        s = self.add(STROKE, shape, {47: width, 48: 1 if round_cap else 0,
                                       49: 1 if round_cap else 0})
        return self.add(SOLID_COLOR, s, {37: color})

    def ellipse(self, shape, w, h=None):
        return self.add(ELLIPSE, shape, {20: w, 21: h or w})

    def rect(self, shape, w, h, radius=0.0):
        return self.add(RECTANGLE, shape, {20: w, 21: h, 164: 1, 31: radius,
                                             161: radius, 162: radius,
                                             163: radius})

    def star(self, shape, size, points, inner):
        return self.add(STAR, shape, {20: size, 21: size, 125: points,
                                        127: inner})

    def polygon(self, shape, pts):
        path = self.add(POINTS_PATH, shape, {32: 1})
        for x, y in pts:
            self.add(STRAIGHT_VERTEX, path, {24: x, 25: y})
        return path

    def animation(self, name, frames, loop, fps=60):
        """loop: 0 one shot, 1 loop, 2 ping-pong. Returns key(obj, prop, kfs)."""
        anim = [(LINEAR_ANIMATION, {55: name, 56: fps, 57: frames, 59: loop})]
        self.animations.append(anim)

        def key(obj, prop, kfs, color=False):
            anim.append((KEYED_OBJECT, {51: obj}))
            anim.append((KEYED_PROPERTY, {53: prop}))
            for frame, value, *interp in kfs:
                kind = interp[0] if interp else 1
                if color:
                    anim.append((KEYFRAME_COLOR, {67: frame, 68: kind,
                                                  88: value}))
                else:
                    anim.append((KEYFRAME_DOUBLE, {67: frame, 68: kind,
                                                   70: float(value)}))
        return key

    def _painter_order(self):
        """Components so that later-added siblings draw on top.

        The runtime draws the first drawable on top, so siblings that are
        shapes or groups are written in reverse; paints and paths keep their
        order. Ids are remapped for parents and keyed objects.
        """
        children = {}
        for i, (_, props) in enumerate(self.artboard[1:], 1):
            children.setdefault(props[PARENT], []).append(i)
        order = [0]

        def visit(i):
            kids = children.get(i, [])
            groups = [k for k in kids if self.artboard[k][0] in (SHAPE, NODE)]
            rest = [k for k in kids if k not in groups]
            for k in rest + groups[::-1]:
                order.append(k)
                visit(k)
        visit(0)
        new_id = {old: new for new, old in enumerate(order)}
        comps = []
        for old in order:
            t, props = self.artboard[old]
            props = dict(props)
            if old:
                props[PARENT] = new_id[props[PARENT]]
            else:
                props.pop(PARENT, None)
            comps.append((t, props))
        anims = [[(t, {**p, 51: new_id[p[51]]} if t == KEYED_OBJECT else p)
                  for t, p in a] for a in self.animations]
        return comps, anims

    def bytes(self):
        comps, anims = self._painter_order()
        out = bytearray(b'RIVE' + varuint(7) + varuint(0) + varuint(0))
        out += varuint(0)  # no extra property keys: all are core keys
        for type_key, props in (self.objects + comps +
                                [o for a in anims for o in a]):
            out += varuint(type_key)
            for k, v in props.items():
                out += encode(k, v)
            out += varuint(0)
        return bytes(out)


def eased(f0, f1, v0, v1, steps=6, ease=lambda t: 0.5 - math.cos(math.pi * t) / 2):
    """Keyframes from f0 to f1 sampling an easing curve (linear between)."""
    return [(round(f0 + (f1 - f0) * i / steps),
             v0 + (v1 - v0) * ease(i / steps)) for i in range(steps + 1)]


def crescent(r, inner_r, offset, n=28):
    """Points of a crescent: the outer circle minus a circle shifted right."""
    # Where the circles cross.
    cx = (r * r - inner_r * inner_r + offset * offset) / (2 * offset)
    cy = math.sqrt(max(r * r - cx * cx, 0))
    a0 = math.atan2(cy, cx)
    outer = [(r * math.cos(a), r * math.sin(a))
             for a in [a0 + (2 * math.pi - 2 * a0) * i / n for i in range(n + 1)]]
    b0 = math.atan2(-cy, cx - offset)
    b1 = math.atan2(cy, cx - offset)
    if b1 < b0:
        b1 += 2 * math.pi
    # Inner arc goes back the short way, through the side facing the outer arc.
    inner = [(offset + inner_r * math.cos(b), inner_r * math.sin(b))
             for b in [b0 - (2 * math.pi - (b1 - b0)) * i / n for i in range(1, n)]]
    return outer + inner


def splash():
    riv = Riv('splash', 256, 256)
    c = 128
    glow = riv.shape(x=c, y=c, opacity=0.25)
    riv.ellipse(glow, 236)
    riv.fill(glow, GOLD_LIGHT)
    outer = riv.shape(x=c, y=c)
    riv.star(outer, 204, 8, 0.78)
    riv.fill(outer, BRAND)
    inner = riv.shape(x=c, y=c)
    riv.star(inner, 164, 8, 0.78)
    riv.fill(inner, GOLD)
    disc = riv.shape(x=c, y=c)
    riv.ellipse(disc, 124)
    riv.fill(disc, BRAND_DEEP)
    moon = riv.shape(x=c - 4, y=c)
    riv.polygon(moon, crescent(36, 30, 16))
    riv.fill(moon, IVORY)
    tiny = riv.shape(x=c + 22, y=c - 14)
    riv.star(tiny, 18, 5, 0.45)
    riv.fill(tiny, GOLD_LIGHT)
    orbit = riv.node(x=c, y=c)
    dots = []
    for i in range(8):
        a = i * math.pi / 4
        d = riv.shape(orbit, x=116 * math.cos(a), y=116 * math.sin(a))
        riv.ellipse(d, 7)
        riv.fill(d, GOLD if i % 2 else BRAND)
        dots.append(d)

    key = riv.animation('main', 240, 1)
    key(outer, ROTATION, [(0, 0), (240, math.pi / 4)])
    key(inner, ROTATION, [(0, 0), (240, -math.pi / 4)])
    key(orbit, ROTATION, [(0, 0), (240, math.pi / 4)])
    breathe = eased(0, 120, 0.94, 1.04) + eased(120, 240, 1.04, 0.94)[1:]
    key(moon, SCALE_X, breathe)
    key(moon, SCALE_Y, breathe)
    key(glow, OPACITY, eased(0, 120, 0.18, 0.45) + eased(120, 240, 0.45, 0.18)[1:])
    glow_s = eased(0, 120, 0.92, 1.0) + eased(120, 240, 1.0, 0.92)[1:]
    key(glow, SCALE_X, glow_s)
    key(glow, SCALE_Y, glow_s)
    key(tiny, OPACITY, [(0, 1), (60, 0.2), (120, 1), (180, 0.2), (240, 1)])
    for i, d in enumerate(dots):
        start = i * 30
        key(d, OPACITY, [(0, 0.35), (start, 0.35), (start + 15, 1),
                         (start + 30, 0.35), (240, 0.35)] if start + 30 <= 240
            else [(0, 0.35), (240, 0.35)])
    return riv


def celebration():
    w, h = 360, 640
    riv = Riv('celebration', w, h)
    rng = random.Random(1447)
    cx, cy = w / 2, h * 0.42
    ring = riv.shape(x=cx, y=cy, opacity=0, scale=0.2)
    riv.ellipse(ring, 160)
    riv.stroke(ring, GOLD, 6)
    burst = riv.shape(x=cx, y=cy, scale=0)
    riv.star(burst, 120, 8, 0.6)
    riv.fill(burst, GOLD)
    core = riv.shape(x=cx, y=cy, scale=0)
    riv.star(core, 70, 8, 0.6)
    riv.fill(core, BRAND)
    colors = [GOLD, BRAND, GOLD_LIGHT, TEAL, ROSE, GOLD, BRAND]
    pieces = []
    for i in range(44):
        p = riv.shape(x=cx, y=cy, opacity=0)
        if i % 5 == 0:
            riv.star(p, 16, 5, 0.45)
        elif i % 3 == 0:
            riv.ellipse(p, 9)
        else:
            riv.rect(p, 8, 14, 2)
        riv.fill(p, colors[i % len(colors)])
        pieces.append(p)

    key = riv.animation('main', 210, 0)
    key(burst, SCALE_X, [(0, 0), (14, 1.25), (24, 1.0), (70, 1.0), (96, 0)])
    key(burst, SCALE_Y, [(0, 0), (14, 1.25), (24, 1.0), (70, 1.0), (96, 0)])
    key(burst, ROTATION, [(0, 0), (96, math.pi / 2)])
    key(core, SCALE_X, [(0, 0), (18, 1.2), (28, 1.0), (70, 1.0), (92, 0)])
    key(core, SCALE_Y, [(0, 0), (18, 1.2), (28, 1.0), (70, 1.0), (92, 0)])
    key(core, ROTATION, [(0, 0), (92, -math.pi / 2)])
    key(ring, SCALE_X, [(0, 0.2), (50, 2.6)])
    key(ring, SCALE_Y, [(0, 0.2), (50, 2.6)])
    key(ring, OPACITY, [(0, 0.9), (50, 0)])
    for p in pieces:
        a = rng.uniform(0, 2 * math.pi)
        speed = rng.uniform(110, 220)
        bx, by = cx + math.cos(a) * speed, cy + math.sin(a) * speed * 0.8 - 40
        t0 = rng.randint(0, 6)
        t1 = t0 + rng.randint(16, 24)
        end = 210
        drift = rng.uniform(-50, 50)
        fall = [(t1 + (end - t1) * i / 5, by + (h + 40 - by) * (i / 5) ** 1.6)
                for i in range(6)]
        key(p, X, [(t0, cx), (t1, bx)] +
            [(round(f), bx + drift * math.sin(i * 1.3)) for i, (f, _) in
             enumerate(fall[1:], 1)])
        key(p, Y, [(t0, cy), (t1, by)] + [(round(f), v) for f, v in fall[1:]])
        spin = rng.choice([-1, 1]) * rng.uniform(4, 10)
        key(p, ROTATION, [(t0, 0), (end, spin)])
        key(p, OPACITY, [(0, 0), (t0, 0, 0), (t0 + 1, 1), (end - 30, 1),
                         (end, 0)])
        flip = rng.uniform(0.25, 1)
        key(p, SCALE_X, [(t0, 1), (t0 + 20, -flip), (t0 + 40, 1),
                         (t0 + 60, -flip), (t0 + 80, 1), (end, -flip)])
    return riv


def empty():
    riv = Riv('empty', 200, 160)
    halo = riv.shape(x=100, y=92, opacity=0.18)
    riv.ellipse(halo, 150, 110)
    riv.fill(halo, GOLD_LIGHT)
    book = riv.node(x=100, y=96)
    left = riv.shape(book)
    riv.polygon(left, [(-2, -26), (-20, -36), (-58, -36), (-62, -32),
                       (-62, 30), (-58, 34), (-20, 34), (-2, 42)])
    riv.fill(left, WHITE)
    riv.stroke(left, BRAND, 3)
    right = riv.shape(book)
    riv.polygon(right, [(2, -26), (20, -36), (58, -36), (62, -32),
                        (62, 30), (58, 34), (20, 34), (2, 42)])
    riv.fill(right, WHITE)
    riv.stroke(right, BRAND, 3)
    for side in (-1, 1):
        for i, y in enumerate((-18, -6, 6, 18)):
            line = riv.shape(book, x=side * (31 + (4 if i == 3 else 0)), y=y)
            riv.rect(line, 34 - (10 if i == 3 else 0), 3, 1.5)
            riv.fill(line, GOLD if i == 0 else 0xFFB9D3CD)
    sparkles = []
    for x, y, s in ((38, 34, 22), (164, 28, 16), (150, 74, 12)):
        sp = riv.shape(x=x, y=y)
        riv.star(sp, s, 4, 0.32)
        riv.fill(sp, GOLD)
        sparkles.append(sp)
    moon = riv.shape(x=100, y=30)
    riv.polygon(moon, crescent(11, 9, 5))
    riv.fill(moon, GOLD)

    key = riv.animation('main', 180, 1)
    bob = eased(0, 90, 0, -6) + eased(90, 180, -6, 0)[1:]
    key(book, Y, [(f, 96 + v) for f, v in bob])
    key(moon, Y, [(f, 30 + v * 0.6) for f, v in bob])
    key(halo, OPACITY, eased(0, 90, 0.12, 0.26) + eased(90, 180, 0.26, 0.12)[1:])
    for i, sp in enumerate(sparkles):
        s = i * 60
        pulse = [(0, 0.3), (s, 0.3), (s + 30, 1.1), (s + 60, 0.3), (180, 0.3)]
        if s + 60 > 180:
            pulse = [(0, 0.3), (180, 0.3)]
        key(sp, SCALE_X, pulse)
        key(sp, SCALE_Y, pulse)
        key(sp, ROTATION, [(0, 0), (180, math.pi / 2)])
    return riv


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    for build in (splash, celebration, empty):
        riv = build()
        path = OUT / f'{build.__name__}.riv'
        path.write_bytes(riv.bytes())
        print(f'{path.name}: {path.stat().st_size} bytes')
