"""
Original UI art for Steal a Game: Shop items, HUD pieces, the Slow Down tortoise. Everything is drawn here from shapes
(no source images), in one style: a thick dark ink line, a two-colour fill lit from the top left, a cel shadow and a
gloss highlight.

    python ui_art.py OUTPUT_FOLDER [name ...]
"""
import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

SS = 2


class Canvas:
    def __init__(self, w=512, h=512):
        self.W, self.H = w * SS, h * SS
        yy, xx = np.mgrid[0:self.H, 0:self.W].astype(np.float32)
        self.x, self.y = (xx + .5) / SS, (yy + .5) / SS
        self.rgb = np.zeros((self.H, self.W, 3), np.float32)
        self.a = np.zeros((self.H, self.W), np.float32)
        self.w, self.h = w, h

    # distance fields
    def circ(self, cx, cy, r):
        return np.hypot(self.x - cx, self.y - cy) - r

    def ell(self, cx, cy, rx, ry, rot=0):
        c, s = np.cos(np.radians(rot)), np.sin(np.radians(rot))
        dx, dy = self.x - cx, self.y - cy
        u, v = (dx * c + dy * s) / rx, (-dx * s + dy * c) / ry
        return (np.hypot(u, v) - 1) * min(rx, ry)

    def box(self, cx, cy, w, h, r=0, rot=0):
        c, s = np.cos(np.radians(rot)), np.sin(np.radians(rot))
        dx, dy = self.x - cx, self.y - cy
        u, v = np.abs(dx * c + dy * s) - (w / 2 - r), np.abs(-dx * s + dy * c) - (h / 2 - r)
        return np.hypot(np.maximum(u, 0), np.maximum(v, 0)) + np.minimum(np.maximum(u, v), 0) - r

    def line(self, x0, y0, x1, y1, r0, r1=None):
        r1 = r0 if r1 is None else r1
        bx, by = x1 - x0, y1 - y0
        t = np.clip(((self.x - x0) * bx + (self.y - y0) * by) / max(bx * bx + by * by, 1e-6), 0, 1)
        return np.hypot(self.x - x0 - bx * t, self.y - y0 - by * t) - (r0 + (r1 - r0) * t)

    def poly(self, pts, round=0):
        pts = np.array(pts, np.float32)
        d = np.full(self.x.shape, 1e9, np.float32)
        inside = np.zeros(self.x.shape, bool)
        for i in range(len(pts)):
            a, b = pts[i], pts[i - 1]
            ex, ey = b[0] - a[0], b[1] - a[1]
            wx, wy = self.x - a[0], self.y - a[1]
            t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
            d = np.minimum(d, (wx - ex * t) ** 2 + (wy - ey * t) ** 2)
            c1, c2, c3 = self.y >= a[1], self.y < b[1], ex * wy > ey * wx
            flip = (c1 & c2 & c3) | (~c1 & ~c2 & ~c3)
            inside ^= flip
        return np.sqrt(d) * np.where(inside, -1, 1) - round

    @staticmethod
    def union(*ds):
        return np.minimum.reduce(ds)

    @staticmethod
    def smooth(a, b, k):
        h = np.clip(.5 + .5 * (b - a) / k, 0, 1)
        return b * (1 - h) + a * h - k * h * (1 - h)

    @staticmethod
    def cut(a, b):
        return np.maximum(a, -b)

    @staticmethod
    def clip(a, b):
        return np.maximum(a, b)

    # painting
    def _cov(self, d):
        return np.clip(.5 - d * SS / 1.5, 0, 1)

    def _over(self, col, cov):
        c = cov[..., None]
        self.rgb[:] = self.rgb * (1 - c) + col * c
        self.a[:] = self.a + (1 - self.a) * cov

    def paint(self, d, top, low=None, ink=7, shade=.34, light=(8, 12), angle=(.35, 1), gloss=None):
        """an inked shape: outline, gradient fill, cel shadow. gloss = a distance field for its highlight"""
        top = np.array(top, np.float32)
        low = top * .72 if low is None else np.array(low, np.float32)
        if ink:
            self._over(np.array(INK, np.float32), self._cov(d - ink))
        inside = d < 0
        if inside.any():
            ax, ay = angle
            p = self.x * ax + self.y * ay
            lo, hi = p[inside].min(), p[inside].max()
            t = np.clip((p - lo) / max(hi - lo, 1), 0, 1)[..., None]
            col = top * (1 - t) + low * t
            if shade:
                px, py = int(light[0] * SS), int(light[1] * SS)
                lit = np.roll(np.roll(d, -py, 0), -px, 1)
                s = np.clip(.5 + lit / 2, 0, 1)[..., None]
                col = col * (1 - s * shade) + (col * .55 + np.array([10, 4, 40], np.float32) * .1) * s * shade
            if gloss is not None:
                g = self._cov(gloss)[..., None] * .82
                col = col * (1 - g) + 255 * g
            self._over(col, self._cov(d))

    def flat(self, d, color, alpha=1.0):
        self._over(np.array(color, np.float32), self._cov(d) * alpha)

    def text(self, s, cx, cy, size, color, font="arialbd.ttf", ink=0, rot=0):
        f = ImageFont.truetype("C:/Windows/Fonts/" + font, int(size * SS))
        im = Image.new("L", (self.W, self.H), 0)
        dr = ImageDraw.Draw(im)
        dr.text((cx * SS, cy * SS), s, fill=255, font=f, anchor="mm", stroke_width=int(ink * SS))
        if ink:
            if rot:
                im = im.rotate(rot, Image.BICUBIC, center=(cx * SS, cy * SS))
            self._over(np.array(INK, np.float32), np.asarray(im, np.float32) / 255)
            im = Image.new("L", (self.W, self.H), 0)
            ImageDraw.Draw(im).text((cx * SS, cy * SS), s, fill=255, font=f, anchor="mm")
        if rot:
            im = im.rotate(rot, Image.BICUBIC, center=(cx * SS, cy * SS))
        self._over(np.array(color, np.float32), np.asarray(im, np.float32) / 255)

    def sparkle(self, cx, cy, r, color=(255, 255, 255), ink=4):
        k = r * .17
        pts = [(cx, cy - r), (cx + k, cy - k), (cx + r, cy), (cx + k, cy + k), (cx, cy + r), (cx - k, cy + k), (cx - r, cy), (cx - k, cy - k)]
        self.paint(self.poly(pts), color, color, ink=ink, shade=0)

    def save(self, path):
        a = self.a
        rgb = self.rgb
        out = np.dstack([rgb, a[..., None] * 255]).clip(0, 255).astype(np.uint8)
        Image.fromarray(out, "RGBA").resize((self.w, self.h), Image.LANCZOS).save(path)


