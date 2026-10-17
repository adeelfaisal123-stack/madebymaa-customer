#!/usr/bin/env python3
"""Generate a stylized-realistic desi kitchen food scene GLB for Made by Maa."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import trimesh
from trimesh.transformations import rotation_matrix
from trimesh.visual.material import PBRMaterial


def scale_xyz(sx: float, sy: float, sz: float) -> np.ndarray:
    matrix = np.eye(4)
    matrix[0, 0] = sx
    matrix[1, 1] = sy
    matrix[2, 2] = sz
    return matrix


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "models" / "desi_kitchen_food.glb"


def rgba(color: list[float], alpha: float = 1.0) -> list[float]:
    if len(color) == 3:
        return [*color, alpha]
    return color


def pbr_mesh(
    mesh: trimesh.Trimesh,
    color: list[float],
    *,
    metallic: float = 0.0,
    roughness: float = 0.75,
    name: str | None = None,
) -> trimesh.Trimesh:
    mesh.visual.material = PBRMaterial(
        name=name,
        baseColorFactor=rgba(color),
        metallicFactor=metallic,
        roughnessFactor=roughness,
    )
    return mesh


def box(
    extents: tuple[float, float, float],
    center: tuple[float, float, float],
    color: list[float],
    **pbr,
) -> trimesh.Trimesh:
    mesh = trimesh.creation.box(extents=extents)
    mesh.apply_translation(center)
    return pbr_mesh(mesh, color, **pbr)


def cylinder(
    radius: float,
    height: float,
    center: tuple[float, float, float],
    color: list[float],
    sections: int = 48,
    **pbr,
) -> trimesh.Trimesh:
    mesh = trimesh.creation.cylinder(radius=radius, height=height, sections=sections)
    mesh.apply_translation([center[0], center[1], center[2] + height / 2])
    return pbr_mesh(mesh, color, **pbr)


def katori(
    center: tuple[float, float, float],
    food_color: list[float],
    *,
    bowl_color: list[float] | None = None,
    food_height: float = 0.045,
) -> list[trimesh.Trimesh]:
    bowl = cylinder(
        0.075,
        0.035,
        center,
        bowl_color or [0.78, 0.78, 0.8],
        metallic=0.55,
        roughness=0.28,
        name="steel_katori",
    )
    food = trimesh.creation.icosphere(subdivisions=3, radius=0.068)
    food.apply_transform(scale_xyz(1.0, 1.0, 0.42))
    food.apply_translation([center[0], center[1], center[2] + food_height])
    pbr_mesh(food, food_color, roughness=0.92, name="food")
    return [bowl, food]


def roti(
    center: tuple[float, float, float],
    radius: float = 0.11,
    *,
    shade: float = 0.0,
) -> trimesh.Trimesh:
    mesh = trimesh.creation.cylinder(radius=radius, height=0.012, sections=48)
    mesh.apply_translation([center[0], center[1], center[2] + 0.006])
    color = [0.86 + shade, 0.72 + shade * 0.5, 0.45 + shade * 0.3]
    return pbr_mesh(mesh, color, roughness=0.88, name="roti")


def handi_biryani(center: tuple[float, float, float]) -> list[trimesh.Trimesh]:
    body = cylinder(
        0.28,
        0.34,
        center,
        [0.72, 0.34, 0.18],
        metallic=0.15,
        roughness=0.55,
        name="handi",
    )
    rim = trimesh.creation.torus(
        major_radius=0.285,
        minor_radius=0.018,
        major_sections=48,
        minor_sections=12,
    )
    rim.apply_translation([center[0], center[1], center[2] + 0.34])
    pbr_mesh(rim, [0.58, 0.26, 0.12], metallic=0.2, roughness=0.5, name="handi_rim")

    rice = trimesh.creation.icosphere(subdivisions=3, radius=0.22)
    rice.apply_transform(scale_xyz(1.0, 1.0, 0.55))
    rice.apply_translation([center[0], center[1], center[2] + 0.36])
    pbr_mesh(rice, [0.93, 0.78, 0.38], roughness=0.95, name="biryani_rice")

    # Saffron onion/fried onion bits
    bits: list[trimesh.Trimesh] = []
    rng = np.random.default_rng(7)
    for _ in range(18):
        bit = trimesh.creation.icosphere(subdivisions=1, radius=rng.uniform(0.012, 0.022))
        angle = rng.uniform(0, 2 * np.pi)
        dist = rng.uniform(0.02, 0.16)
        bit.apply_translation(
            [
                center[0] + np.cos(angle) * dist,
                center[1] + np.sin(angle) * dist,
                center[2] + 0.42 + rng.uniform(-0.01, 0.02),
            ]
        )
        bits.append(
            pbr_mesh(
                bit,
                [0.78, 0.48, 0.12],
                roughness=0.9,
                name="biryani_garnish",
            )
        )

    lid = trimesh.creation.cylinder(radius=0.24, height=0.05, sections=40)
    lid.apply_transform(rotation_matrix(np.pi / 5, [0.0, 1.0, 0.0]))
    lid.apply_translation([center[0] + 0.34, center[1] + 0.08, center[2] + 0.28])
    pbr_mesh(lid, [0.66, 0.3, 0.15], metallic=0.18, roughness=0.52, name="handi_lid")

    steam: list[trimesh.Trimesh] = []
    for i, (dx, dz, r) in enumerate([(0.0, 0.48, 0.06), (0.05, 0.58, 0.045), (-0.04, 0.66, 0.035)]):
        puff = trimesh.creation.icosphere(subdivisions=2, radius=r)
        puff.apply_translation([center[0] + dx, center[1], center[2] + dz])
        steam.append(
            pbr_mesh(
                puff,
                [1.0, 1.0, 1.0, 0.22 - i * 0.05],
                roughness=1.0,
                name="steam",
            )
        )

    return [body, rim, rice, lid, *bits, *steam]


def tawa_paratha(origin: tuple[float, float, float]) -> list[trimesh.Trimesh]:
    pan = cylinder(
        0.24,
        0.018,
        origin,
        [0.18, 0.18, 0.19],
        metallic=0.75,
        roughness=0.35,
        name="tawa",
    )
    handle = trimesh.creation.cylinder(radius=0.022, height=0.28, sections=16)
    handle.apply_transform(rotation_matrix(np.pi / 2.0, [0.0, 1.0, 0.0]))
    handle.apply_translation([origin[0] + 0.38, origin[1], origin[2] + 0.05])
    pbr_mesh(handle, [0.14, 0.14, 0.15], metallic=0.8, roughness=0.4, name="tawa_handle")

    paratha = roti((origin[0], origin[1], origin[2] + 0.02), radius=0.17, shade=0.04)
    paratha.visual.material.name = "paratha"

    spot_rng = np.random.default_rng(11)
    spots: list[trimesh.Trimesh] = []
    for _ in range(10):
        spot = trimesh.creation.icosphere(subdivisions=1, radius=spot_rng.uniform(0.012, 0.024))
        spot.apply_transform(scale_xyz(1.0, 1.0, 0.25))
        angle = spot_rng.uniform(0, 2 * np.pi)
        dist = spot_rng.uniform(0.02, 0.12)
        spot.apply_translation(
            [
                origin[0] + np.cos(angle) * dist,
                origin[1] + np.sin(angle) * dist,
                origin[2] + 0.035,
            ]
        )
        spots.append(
            pbr_mesh(spot, [0.55, 0.35, 0.16], roughness=0.85, name="paratha_spot")
        )

    return [pan, handle, paratha, *spots]


def masala_dabba(center: tuple[float, float, float]) -> list[trimesh.Trimesh]:
    base = cylinder(
        0.12,
        0.045,
        center,
        [0.82, 0.82, 0.84],
        metallic=0.7,
        roughness=0.25,
        name="masala_dabba",
    )
    lid = cylinder(
        0.125,
        0.012,
        (center[0], center[1], center[2] + 0.05),
        [0.88, 0.88, 0.9],
        metallic=0.75,
        roughness=0.22,
        name="masala_lid",
    )

    spices: list[trimesh.Trimesh] = []
    palette = [
        [0.78, 0.58, 0.18],
        [0.85, 0.25, 0.12],
        [0.92, 0.86, 0.55],
        [0.45, 0.28, 0.12],
        [0.18, 0.42, 0.18],
    ]
    for i, angle in enumerate(np.linspace(0, 2 * np.pi, 5, endpoint=False)):
        cup = trimesh.creation.cylinder(radius=0.022, height=0.025, sections=20)
        cup.apply_translation(
            [
                center[0] + np.cos(angle) * 0.055,
                center[1] + np.sin(angle) * 0.055,
                center[2] + 0.05,
            ]
        )
        spices.append(
            pbr_mesh(cup, palette[i], roughness=0.95, name="spice")
        )

    return [base, lid, *spices]


def thali_plate(center: tuple[float, float, float]) -> list[trimesh.Trimesh]:
    plate = cylinder(
        0.42,
        0.012,
        center,
        [0.82, 0.62, 0.22],
        metallic=0.88,
        roughness=0.32,
        name="thali",
    )
    rim = trimesh.creation.torus(
        major_radius=0.41,
        minor_radius=0.012,
        major_sections=56,
        minor_sections=10,
    )
    rim.apply_translation([center[0], center[1], center[2] + 0.012])
    pbr_mesh(rim, [0.72, 0.52, 0.16], metallic=0.9, roughness=0.28, name="thali_rim")

    z = center[2] + 0.02
    items: list[trimesh.Trimesh] = [
        roti((center[0] - 0.14, center[1] + 0.1, z)),
        roti((center[0] - 0.1, center[1] + 0.12, z + 0.012), shade=0.02),
        *katori((center[0] + 0.12, center[1] + 0.08, z), [0.92, 0.78, 0.22], food_height=0.04),  # dal
        *katori((center[0] + 0.15, center[1] - 0.1, z), [0.86, 0.42, 0.14], food_height=0.038),  # paneer curry
        *katori((center[0] - 0.02, center[1] - 0.12, z), [0.95, 0.94, 0.9], food_height=0.035),  # rice
    ]

    papad = trimesh.creation.cylinder(radius=0.055, height=0.004, sections=32)
    papad.apply_translation([center[0] + 0.02, center[1] + 0.16, z + 0.004])
    items.append(pbr_mesh(papad, [0.78, 0.55, 0.22], roughness=0.8, name="papad"))

    pickle = trimesh.creation.icosphere(subdivisions=2, radius=0.028)
    pickle.apply_transform(scale_xyz(1.0, 1.0, 0.6))
    pickle.apply_translation([center[0] - 0.18, center[1] - 0.05, z + 0.02])
    items.append(pbr_mesh(pickle, [0.55, 0.08, 0.1], roughness=0.9, name="pickle"))

    return [plate, rim, *items]


def main() -> None:
    meshes: list[trimesh.Trimesh] = []

    # Kitchen counter + backsplash
    meshes.append(
        box(
            (2.8, 1.6, 0.09),
            (0.0, 0.0, 0.045),
            [0.93, 0.9, 0.86],
            roughness=0.45,
            name="counter",
        )
    )
    meshes.append(
        box(
            (2.8, 0.06, 0.72),
            (0.0, -0.77, 0.45),
            [0.96, 0.94, 0.9],
            roughness=0.55,
            name="backsplash",
        )
    )
    meshes.append(
        box(
            (2.8, 0.08, 0.12),
            (0.0, 0.74, 0.06),
            [0.42, 0.28, 0.18],
            roughness=0.7,
            name="counter_front",
        )
    )

    # Wall tiles accent strip
    for i in range(-6, 7):
        tile = box(
            (0.18, 0.02, 0.18),
            (i * 0.2, -0.74, 0.34 + (i % 2) * 0.18),
            [0.88, 0.55, 0.2] if i % 2 == 0 else [0.95, 0.92, 0.86],
            roughness=0.6,
            name="tile",
        )
        meshes.append(tile)

    # Main food arrangement
    meshes.extend(thali_plate((-0.55, 0.15, 0.09)))
    meshes.extend(handi_biryani((0.72, 0.18, 0.09)))
    meshes.extend(tawa_paratha((0.45, -0.42, 0.09)))
    meshes.extend(masala_dabba((-0.95, -0.45, 0.09)))

    # Belan + chakla (rolling pin and board)
    board = cylinder(0.11, 0.025, (-0.95, 0.48, 0.09), [0.72, 0.52, 0.3], roughness=0.65, name="chakla")
    pin = trimesh.creation.cylinder(radius=0.018, height=0.34, sections=20)
    pin.apply_transform(rotation_matrix(np.pi / 2.2, [0.0, 1.0, 0.0]))
    pin.apply_translation([-0.78, 0.52, 0.13])
    meshes.extend([board, pbr_mesh(pin, [0.68, 0.48, 0.28], roughness=0.62, name="belan")])

    # Steel water glass
    glass = cylinder(0.045, 0.12, (-0.15, -0.48, 0.09), [0.82, 0.84, 0.86], metallic=0.65, roughness=0.18, name="glass")
    water = trimesh.creation.cylinder(radius=0.038, height=0.09, sections=24)
    water.apply_translation([-0.15, -0.48, 0.135])
    meshes.extend([glass, pbr_mesh(water, [0.72, 0.86, 0.95, 0.75], roughness=0.1, name="water")])

    # Hanging ladle hook detail
    hook = trimesh.creation.torus(major_radius=0.035, minor_radius=0.006, major_sections=24, minor_sections=8)
    hook.apply_translation([1.05, -0.72, 0.62])
    meshes.append(pbr_mesh(hook, [0.72, 0.72, 0.74], metallic=0.85, roughness=0.25, name="hook"))

    scene = trimesh.Scene(meshes)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    scene.export(str(OUTPUT))
    print(f"Wrote {OUTPUT} ({OUTPUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
