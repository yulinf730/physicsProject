#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

SIZE = 1024
OUT_DIR = Path("/Users/yulinfeng/Documents/physicsProjectAlevel/physicsProject/Assets.xcassets/AppIcon.appiconset")


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def mix(c1, c2, t: float):
    return tuple(int(lerp(c1[i], c2[i], t)) for i in range(3))


def vertical_gradient(size: int, top, bottom):
    image = Image.new("RGBA", (size, size))
    pixels = image.load()
    for y in range(size):
        t = y / (size - 1)
        row = mix(top, bottom, t)
        for x in range(size):
            pixels[x, y] = (*row, 255)
    return image


def radial_glow(size: int, center, radius: int, color, alpha: int, blur: int | None = None):
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(*color, alpha))
    return layer.filter(ImageFilter.GaussianBlur(blur or radius // 2))


def add_noise_stars(base: Image.Image, stars):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for x, y, r, alpha in stars:
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, alpha))
    return Image.alpha_composite(base, layer.filter(ImageFilter.GaussianBlur(1)))


def draw_wave(draw: ImageDraw.ImageDraw, x0: float, x1: float, y: float, amplitude: float, cycles: float, fill, width: int):
    points = []
    steps = 220
    for i in range(steps + 1):
        t = i / steps
        x = lerp(x0, x1, t)
        yy = y + math.sin(t * cycles * 2 * math.pi) * amplitude
        points.append((x, yy))
    draw.line(points, fill=fill, width=width, joint="curve")
    return points


def glow_line(layer: Image.Image, points, fill, width=12, blur_radius=18):
    glow = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).line(points, fill=fill, width=width, joint="curve")
    glow = glow.filter(ImageFilter.GaussianBlur(blur_radius))
    return Image.alpha_composite(layer, glow)


def polygon_shadow(size: int, points, offset=(0, 0), alpha=120, blur=20, color=(17, 8, 40)):
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shifted = [(x + offset[0], y + offset[1]) for x, y in points]
    ImageDraw.Draw(layer).polygon(shifted, fill=(*color, alpha))
    return layer.filter(ImageFilter.GaussianBlur(blur))