INK = (22, 14, 40)
GOLD = ((255, 232, 110), (240, 150, 20))
GREEN = ((130, 240, 130), (24, 150, 70))
BLUE = ((130, 215, 255), (30, 110, 235))
PINK = ((255, 150, 210), (225, 50, 140))
PURPLE = ((205, 160, 255), (110, 60, 225))
RED = ((255, 130, 110), (225, 40, 60))
STEEL = ((225, 232, 245), (120, 134, 165))
DARK = ((90, 84, 130), (40, 34, 70))
WHITE = (255, 255, 255)


# ------------------------------------------------------------------ PARTS
def coin(c, x, y, r, tilt=0):
    d = c.ell(x, y, r, r * (1 - tilt))
    if tilt:
        c.paint(c.ell(x, y + r * .12, r, r * (1 - tilt)), (205, 120, 10), (150, 80, 10), shade=0)
    c.paint(d, *GOLD, gloss=c.ell(x - r * .36, y - r * (1 - tilt) * .48, r * .22, r * .11, -35))
    c.flat(c.cut(c.ell(x, y, r * .76, r * .76 * (1 - tilt)), c.ell(x, y, r * .64, r * .64 * (1 - tilt))), (190, 110, 10), .8)
    c.text("$", x, y, r * 1.0 * (1 - tilt * .5), (165, 90, 5))


def bill(c, x, y, w, h, rot=0):
    c.paint(c.box(x, y, w, h, h * .08, rot), *GREEN)
    a = np.radians(rot)
    c.flat(c.cut(c.box(x, y, w * .86, h * .74, h * .06, rot), c.box(x, y, w * .8, h * .62, h * .04, rot)), (20, 110, 60), .75)
    c.flat(c.ell(x, y, h * .25, h * .25), (225, 255, 215))
    c.text("$", x, y, h * .4, (20, 120, 60), rot=-rot)


