from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image


def build_atlas(
    frame_directory: Path,
    output_path: Path,
    frame_size: int,
    columns: int,
) -> int:
    frame_paths = sorted(frame_directory.glob("frame_*.png"))
    if not frame_paths:
        raise ValueError(f"No PNG frames found in {frame_directory}")

    rows = math.ceil(len(frame_paths) / columns)
    atlas = Image.new(
        "RGBA",
        (columns * frame_size, rows * frame_size),
        (0, 0, 0, 0),
    )
    for frame_index, frame_path in enumerate(frame_paths):
        with Image.open(frame_path) as source:
            frame = source.convert("RGBA")
            if frame.size != (frame_size, frame_size):
                raise ValueError(
                    f"{frame_path} is {frame.size}, expected "
                    f"{frame_size}x{frame_size}"
                )
            atlas.paste(
                frame,
                (
                    (frame_index % columns) * frame_size,
                    (frame_index // columns) * frame_size,
                ),
            )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    if output_path.suffix.lower() == ".webp":
        atlas.save(
            output_path,
            format="WEBP",
            lossless=True,
            quality=100,
            method=3,
            exact=True,
        )
    elif output_path.suffix.lower() == ".png":
        atlas.save(
            output_path,
            format="PNG",
            compress_level=7,
        )
    else:
        raise ValueError(f"Unsupported atlas format: {output_path.suffix}")
    return len(frame_paths)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Pack exact RGBA PNG frames into one lossless atlas."
    )
    parser.add_argument("frame_directory", type=Path)
    parser.add_argument("output_path", type=Path)
    parser.add_argument("--frame-size", type=int, required=True)
    parser.add_argument("--columns", type=int, default=10)
    args = parser.parse_args()

    frame_count = build_atlas(
        args.frame_directory,
        args.output_path,
        args.frame_size,
        args.columns,
    )
    print(f"Packed {frame_count} exact-RGBA frames into {args.output_path}.")


if __name__ == "__main__":
    main()
