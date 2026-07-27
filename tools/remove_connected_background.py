from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


def remove_connected_white_background(
    path: Path,
    threshold: int,
    neutral_delta: int,
    hard_alpha: bool,
    protect_center_holes: bool,
) -> None:
    with Image.open(path) as source:
        rgb = np.asarray(source.convert("RGB"), dtype=np.uint8)

    minimum = rgb.min(axis=2)
    maximum = rgb.max(axis=2)
    candidate = (minimum >= threshold) & ((maximum - minimum) <= neutral_delta)
    candidate_image = Image.fromarray(candidate.astype(np.uint8) * 255, mode="L").copy()
    ImageDraw.floodfill(candidate_image, (0, 0), 128, thresh=0)
    connected_background = np.asarray(candidate_image) == 128
    background = connected_background

    if protect_center_holes:
        foreground_seed = ~candidate
        foreground_points = np.argwhere(foreground_seed)
        if foreground_points.size > 0:
            center_y = rgb.shape[0] // 2
            center_x = rgb.shape[1] // 2
            distances = (
                (foreground_points[:, 0] - center_y) ** 2
                + (foreground_points[:, 1] - center_x) ** 2
            )
            seed_y, seed_x = foreground_points[int(np.argmin(distances))]
            component_image = Image.fromarray(
                foreground_seed.astype(np.uint8) * 255,
                mode="L",
            ).copy()
            ImageDraw.floodfill(
                component_image,
                (int(seed_x), int(seed_y)),
                128,
                thresh=0,
            )
            center_component = np.asarray(component_image) == 128
            exterior_image = Image.fromarray(
                (~center_component).astype(np.uint8) * 255,
                mode="L",
            ).copy()
            ImageDraw.floodfill(exterior_image, (0, 0), 128, thresh=0)
            exterior = np.asarray(exterior_image) == 128
            protected_holes = (~center_component) & (~exterior)
            protection_region = np.zeros_like(protected_holes)
            protection_region[
                int(rgb.shape[0] * 0.14) : int(rgb.shape[0] * 0.25),
                int(rgb.shape[1] * 0.38) : int(rgb.shape[1] * 0.62),
            ] = True
            protected_holes &= protection_region
            background = candidate & (~protected_holes)

    alpha = np.full(minimum.shape, 255, dtype=np.uint8)
    if hard_alpha:
        alpha[background] = 0
    else:
        fully_transparent_threshold = 245
        softness = max(1, fully_transparent_threshold - threshold)
        softened_alpha = np.clip(
            (fully_transparent_threshold - minimum.astype(np.int16)) * 255 / softness,
            0,
            255,
        ).astype(np.uint8)
        alpha[background] = softened_alpha[background]

    rgba = np.dstack((rgb, alpha))
    Image.fromarray(rgba, mode="RGBA").save(path, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Remove only the edge-connected near-white background from PNG assets."
    )
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--threshold", type=int, default=225)
    parser.add_argument("--neutral-delta", type=int, default=28)
    parser.add_argument("--hard-alpha", action="store_true")
    parser.add_argument("--protect-center-holes", action="store_true")
    args = parser.parse_args()

    for supplied_path in args.paths:
        if supplied_path.is_dir():
            files = sorted(supplied_path.glob("*.png"))
        else:
            files = [supplied_path]
        for path in files:
            remove_connected_white_background(
                path,
                args.threshold,
                args.neutral_delta,
                args.hard_alpha,
                args.protect_center_holes,
            )


if __name__ == "__main__":
    main()
