#!/usr/bin/env python3
"""Generate a simple kitchen-themed GLB (cooking pot + ladle) for Made by Maa."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "models" / "kitchen_pot.glb"


def rgba_mesh(mesh: trimesh.Trimesh, rgba: list[int]) -> trimesh.Trimesh:
    mesh.visual.vertex_colors = np.tile(rgba, (len(mesh.vertices), 1))
    return mesh


def main() -> None:
    # Cooking pot body
    pot = trimesh.creation.cylinder(radius=0.46, height=0.58, sections=40)
    pot.apply_translation([0.0, 0.0, 0.29])

    pot_inner = trimesh.creation.cylinder(radius=0.38, height=0.5, sections=32)
    pot_inner.apply_translation([0.0, 0.0, 0.32])

    rim = trimesh.creation.torus(
        major_radius=0.47,
        minor_radius=0.035,
        major_sections=40,
        minor_sections=12,
    )
    rim.apply_translation([0.0, 0.0, 0.55])

    lid = trimesh.creation.cylinder(radius=0.43, height=0.07, sections=32)
    lid.apply_translation([0.0, 0.0, 0.62])

    knob = trimesh.creation.icosphere(subdivisions=2, radius=0.055)
    knob.apply_translation([0.0, 0.0, 0.69])

    # Wooden ladle beside the pot
    handle = trimesh.creation.cylinder(radius=0.022, height=0.55, sections=12)
    handle.apply_transform(
        trimesh.transformations.rotation_matrix(np.pi / 2.0, [0.0, 1.0, 0.0])
    )
    handle.apply_translation([0.78, 0.0, 0.34])

    ladle_bowl = trimesh.creation.icosphere(subdivisions=2, radius=0.11)
    ladle_bowl.apply_translation([1.0, 0.0, 0.42])

    # Serving plate
    plate = trimesh.creation.cylinder(radius=0.34, height=0.03, sections=36)
    plate.apply_translation([-0.72, 0.0, 0.015])

    plate_rim = trimesh.creation.torus(
        major_radius=0.34,
        minor_radius=0.018,
        major_sections=36,
        minor_sections=10,
    )
    plate_rim.apply_translation([-0.72, 0.0, 0.03])

    # Soft steam puffs above the pot
    steam = []
    for i, (x, z, r) in enumerate(
        [
            (-0.08, 0.82, 0.07),
            (0.06, 0.92, 0.055),
            (0.0, 1.02, 0.045),
        ]
    ):
        puff = trimesh.creation.icosphere(subdivisions=2, radius=r)
        puff.apply_translation([x, 0.0, z])
        alpha = 180 - i * 35
        steam.append(rgba_mesh(puff, [255, 255, 255, alpha]))

    meshes = [
        rgba_mesh(pot, [176, 92, 48, 255]),
        rgba_mesh(pot_inner, [120, 58, 28, 255]),
        rgba_mesh(rim, [142, 72, 38, 255]),
        rgba_mesh(lid, [158, 84, 44, 255]),
        rgba_mesh(knob, [98, 33, 176, 255]),  # brand purple
        rgba_mesh(handle, [118, 78, 46, 255]),
        rgba_mesh(ladle_bowl, [210, 210, 210, 255]),
        rgba_mesh(plate, [245, 240, 232, 255]),
        rgba_mesh(plate_rim, [220, 210, 198, 255]),
        *steam,
    ]

    scene = trimesh.Scene(meshes)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    scene.export(str(OUTPUT))
    print(f"Wrote {OUTPUT} ({OUTPUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