def stack(c, x, y, w, h, n):
    # a banded brick of notes, seen a little from above
    for i in range(n):
        yy = y - i * h * .34
        c.paint(c.box(x, yy, w, h, h * .22), *GREEN, ink=6, shade=.2)
    top = y - (n - 1) * h * .34
    c.flat(c.ell(x, top, h * .3, h * .3), (225, 255, 215))
    c.text("$", x, top, h * .46, (20, 120, 60))
    c.paint(c.box(x, y - (n - 1) * h * .17, w * .15, (n - 1) * h * .34 + h, 3), (255, 240, 170), (235, 170, 60), ink=4, shade=0)


def game_case(c, x, y, w, h, rot=0, plastic=BLUE, art=None):
    """the game's own boxed release: a coloured case, a console band and a little cover picture"""
    r = np.radians(rot)
    def at(u, v):
        return x + u * np.cos(r) - v * np.sin(r), y + u * np.sin(r) + v * np.cos(r)
    c.paint(c.box(x, y, w, h, w * .07, rot), *plastic)
    bx, by = at(0, -h * .375)
    c.flat(c.box(bx, by, w * .84, h * .13, w * .03, rot), (255, 255, 255), .92)
    ax, ay = at(0, h * .08)
    sky = c.box(ax, ay, w * .84, h * .72, w * .04, rot)
    c.paint(sky, (255, 214, 120), (255, 90, 140), ink=0, shade=0, angle=(0, 1))
    sx, sy = at(w * .12, -h * .06)
    c.flat(c.clip(c.circ(sx, sy, w * .2), sky), (255, 248, 190))
    pts = [at(-w * .42, h * .44), at(-w * .15, h * .02), at(w * .04, h * .24), at(w * .18, h * .1), at(w * .42, h * .44)]
    c.flat(c.clip(c.poly(pts), sky), (70, 40, 130))
    gx, gy = at(-w * .24, -h * .375)
    c.flat(c.circ(gx, gy, h * .035), plastic[1])


def bolt(c, x, y, s, rot=0, col=GOLD, ink=7):
    r = np.radians(rot)
    raw = [(.12, -1), (-.55, .16), (-.08, .16), (-.2, 1), (.56, -.26), (.06, -.26), (.42, -1)]
    pts = [(x + (u * np.cos(r) - v * np.sin(r)) * s, y + (u * np.sin(r) + v * np.cos(r)) * s) for u, v in raw]
    c.paint(c.poly(pts, 2), *col, ink=ink, gloss=c.line(x - .1 * s, y - .62 * s, x + .1 * s, y - .86 * s, s * .03))


def sneaker(c, x, y, s, col=RED, wing=False, flame=False):
    P = lambda u, v: (x + u * s, y + v * s)
    if flame:
        for dy, l, cc in ((-.1, .44, GOLD), (.22, .32, RED)):
            c.paint(c.poly([P(-.8, dy - .2), P(-.8 - l, dy), P(-.8, dy + .2)], 8), *cc, ink=5, shade=0)
    if wing:
        wd = c.union(c.ell(x - .62 * s, y - .5 * s, .46 * s, .17 * s, 28), c.ell(x - .72 * s, y - .28 * s, .42 * s, .14 * s, 14), c.ell(x - .74 * s, y - .07 * s, .34 * s, .11 * s, 2))
        c.paint(wd, WHITE, (190, 225, 255), ink=6)
    upper = c.smooth(c.poly([P(-.7, .3), P(-.72, -.42), P(-.28, -.5), P(-.08, -.12), P(.36, .0), P(.84, .14), P(.88, .36)], 6), c.ell(x + .55 * s, y + .17 * s, .36 * s, .22 * s), 10)
    c.paint(upper, *col, gloss=c.ell(x - .46 * s, y - .28 * s, .08 * s, .04 * s, 0))
    # toe cap and heel
    c.flat(c.clip(c.ell(x + .72 * s, y + .22 * s, .3 * s, .3 * s), upper), (255, 255, 255), .92)
    c.flat(c.clip(c.box(x - .66 * s, y - .06 * s, .24 * s, .9 * s), upper), (255, 255, 255), .6)
    for i in range(3):
        u = -.14 + i * .17
        c.line(0, 0, 0, 0, 0)
        c.flat(c.line(x + u * s, y - .11 * s + i * .03 * s, x + (u + .16) * s, y + .02 * s + i * .03 * s, .027 * s), (255, 255, 255))
    sole = c.box(x + .08 * s, y + .43 * s, 1.68 * s, .24 * s, .1 * s)
    c.paint(sole, WHITE, (185, 195, 225), ink=6, shade=.1)
    for i in range(5):
        c.flat(c.box(x + (-.56 + i * .3) * s, y + .49 * s, .12 * s, .05 * s), (120, 130, 165))


