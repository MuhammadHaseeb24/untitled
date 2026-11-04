"""Draws the Ember Legion logo and launcher icons (original artwork).
Run:  python3 tools/make_logo.py   (needs Pillow)"""
from PIL import Image, ImageDraw, ImageFilter
import math

SS = 4  # supersampling
W = 1024 * SS


def logo_layer():
    im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = W // 2, W // 2
    s = W

    # yellow disc with outline
    r = int(0.47 * s)
    d.ellipse([cx - r - 14 * SS, cy - r - 14 * SS, cx + r + 14 * SS, cy + r + 14 * SS], fill=(20, 12, 8, 255))
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(247, 196, 0, 255))

    # crossed spears behind the helmet
    def spear(angle_deg, color=(120, 80, 40, 255)):
        a = math.radians(angle_deg)
        dx, dy = math.cos(a), math.sin(a)
        length = 0.78 * s
        x0, y0 = cx - dx * length / 2, cy - dy * length / 2
        x1, y1 = cx + dx * length / 2, cy + dy * length / 2
        d.line([(x0, y0), (x1, y1)], fill=(20, 12, 8, 255), width=int(0.055 * s))
        d.line([(x0, y0), (x1, y1)], fill=color, width=int(0.036 * s))
        nx, ny = -dy, dx
        tip = [(x1 + dx * 0.10 * s, y1 + dy * 0.10 * s), (x1 + nx * 0.04 * s, y1 + ny * 0.04 * s), (x1 - nx * 0.04 * s, y1 - ny * 0.04 * s)]
        d.polygon(tip, fill=(226, 232, 242, 255), outline=(20, 12, 8, 255), width=10 * SS)

    spear(-40)
    spear(-140)

    # red crest
    crest = [(0.33, 0.34), (0.27, 0.19), (0.37, 0.24), (0.41, 0.07), (0.50, 0.21), (0.59, 0.07), (0.63, 0.24), (0.73, 0.19), (0.67, 0.34)]
    pts = [(x * s, y * s) for x, y in crest]
    d.polygon(pts, fill=(232, 84, 42, 255), outline=(20, 12, 8, 255), width=16 * SS)
    d.polygon([(0.45 * s, 0.25 * s), (0.50 * s, 0.13 * s), (0.55 * s, 0.25 * s)], fill=(255, 150, 90, 255))

    # helmet dome + cheek guards
    dome = [cx - 0.27 * s, 0.24 * s, cx + 0.27 * s, 0.70 * s]
    d.ellipse([dome[0] - 14 * SS, dome[1] - 14 * SS, dome[2] + 14 * SS, dome[3] + 14 * SS], fill=(20, 12, 8, 255))
    d.ellipse(dome, fill=(205, 210, 220, 255))
    cheeks = [(0.25, 0.52), (0.75, 0.52), (0.69, 0.80), (0.58, 0.88), (0.50, 0.84), (0.42, 0.88), (0.31, 0.80)]
    cpts = [(x * s, y * s) for x, y in cheeks]
    d.polygon(cpts, fill=(205, 210, 220, 255), outline=(20, 12, 8, 255), width=16 * SS)
    # shading on the right side
    d.polygon([(0.66 * s, 0.38 * s), (0.75 * s, 0.52 * s), (0.69 * s, 0.80 * s), (0.62 * s, 0.82 * s)], fill=(150, 156, 170, 255))
    # face opening (T shape)
    face = [(0.38, 0.42), (0.62, 0.42), (0.60, 0.52), (0.55, 0.53), (0.55, 0.76), (0.45, 0.76), (0.45, 0.53), (0.40, 0.52)]
    fpts = [(x * s, y * s) for x, y in face]
    d.polygon(fpts, fill=(18, 10, 12, 255))
    # angry eyes
    d.polygon([(0.395 * s, 0.455 * s), (0.485 * s, 0.475 * s), (0.485 * s, 0.505 * s), (0.405 * s, 0.50 * s)], fill=(255, 255, 255, 255))
    d.polygon([(0.605 * s, 0.455 * s), (0.515 * s, 0.475 * s), (0.515 * s, 0.505 * s), (0.595 * s, 0.50 * s)], fill=(255, 255, 255, 255))
    d.ellipse([0.44 * s, 0.472 * s, 0.47 * s, 0.502 * s], fill=(10, 10, 14, 255))
    d.ellipse([0.53 * s, 0.472 * s, 0.56 * s, 0.502 * s], fill=(10, 10, 14, 255))
    # mouth
    d.polygon([(0.46 * s, 0.62 * s), (0.54 * s, 0.62 * s), (0.52 * s, 0.68 * s), (0.48 * s, 0.68 * s)], fill=(190, 60, 60, 255))
    # highlights
    d.polygon([(0.35 * s, 0.36 * s), (0.41 * s, 0.30 * s), (0.43 * s, 0.34 * s), (0.38 * s, 0.42 * s)], fill=(255, 255, 255, 200))
    # ember sparks
    for (x, y, r2) in [(0.15, 0.30, 0.012), (0.86, 0.26, 0.015), (0.10, 0.70, 0.010), (0.90, 0.66, 0.012), (0.22, 0.14, 0.009)]:
        d.ellipse([x * s - r2 * s, y * s - r2 * s, x * s + r2 * s, y * s + r2 * s], fill=(255, 140, 40, 255))
    return im


def down(im, size):
    return im.resize((size, size), Image.LANCZOS)


logo = logo_layer()
down(logo, 1024).save("assets/icon/logo.png")

# launcher icon: dark gradient background + logo
bg = Image.new("RGBA", (1024, 1024))
bd = ImageDraw.Draw(bg)
for y in range(1024):
    t = y / 1023
    bd.line([(0, y), (1024, y)], fill=(int(40 + 90 * t), int(14 + 10 * t), int(24 + 6 * t), 255))
icon = bg.copy()
small = down(logo, 940)
icon.alpha_composite(small, (42, 42))
icon.save("assets/icon/icon.png")

# adaptive foreground: keep the artwork inside the safe zone (about 62%)
fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
fg.alpha_composite(down(logo, 700), (162, 162))
fg.save("assets/icon/icon_fg.png")
print("logo written")