def draw_icon(mode: str) -> Image.Image:
    if mode == "any":
        top = (66, 31, 122)
        bottom = (132, 92, 242)
        top_right = (84, 126, 255)
        halo = (188, 154, 255)
        glass_white = (250, 248, 255)
        edge = (255, 255, 255)
        inner = (209, 199, 255)
        cyan = (112, 235, 255)
        gold = (255, 207, 111)
        spark = (255, 245, 222)
        wave = (225, 235, 255)
    elif mode == "dark":
        top = (25, 16, 58)
        bottom = (82, 52, 152)
        top_right = (71, 100, 214)
        halo = (131, 106, 220)
        glass_white = (242, 241, 255)
        edge = (255, 255, 255)
        inner = (173, 166, 230)
        cyan = (99, 221, 255)
        gold = (255, 195, 96)
        spark = (255, 238, 204)
        wave = (218, 228, 255)
    else:
        top = (89, 72, 142)
        bottom = (142, 120, 191)
        top_right = (168, 152, 224)
        halo = (210, 194, 244)
        glass_white = (248, 245, 255)
        edge = (255, 255, 255)
        inner = (221, 211, 246)
        cyan = (245, 243, 255)
        gold = (246, 242, 255)
        spark = (255, 255, 255)
        wave = (248, 246, 255)

    base = vertical_gradient(SIZE, top, bottom)
    base = Image.alpha_composite(base, radial_glow(SIZE, (784, 246), 420, top_right, 84, blur=180))
    base = Image.alpha_composite(base, radial_glow(SIZE, (230, 808), 380, halo, 42, blur=220))
    base = Image.alpha_composite(base, radial_glow(SIZE, (512, 430), 240, (255, 255, 255), 32, blur=84))

    vignette = radial_glow(SIZE, (512, 512), 620, (0, 0, 0), 0, blur=300)
    vignette = ImageChops.invert(vignette.convert("RGB")).convert("RGBA")
    base = Image.blend(base, vignette, 0.10)

    base = add_noise_stars(base, [
        (184, 216, 3, 165),
        (772, 208, 2, 140),
        (810, 404, 2, 150),
        (254, 728, 2, 130),
        (702, 716, 2, 148),
        (318, 286, 2, 120),
    ])

    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    draw.ellipse((236, 172, 788, 724), fill=(*halo, 30))
    layer = layer.filter(ImageFilter.GaussianBlur(10))
    draw = ImageDraw.Draw(layer)

    left_leg = [(332, 734), (438, 252), (500, 252), (414, 734)]
    right_leg = [(526, 252), (588, 252), (694, 734), (612, 734)]

    layer = Image.alpha_composite(layer, polygon_shadow(SIZE, left_leg, offset=(10, 18), alpha=110, blur=22))
    layer = Image.alpha_composite(layer, polygon_shadow(SIZE, right_leg, offset=(10, 18), alpha=110, blur=22))

    draw = ImageDraw.Draw(layer)
    draw.polygon(left_leg, fill=(*glass_white, 238))
    draw.polygon(right_leg, fill=(*glass_white, 238))
    draw.line(left_leg + [left_leg[0]], fill=(*edge, 240), width=8, joint="curve")
    draw.line(right_leg + [right_leg[0]], fill=(*edge, 240), width=8, joint="curve")

    draw.line([(466, 300), (410, 682)], fill=(*inner, 180), width=6)
    draw.line([(557, 300), (616, 682)], fill=(*inner, 180), width=6)

    wave_points = draw_wave(draw, 384, 640, 544, 18, 1.25, (*wave, 245), 10)
    layer = glow_line(layer, wave_points, (*cyan, 100), width=18, blur_radius=18)
    draw = ImageDraw.Draw(layer)
    draw_wave(draw, 384, 640, 544, 18, 1.25, (*cyan, 238), 8)

    crossbar = [(396, 520), (642, 520), (642, 568), (396, 568)]
    layer = Image.alpha_composite(layer, radial_glow(SIZE, (520, 544), 70, cyan, 80, blur=36))

    apex_spark = radial_glow(SIZE, (512, 246), 34, gold, 210, blur=20)
    layer = Image.alpha_composite(layer, apex_spark)

    draw = ImageDraw.Draw(layer)
    for x, y, s in [(252, 384, 24), (770, 330, 20), (756, 746, 18)]:
        draw.line([(x - s, y), (x + s, y)], fill=(*spark, 185), width=4)
        draw.line([(x, y - s), (x, y + s)], fill=(*spark, 185), width=4)

    # Small quantum dot in the centre.
    core = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(core).ellipse((486, 510, 550, 574), fill=(*gold, 220))
    core = core.filter(ImageFilter.GaussianBlur(12))
    layer = Image.alpha_composite(layer, core)

    if mode == "tinted":
        tint_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        td = ImageDraw.Draw(tint_overlay)
        td.polygon(left_leg, fill=(250, 246, 255, 238))
        td.polygon(right_leg, fill=(250, 246, 255, 238))
        td.line(wave_points, fill=(248, 245, 255, 235), width=10, joint="curve")
        tint_overlay = tint_overlay.filter(ImageFilter.GaussianBlur(1))
        layer = Image.alpha_composite(layer, tint_overlay)

    return Image.alpha_composite(base, layer).convert("RGB")


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    variants = {
        "AppIcon-Any.png": "any",
        "AppIcon-Dark.png": "dark",
        "AppIcon-Tinted.png": "tinted",
    }
    for filename, mode in variants.items():
        draw_icon(mode).save(OUT_DIR / filename, format="PNG")
        print(f"wrote {OUT_DIR / filename}")


if __name__ == "__main__":
    main()
