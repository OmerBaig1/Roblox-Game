# Tutorial pointer: traces "Pointer Finger Reference Image/Pointer finger.jpg" into a clean transparent image.
# The JPG has a checkerboard painted in as fake transparency, so: ink = the dark line, inside = anything the ink
# encloses, everything else is dropped. The fingertip ends up on the vertical centre line, so turning the image keeps
# it aimed.  python tutorial_hand.py REFERENCE.jpg OUT.png
import numpy as np, sys
from PIL import Image, ImageDraw, ImageFilter
SIZE, MARGIN, UP = 512, 8, 4
src = Image.open(sys.argv[1]).convert("L")
W, H = src.size
gray = np.asarray(src, np.float32)
# flood the background in from a border one pixel outside the image; the outline stops it
flood = Image.fromarray(((gray > 110) * 255).astype(np.uint8)).copy()
pad = Image.new("L", (W + 2, H + 2), 255)
pad.paste(flood, (1, 1))
ImageDraw.floodfill(pad, (0, 0), 128)
inside = np.asarray(pad)[1:-1, 1:-1] == 255
big = (W * UP, H * UP)
dark = np.asarray(src.resize(big, Image.BICUBIC).filter(ImageFilter.GaussianBlur(UP * .7)), np.float32)
ink = np.clip((125 - dark) / 40 + .5, 0, 1)
ins = np.asarray(Image.fromarray((inside * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5)).resize(big, Image.BICUBIC), np.float32) / 255
alpha = np.maximum(ink, np.clip((ins - .5) * 4 + .5, 0, 1) * (ins > .1))
rgb = 255 * (1 - ink) + 12 * ink
img = Image.fromarray(np.dstack([rgb, rgb, rgb, alpha * 255]).clip(0, 255).astype(np.uint8), "RGBA")
a = np.asarray(img)[..., 3] > 128
ys, xs = np.where(a)
x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
tip_x = (xs[ys <= y0 + 30 * UP].min() + xs[ys <= y0 + 30 * UP].max()) / 2  # the middle of the fingertip
scale = (SIZE - 2 * MARGIN) / max(y1 - y0, 2 * max(tip_x - x0, x1 - tip_x))
hand = img.crop((x0, y0, x1 + 1, y1 + 1))
hand = hand.resize((round(hand.width * scale), round(hand.height * scale)), Image.LANCZOS)
out = Image.new("RGBA", (SIZE, SIZE), (12, 12, 12, 0))
px, py = round(SIZE / 2 - (tip_x - x0) * scale), (SIZE - hand.height) // 2
out.alpha_composite(hand, (px, py))
out.save(sys.argv[2])
A = np.asarray(out)[..., 3] > 128
yy, xx = np.where(A)
print("bbox", xx.min(), yy.min(), xx.max(), yy.max(), "HAND_TIP", (SIZE / 2 - yy.min()) / SIZE, "tip centre x", xx[yy <= yy.min() + 6].mean())