def speed_lines(c, x, y, n, length, gap, col=(255, 255, 255)):
    for i in range(n):
        ll = length * (1 - .25 * ((i * 7) % 3))
        c.paint(c.line(x, y + i * gap, x - ll, y + i * gap, 7, 1.5), col, col, ink=4, shade=0)


# ------------------------------------------------------------------ SHOP ITEMS
def item_starter(c):
    # an open box of goodies: a game, a coin and a bolt bursting out of it
    for i in range(10):
        a = np.pi + (i + .5) / 10 * np.pi
        c.flat(c.poly([(256, 250), (256 + np.cos(a - .1) * 250, 250 + np.sin(a - .1) * 250), (256 + np.cos(a + .1) * 250, 250 + np.sin(a + .1) * 250)]), (255, 245, 170), .34)
    game_case(c, 256, 170, 150, 196, -6, BLUE)
    coin(c, 120, 222, 62)
    bolt(c, 392, 202, 74, 10)
    c.paint(c.poly([(82, 270), (430, 270), (408, 472), (104, 472)], 10), *PINK)
    c.paint(c.box(256, 268, 408, 62, 14), (255, 190, 225), (240, 90, 170))
    c.paint(c.box(256, 372, 70, 196, 3), *GOLD, ink=6, shade=.2)
    c.paint(c.box(256, 268, 88, 74, 12), *GOLD, ink=6)
    c.sparkle(70, 120, 36)
    c.sparkle(450, 90, 28)


def item_money2(c):
    coin(c, 196, 226, 148, 0)
    coin(c, 322, 300, 148, 0)
    c.sparkle(422, 100, 40)
    c.sparkle(70, 410, 28)


def item_speed2(c):
    sneaker(c, 256, 176, 176, BLUE, wing=True)
    sneaker(c, 272, 352, 176, RED, wing=True)
    c.sparkle(450, 76, 30)


def item_steal2(c):
    # two games carried off in a hurry
    speed_lines(c, 110, 170, 4, 90, 58)
    game_case(c, 214, 234, 200, 276, -13, RED)
    game_case(c, 312, 262, 200, 276, 9, PURPLE)
    c.sparkle(444, 88, 36)
    c.sparkle(90, 72, 24)


def item_treadmill(c):
    c.paint(c.poly([(112, 110), (150, 92), (214, 300), (176, 318)], 5), *STEEL)
    c.paint(c.box(162, 88, 150, 62, 18, -8), *DARK)
    c.flat(c.box(162, 86, 110, 28, 7, -8), (80, 255, 190))
    c.paint(c.poly([(60, 340), (368, 248), (472, 330), (168, 438)], 12), *DARK)
    c.paint(c.poly([(100, 340), (362, 264), (430, 322), (172, 414)], 6), (70, 70, 110), (28, 26, 54), ink=4, shade=0)
    for i in range(4):
        t = .17 + i * .22
        a, b = (100 + 72 * t, 340 + 74 * t), (362 + 68 * t, 264 + 58 * t)
        c.flat(c.line(a[0], a[1], b[0], b[1], 3.5), (120, 255, 200), .85)
    bolt(c, 384, 150, 92, 12)
    speed_lines(c, 300, 90, 3, 70, 44)


