#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "pillow",
#   "numpy",
# ]
# ///
"""Transfer the color palette of one image onto another.

Matches the mean/std of each CIE L*a*b* channel of the target image to the
source image's, which carries over the source's overall tone, contrast and
color cast while keeping the target's content/structure intact.

Pillow's built-in RGB->LAB conversion is unreliable (it produces nonsensical
values for many pixels), so this implements the standard
sRGB -> linear RGB -> XYZ -> CIE L*a*b* pipeline manually with numpy.

Usage:
    uv run scripts/color-transfer.py SOURCE TARGET OUTPUT [--strength 1.0]

Example:
    uv run scripts/color-transfer.py \\
        modules/common/theme/wallpapers/wallpaper3.jpg \\
        modules/common/theme/wallpapers/wallpaper11.jpg \\
        modules/common/theme/wallpapers/wallpaper11.jpg
"""

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# sRGB D65 to XYZ matrix
_RGB2XYZ = np.array(
    [
        [0.4124564, 0.3575761, 0.1804375],
        [0.2126729, 0.7151522, 0.0721750],
        [0.0193339, 0.1191920, 0.9503041],
    ]
)
_XYZ2RGB = np.linalg.inv(_RGB2XYZ)

# D65 reference white
_WHITE = np.array([0.95047, 1.0, 1.08883])

_DELTA = 6 / 29


def srgb_to_linear(c: np.ndarray) -> np.ndarray:
    c = c / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c: np.ndarray) -> np.ndarray:
    c = np.clip(c, 0, 1)
    out = np.where(c <= 0.0031308, c * 12.92, 1.055 * (c ** (1 / 2.4)) - 0.055)
    return np.clip(out * 255.0, 0, 255)


def rgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    lin = srgb_to_linear(rgb.astype(np.float64))
    xyz = (lin @ _RGB2XYZ.T) / _WHITE

    def f(t: np.ndarray) -> np.ndarray:
        return np.where(t > _DELTA**3, np.cbrt(t), t / (3 * _DELTA**2) + 4 / 29)

    fx, fy, fz = f(xyz[..., 0]), f(xyz[..., 1]), f(xyz[..., 2])
    L = 116 * fy - 16
    a = 500 * (fx - fy)
    b = 200 * (fy - fz)
    return np.stack([L, a, b], axis=-1)


def lab_to_rgb(lab: np.ndarray) -> np.ndarray:
    L, a, b = lab[..., 0], lab[..., 1], lab[..., 2]
    fy = (L + 16) / 116
    fx = fy + a / 500
    fz = fy - b / 200

    def finv(t: np.ndarray) -> np.ndarray:
        return np.where(t > _DELTA, t**3, 3 * _DELTA**2 * (t - 4 / 29))

    xyz = np.stack([finv(fx), finv(fy), finv(fz)], axis=-1) * _WHITE
    lin = xyz @ _XYZ2RGB.T
    return linear_to_srgb(lin)


def transfer_palette(source: Image.Image, target: Image.Image, strength: float = 1.0) -> Image.Image:
    """Return a copy of `target` graded to match `source`'s Lab statistics."""
    src_lab = rgb_to_lab(np.asarray(source.convert("RGB")))
    tgt_lab = rgb_to_lab(np.asarray(target.convert("RGB")))

    src_flat = src_lab.reshape(-1, 3)
    tgt_flat = tgt_lab.reshape(-1, 3)

    src_mean, src_std = src_flat.mean(axis=0), src_flat.std(axis=0)
    tgt_mean, tgt_std = tgt_flat.mean(axis=0), tgt_flat.std(axis=0)

    tgt_std_safe = np.where(tgt_std < 1e-6, 1e-6, tgt_std)
    graded_lab = (tgt_lab - tgt_mean) * (src_std / tgt_std_safe) + src_mean

    if strength < 1.0:
        graded_lab = tgt_lab + (graded_lab - tgt_lab) * strength

    graded_rgb = lab_to_rgb(graded_lab)
    return Image.fromarray(graded_rgb.astype(np.uint8), mode="RGB")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("source", type=Path, help="Image whose color palette to copy")
    parser.add_argument("target", type=Path, help="Image whose content/structure is kept")
    parser.add_argument("output", type=Path, help="Where to save the result (may equal target)")
    parser.add_argument(
        "--strength",
        type=float,
        default=1.0,
        help="Blend factor between the original target (0.0) and the fully graded result (1.0). Default: 1.0",
    )
    parser.add_argument(
        "--quality",
        type=int,
        default=90,
        help="JPEG quality for the output, when saving as JPEG. Default: 90",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    source = Image.open(args.source)
    target = Image.open(args.target)

    result = transfer_palette(source, target, strength=args.strength)

    save_kwargs = {}
    if args.output.suffix.lower() in {".jpg", ".jpeg"}:
        save_kwargs = {"quality": args.quality, "optimize": True, "progressive": True}

    result.save(args.output, **save_kwargs)
    print(f"Saved {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
