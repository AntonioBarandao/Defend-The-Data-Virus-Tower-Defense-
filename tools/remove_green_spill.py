from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


def remove_green_spill(
    path: Path,
    dominance_threshold: float,
    feather_width: float,
    fast_save: bool,
) -> None:
    with Image.open(path) as source:
        rgba = np.asarray(source.convert("RGBA"), dtype=np.uint8).copy()

    rgb = rgba[:, :, :3].astype(np.float32)
    alpha = rgba[:, :, 3].astype(np.float32)
    red = rgb[:, :, 0]
    green = rgb[:, :, 1]
    blue = rgb[:, :, 2]
    green_dominance = green - np.maximum(red, blue)

    alpha_multiplier = np.clip(
        (
            dominance_threshold
            + feather_width
            - green_dominance
        ) / feather_width,
        0.0,
        1.0,
    )
    alpha *= alpha_multiplier

    spill_mask = green_dominance > 0.0
    green[spill_mask] = np.maximum(red[spill_mask], blue[spill_mask])

    rgba[:, :, :3] = np.stack((red, green, blue), axis=-1).astype(np.uint8)
    rgba[:, :, 3] = alpha.astype(np.uint8)
    output = Image.fromarray(rgba, mode="RGBA")
    if fast_save:
        output.save(path, compress_level=1)
    else:
        output.save(path, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Remove residual green spill from already keyed RGBA images."
        )
    )
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument(
        "--dominance-threshold",
        type=float,
        default=20.0,
    )
    parser.add_argument("--feather-width", type=float, default=22.0)
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
            remove_green_spill(
                path,
                args.dominance_threshold,
                args.feather_width,
                args.fast_save,
            )


if __name__ == "__main__":
    main()
