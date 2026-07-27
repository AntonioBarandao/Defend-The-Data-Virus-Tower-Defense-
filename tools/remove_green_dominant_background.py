from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


def _edge_connected_mask(candidate: np.ndarray) -> np.ndarray:
    mask = Image.fromarray(
        np.where(candidate, 255, 0).astype(np.uint8),
        mode="L",
    ).copy()
    width, height = mask.size
    for seed in (
        (0, 0),
        (width - 1, 0),
        (0, height - 1),
        (width - 1, height - 1),
    ):
        if mask.getpixel(seed) == 255:
            ImageDraw.floodfill(mask, seed, 128, thresh=0)
    return np.asarray(mask, dtype=np.uint8) == 128


def remove_green_dominant_background(
    path: Path,
    excess_start: float,
    excess_full: float,
    green_start: float,
    green_full: float,
    despill: bool,
    despill_all: bool,
    edge_connected_only: bool,
    clear_transparent_rgb: bool,
    hard_key: bool,
    preserve_alpha: bool,
) -> None:
    with Image.open(path) as source:
        rgba = np.asarray(source.convert("RGBA"), dtype=np.uint8)

    rgb = rgba[:, :, :3].astype(np.float32)
    red = rgb[:, :, 0]
    green = rgb[:, :, 1]
    blue = rgb[:, :, 2]
    neutral = np.maximum(red, blue)
    green_excess = green - neutral

    excess_range = max(1.0, excess_full - excess_start)
    green_range = max(1.0, green_full - green_start)
    excess_strength = np.clip(
        (green_excess - excess_start) / excess_range,
        0.0,
        1.0,
    )
    brightness_strength = np.clip(
        (green - green_start) / green_range,
        0.0,
        1.0,
    )
    key_strength = np.minimum(excess_strength, brightness_strength)
    connected_background = None
    if edge_connected_only:
        connected_background = _edge_connected_mask(key_strength > 0.0)
        key_strength = np.where(
            connected_background,
            key_strength,
            0.0,
        )

    source_alpha = rgba[:, :, 3].astype(np.float32) / 255.0
    if preserve_alpha:
        output_alpha = rgba[:, :, 3].copy()
    elif hard_key:
        hard_key_mask = (green_excess > excess_start) & (
            green > green_start
        )
        if connected_background is not None:
            hard_key_mask &= connected_background
        key_strength = hard_key_mask.astype(np.float32)
        output_alpha = rgba[:, :, 3].copy()
        output_alpha[hard_key_mask] = 0
    else:
        output_alpha = np.clip(
            source_alpha * (1.0 - key_strength) * 255.0,
            0.0,
            255.0,
        ).astype(np.uint8)

    output_rgb = rgba[:, :, :3].copy()
    if despill:
        if connected_background is not None:
            edge_strength = np.clip(
                green_excess / max(1.0, excess_start),
                0.0,
                1.0,
            ) * connected_background
        else:
            edge_strength = (key_strength > 0.0).astype(np.float32)
        corrected_green = green + (neutral - green) * edge_strength
        output_rgb[:, :, 1] = np.clip(
            corrected_green,
            0.0,
            255.0,
        ).astype(np.uint8)
    if despill_all:
        visible_pixels = output_alpha > 16
        output_rgb[:, :, 1][visible_pixels] = np.minimum(
            green[visible_pixels],
            neutral[visible_pixels],
        ).astype(np.uint8)
    if clear_transparent_rgb:
        output_rgb[output_alpha <= 16] = 0

    output = np.dstack((output_rgb, output_alpha))
    Image.fromarray(output, mode="RGBA").save(path, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Remove only pixels whose green channel strongly dominates red "
            "and blue, preserving neutral black and gray sprite details."
        )
    )
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--excess-start", type=float, default=20.0)
    parser.add_argument("--excess-full", type=float, default=72.0)
    parser.add_argument("--green-start", type=float, default=35.0)
    parser.add_argument("--green-full", type=float, default=90.0)
    parser.add_argument("--despill", action="store_true")
    parser.add_argument(
        "--despill-all",
        action="store_true",
        help=(
            "Neutralize residual green dominance in retained pixels without "
            "making those pixels transparent."
        ),
    )
    parser.add_argument(
        "--hard-key",
        action="store_true",
        help=(
            "Make every qualifying green-dominant pixel fully transparent "
            "instead of producing a soft alpha transition."
        ),
    )
    parser.add_argument(
        "--clear-transparent-rgb",
        action="store_true",
        help=(
            "Clear RGB beneath nearly transparent pixels so lossy atlas "
            "compression cannot bleed the keyed color back onto sprite edges."
        ),
    )
    parser.add_argument(
        "--edge-connected-only",
        action="store_true",
        help=(
            "Only key green regions connected to the frame corners. "
            "This preserves enclosed green details inside the sprite."
        ),
    )
    parser.add_argument(
        "--preserve-alpha",
        action="store_true",
        help=(
            "Keep the source alpha unchanged. This is useful for a final "
            "despill pass after resizing a keyed image."
        ),
    )
    args = parser.parse_args()

    for supplied_path in args.paths:
        files = (
            sorted(supplied_path.glob("*.png"))
            if supplied_path.is_dir()
            else [supplied_path]
        )
        for path in files:
            remove_green_dominant_background(
                path,
                args.excess_start,
                args.excess_full,
                args.green_start,
                args.green_full,
                args.despill,
                args.despill_all,
                args.edge_connected_only,
                args.clear_transparent_rgb,
                args.hard_key,
                args.preserve_alpha,
            )


if __name__ == "__main__":
    main()