def item_spin(c):
    x, y, r = 256, 268, 192
    c.paint(c.circ(x, y, r), *GOLD)
    cols = [(255, 90, 110), (255, 200, 70), (90, 215, 130), (80, 170, 255), (190, 110, 255), (255, 130, 200)]
    a0 = -np.pi / 2
    n = 12
    wheel = c.circ(x, y, r - 22)
    for i in range(n):
        a, b = a0 + i / n * 2 * np.pi, a0 + (i + 1) / n * 2 * np.pi
        wedge = c.poly([(x, y), (x + np.cos(a) * r * 1.3, y + np.sin(a) * r * 1.3), (x + np.cos(b) * r * 1.3, y + np.sin(b) * r * 1.3)])
        c.flat(c.clip(wedge, wheel), cols[i % 6])
    for i in range(n):
        a = a0 + i / n * 2 * np.pi
        c.flat(c.clip(c.line(x, y, x + np.cos(a) * r, y + np.sin(a) * r, 3), wheel), INK)
        c.paint(c.circ(x + np.cos(a) * (r - 10), y + np.sin(a) * (r - 10), 10), WHITE, (225, 225, 240), ink=4, shade=0)
    c.paint(c.circ(x, y, 56), *GOLD)
    c.text("?", x, y, 72, (150, 80, 10))
    c.paint(c.poly([(218, 34), (294, 34), (256, 128)], 8), *RED)
    c.sparkle(70, 90, 32)


def item_speedS(c):
    # a Speed Snack: an energy drink can
    c.paint(c.box(256, 270, 196, 356, 30), (120, 230, 255), (40, 110, 240))
    c.paint(c.ell(256, 92, 98, 28), *STEEL, ink=7, shade=0)
    c.paint(c.ell(256, 92, 58, 14), (150, 160, 190), (90, 100, 130), ink=4, shade=0)
    c.paint(c.box(256, 440, 174, 30, 14), *STEEL, ink=6, shade=0)
    c.flat(c.box(204, 276, 36, 290, 16), (255, 255, 255), .22)
    bolt(c, 256, 278, 112, 8)
    c.sparkle(420, 150, 36)
    c.sparkle(90, 380, 24)


def item_speedM(c):
    speed_lines(c, 120, 280, 3, 90, 60)
    sneaker(c, 276, 268, 214, BLUE, wing=True)
    c.sparkle(450, 120, 34)


def item_speedL(c):
    bolt(c, 402, 118, 84, 14)
    bolt(c, 118, 128, 62, -14, BLUE, 6)
    sneaker(c, 282, 300, 214, PURPLE, wing=True, flame=True)


def item_speedXL(c):
    # a Speed Storm: a twister with lightning in it
    rows = [(256, 74, 210, 34), (262, 132, 176, 32), (250, 188, 136, 30), (266, 242, 104, 28), (250, 296, 74, 25), (262, 346, 48, 21), (252, 392, 28, 17), (258, 428, 12, 12)]
    for x, y, rx, ry in reversed(rows):
        c.paint(c.ell(x, y, rx, ry), (215, 230, 255), (90, 110, 225), ink=6, shade=.28)
    bolt(c, 402, 276, 86, 14)
    bolt(c, 104, 232, 70, -10)
    c.sparkle(70, 80, 26)


def item_speedXXL(c):
    # a Speed Supernova: a blazing star with a sneaker riding out of it
    x, y = 256, 240
    pts = []
    for i in range(24):
        a = i / 24 * 2 * np.pi
        r = 226 if i % 2 == 0 else 118
        pts.append((x + np.cos(a) * r, y + np.sin(a) * r))
    c.paint(c.poly(pts, 4), (255, 180, 255), (150, 60, 235), ink=7, shade=0)
    pts2 = []
    for i in range(16):
        a = (i + .5) / 16 * 2 * np.pi
        r = 150 if i % 2 == 0 else 84
        pts2.append((x + np.cos(a) * r, y + np.sin(a) * r))
    c.paint(c.poly(pts2, 3), *GOLD, ink=6, shade=0)
    c.flat(c.circ(x, y, 56), (255, 255, 235))
    sneaker(c, 266, 344, 170, BLUE, wing=True, flame=True)


