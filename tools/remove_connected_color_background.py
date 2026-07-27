from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


def estimate_key_color(rgb: np.ndarray) -> np.ndarray:
    height, width, _ = rgb.shape
    sample_size = max(2, min(height, width) // 40)
    samples = np.concatenate(
        (
            rgb[:sample_size, :sample_size].reshape(-1, 3),
            rgb[:sample_size, -sample_size:].reshape(-1, 3),
            rgb[-sample_size:, :sample_size].reshape(-1, 3),
            rgb[-sample_size:, -sample_size:].reshape(-1, 3),
        ),
        axis=0,
    )
    return np.median(samples, axis=0).astype(np.float32)


def remove_connected_color_background(
    path: Path,
    inner_distance: float,
    outer_distance: float,
    despill: bool,
    fast_save: bool,
) -> None:
    with Image.open(path) as source:
        rgb = np.asarray(source.convert("RGB"), dtype=np.uint8)

    key_color = estimate_key_color(rgb)
    difference = rgb.astype(np.float32) - key_color
    distance = np.sqrt(np.sum(difference * difference, axis=2))
    candidate = distance <= outer_distance

    candidate_image = Image.fromarray(
        candidate.astype(np.uint8) * 255,
        mode="L",
    ).copy()
    ImageDraw.floodfill(candidate_image, (0, 0), 128, thresh=0)
    connected_background = np.asarray(candidate_image) == 128

    alpha = np.full(distance.shape, 255, dtype=np.uint8)
    blend_width = max(1.0, outer_distance - inner_distance)
    softened_alpha = np.clip(
        (distance - inner_distance) * 255.0 / blend_width,
        0.0,
        255.0,
    ).astype(np.uint8)
    alpha[connected_background] = softened_alpha[connected_background]

    output_rgb = rgb.copy()
    if despill:
        green = output_rgb[:, :, 1].astype(np.float32)
        neutral_green = np.maximum(
            output_rgb[:, :, 0],
            output_rgb[:, :, 2],
        ).astype(np.float32)
        transparency = 1.0 - alpha.astype(np.float32) / 255.0
        corrected_green = green + (neutral_green - green) * transparency
        output_rgb[:, :, 1][connected_background] = np.clip(
            corrected_green[connected_background],
            0.0,
            255.0,
        ).astype(np.uint8)

    rgba = np.dstack((output_rgb, alpha))
    output_image = Image.fromarray(rgba, mode="RGBA")
    if fast_save:
        output_image.save(path, compress_level=1)
    else:
        output_image.save(path, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Remove a corner-sampled color background only where it remains "
            "connected to the image boundary."
        )
    )
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--inner-distance", type=float, default=18.0)
    parser.add_argument("--outer-distance", type=float, default=105.0)
    parser.add_argument("--despill", action="store_true")
    parser.add_argument(
        "--fast-save",
        action="store_true",
        help="Use fast PNG compression for temporary frame pipelines.",
    )
    args = parser.parse_args()

    for supplied_path in args.paths:
        files = (
            sorted(supplied_path.glob("*.png"))
            if supplied_path.is_dir()
            else [supplied_path]
        )
        for path in files:
            remove_connected_color_background(
                path,
                args.inner_distance,
                args.outer_distance,
                args.despill,
                args.fast_save,
            )


if __name__ == "__main__":
    main()