def item_cash5(c):
    bill(c, 200, 318, 268, 140, -16)
    bill(c, 310, 342, 268, 140, 10)
    coin(c, 166, 176, 78)
    coin(c, 306, 148, 92)
    c.sparkle(444, 110, 32)


def item_cashS(c):
    stack(c, 170, 392, 228, 96, 5)
    stack(c, 346, 410, 228, 96, 4)
    stack(c, 262, 230, 228, 96, 4)
    coin(c, 430, 174, 54)
    c.sparkle(80, 96, 32)


def item_cashL(c):
    # a Cash Vault: a heavy round door hanging open on gold
    c.paint(c.box(256, 256, 420, 420, 46), *STEEL)
    c.paint(c.box(256, 256, 346, 346, 30), (50, 42, 84), (20, 14, 40), ink=6, shade=0)
    for u, v in ((-44, 62), (52, 72), (6, 16), (-92, 104), (102, 112)):
        coin(c, 240 + u, 318 + v, 44)
    c.paint(c.circ(196, 196, 134), *STEEL)
    c.paint(c.circ(196, 196, 96), (170, 180, 205), (98, 108, 140), ink=6, shade=.2)
    for a in range(0, 180, 60):
        r = np.radians(a)
        c.paint(c.line(196 - np.cos(r) * 72, 196 - np.sin(r) * 72, 196 + np.cos(r) * 72, 196 + np.sin(r) * 72, 10), *GOLD, ink=4, shade=0)
    c.paint(c.circ(196, 196, 26), *GOLD, ink=5)
    c.sparkle(432, 90, 34)


def item_cashXL(c):
    # a Cash Mountain: a heap of coins and notes with a flag on top
    c.paint(c.line(256, 118, 256, 34, 6), *STEEL, ink=5, shade=0)
    c.paint(c.poly([(262, 30), (344, 54), (262, 84)], 4), *RED, ink=5, shade=0)
    c.paint(c.poly([(40, 462), (256, 96), (472, 462)], 18), (255, 214, 90), (210, 120, 20))
    bill(c, 356, 396, 170, 88, 18)
    bill(c, 140, 410, 170, 88, -14)
    for x, y, r in ((256, 168, 44), (204, 248, 48), (312, 254, 50), (256, 328, 58), (152, 348, 52), (364, 332, 50), (96, 428, 44), (256, 430, 52), (420, 430, 44)):
        coin(c, x, y, r)
    c.sparkle(90, 120, 34)
    c.sparkle(440, 170, 26)


def item_cashXXL(c):
    # a Cash Planet: a world of gold wearing a ring of coins, and a crown
    x, y = 256, 276
    # the back of the ring
    for i in range(9):
        a = np.pi + (i + .5) / 9 * np.pi
        coin(c, x + np.cos(a) * 230, y + np.sin(a) * 66 - 8, 25, .3)
    c.paint(c.circ(x, y, 162), *GOLD, gloss=c.ell(x - 72, y - 92, 42, 20, -35))
    land = c.union(c.ell(x - 40, y - 34, 76, 40, -18), c.ell(x + 76, y + 40, 60, 32, 20), c.ell(x - 62, y + 86, 58, 26, 8))
    c.flat(c.clip(land, c.circ(x, y, 156)), (205, 120, 15), .75)
    c.text("$", x, y, 170, (255, 248, 190), ink=5)
    # the front of the ring
    for i in range(9):
        a = (i + .5) / 9 * np.pi
        coin(c, x + np.cos(a) * 230, y + np.sin(a) * 66 + 8, 30, .3)
    pts = [(176, 118), (156, 36), (214, 78), (256, 18), (298, 78), (356, 36), (336, 118)]
    c.paint(c.poly(pts, 6), *GOLD)
    for px, py, cc in ((156, 36, RED), (256, 18, BLUE), (356, 36, RED)):
        c.paint(c.circ(px, py, 14), *cc, ink=5)
    c.sparkle(70, 90, 30)


# ------------------------------------------------------------------ HUD
def hud_shop(c):
    # a shopping bag in the game's pink and gold, with a star on it
    c.paint(c.cut(c.ell(256, 150, 94, 112), c.ell(256, 150, 62, 84)), *GOLD, ink=8)
    c.paint(c.poly([(92, 164), (420, 164), (458, 466), (54, 466)], 22), *PINK, ink=10, gloss=c.ell(148, 214, 22, 34, 10))
    c.paint(c.box(256, 172, 354, 30, 10), (255, 200, 235), (250, 130, 195), ink=6, shade=0)
    for cx in (156, 356):
        c.paint(c.circ(cx, 212, 18), *GOLD, ink=6, shade=0)
    x, y = 256, 334
    pts = []
    for i in range(10):
        a = -np.pi / 2 + i / 10 * 2 * np.pi
        r = 94 if i % 2 == 0 else 42
        pts.append((x + np.cos(a) * r, y + np.sin(a) * r))
    c.paint(c.poly(pts, 6), *GOLD, ink=8, gloss=c.ell(236, 300, 12, 6, -30))
    c.sparkle(450, 92, 40)


def hud_index(c):
    # an open collection book, a game case on the page
    c.paint(c.poly([(30, 124), (256, 86), (482, 124), (482, 446), (256, 482), (30, 446)], 14), *((255, 214, 90), (205, 120, 20)), ink=10)
    c.paint(c.poly([(62, 118), (250, 82), (250, 436), (62, 414)], 8), (255, 255, 245), (225, 215, 195), ink=7, shade=.12)
    c.paint(c.poly([(262, 82), (450, 118), (450, 414), (262, 436)], 8), (255, 255, 245), (225, 215, 195), ink=7, shade=.12)
    game_case(c, 156, 256, 124, 172, -4, BLUE)
    for i in range(4):
        y = 170 + i * 48
        c.flat(c.line(304, y, 412, y + 8, 6), (180, 165, 150), .9)
    c.paint(c.line(256, 88, 256, 452, 7), (205, 120, 20), (150, 80, 10), ink=4, shade=0)
    c.paint(c.poly([(390, 60), (440, 60), (440, 190), (415, 164), (390, 190)], 3), *RED, ink=6, shade=0)
    c.sparkle(62, 62, 36)


def hud_plus(c):
    # one shape: the union of the two bars is outlined once, so nothing overlaps
    s = 128
    x = c.w / 2
    d = c.union(c.box(x, x, s * .62, s * .2, s * .07), c.box(x, x, s * .2, s * .62, s * .07))
    c.paint(d, WHITE, (255, 240, 200), ink=s * .05, shade=0)


def hud_fuse(c):
    # three game cases feeding one glowing core
    for i in range(12):
        a = (i + .5) / 12 * 2 * np.pi
        c.flat(c.poly([(256, 256), (256 + np.cos(a - .09) * 245, 256 + np.sin(a - .09) * 245), (256 + np.cos(a + .09) * 245, 256 + np.sin(a + .09) * 245)]), (120, 240, 255), .3)
    game_case(c, 96, 150, 108, 146, -14, RED)
    game_case(c, 416, 150, 108, 146, 14, BLUE)
    game_case(c, 256, 408, 108, 146, 0, GREEN)
    x, y = 256, 216
    c.paint(c.circ(x, y, 110), (150, 245, 255), (40, 120, 235), gloss=c.ell(x - 42, y - 56, 28, 13, -32))
    c.flat(c.circ(x, y, 58), (235, 255, 255), .92)
    bolt(c, x, y, 60, 8)
    c.sparkle(450, 330, 30)
    c.sparkle(60, 330, 24)


def item_mystery(c):
    # a mystery game: a shadowy case with a big question mark, glowing at the edges
    for i in range(12):
        a = (i + .5) / 12 * 2 * np.pi
        c.flat(c.poly([(256, 256), (256 + np.cos(a - .1) * 250, 256 + np.sin(a - .1) * 250), (256 + np.cos(a + .1) * 250, 256 + np.sin(a + .1) * 250)]), (255, 225, 130), .32)
    c.paint(c.box(256, 256, 286, 392, 26, -6), *PURPLE)
    c.paint(c.box(256, 264, 228, 300, 18, -6), (70, 40, 130), (30, 14, 70), ink=5, shade=0)
    c.text("?", 256, 268, 250, (255, 214, 90), font="arialbd.ttf", ink=7, rot=6)
    c.sparkle(70, 90, 36)
    c.sparkle(444, 410, 30)


def tortoise_body(c):
    # side on, facing right. The head is its own image so it can move
    SH = ((150, 225, 110), (46, 140, 70))
    SK = ((235, 215, 130), (190, 150, 80))
    # tail
    c.paint(c.poly([(70, 322), (22, 360), (84, 362)], 6), *SK, ink=8, shade=0)
    # far legs
    c.paint(c.box(176, 378, 64, 90, 26), (205, 180, 105), (160, 125, 70), ink=8, shade=0)
    c.paint(c.box(344, 378, 64, 90, 26), (205, 180, 105), (160, 125, 70), ink=8, shade=0)
    # belly
    c.paint(c.box(236, 352, 340, 70, 32), (255, 235, 165), (215, 180, 100), ink=8, shade=.2)
    # near legs, chunky, with toes
    for cx in (128, 300):
        c.paint(c.box(cx, 396, 84, 92, 34), *SK, ink=9)
        for t in (-22, 0, 22):
            c.flat(c.ell(cx + t, 432, 8, 7), (255, 250, 225))
    # the shell: a big dome with scutes and a rim
    dome = c.clip(c.ell(236, 324, 196, 200), c.box(236, 220, 460, 214))
    dome = c.smooth(dome, c.box(236, 322, 400, 24, 12), 14)
    c.paint(dome, *SH, ink=10, gloss=c.ell(150, 182, 46, 18, -32))
    scute = lambda pts: c.paint(c.poly(pts, 6), (190, 240, 120), (70, 170, 80), ink=6, shade=.15)
    scute([(186, 190), (236, 162), (286, 190), (280, 252), (192, 252)])
    scute([(84, 244), (132, 186), (168, 200), (172, 256), (112, 290)])
    scute([(304, 200), (340, 186), (388, 244), (360, 290), (300, 256)])
    scute([(180, 276), (292, 276), (308, 300), (166, 300)])
    # the rim of the shell
    c.paint(c.box(236, 322, 410, 34, 16), (255, 225, 120), (205, 145, 50), ink=8, shade=.2)


def tortoise_head(c):
    # neck comes in from the lower left of the image (the rotation pivot); it looks right
    SK = ((245, 225, 140), (195, 155, 85))
    c.paint(c.line(70, 196, 160, 138, 54, 48), *SK, ink=10, shade=.2)
    head = c.smooth(c.ell(170, 104, 76, 68), c.ell(214, 124, 44, 34), 22)
    c.paint(head, *SK, ink=10, gloss=c.ell(136, 66, 20, 9, -25))
    # eye, with a big shine
    c.paint(c.circ(186, 84, 26), WHITE, WHITE, ink=7, shade=0)
    c.flat(c.circ(194, 86, 16), INK)
    c.flat(c.circ(200, 79, 6), WHITE)
    # the smile and a nostril
    c.flat(c.cut(c.ell(196, 128, 38, 20), c.ell(196, 118, 42, 20)), INK)
    c.flat(c.circ(238, 110, 4.5), INK)
    # a cheek
    c.flat(c.ell(146, 122, 15, 10), (255, 160, 150), .7)


ALL = {
    "starter": item_starter, "money2": item_money2, "speed2": item_speed2, "steal2": item_steal2, "treadmill": item_treadmill, "spin": item_spin,
    "speedS": item_speedS, "speedM": item_speedM, "speedL": item_speedL, "speedXL": item_speedXL, "speedXXL": item_speedXXL,
    "cash5": item_cash5, "cashS": item_cashS, "cashL": item_cashL, "cashXL": item_cashXL, "cashXXL": item_cashXXL,
    "hud_shop": hud_shop, "hud_index": hud_index, "hud_fuse": hud_fuse, "mystery": item_mystery,
    "hud_plus": (hud_plus, 128, 128),
    "tortoise_body": tortoise_body, "tortoise_head": (tortoise_head, 288, 288),
}

if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name in (sys.argv[2:] or ALL):
        fn = ALL[name]
        w, h = (512, 512)
        if isinstance(fn, tuple):
            fn, w, h = fn
        c = Canvas(w, h)
        fn(c)
        c.save(os.path.join(out, name + ".png"))
        print(name, end=" ", flush=True)
    print()
