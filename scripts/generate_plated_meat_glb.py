#!/usr/bin/env python3
"""High-detail GLB of the Made by Maa hero plated meat dish."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import trimesh
from trimesh.creation import revolve
from trimesh.transformations import rotation_matrix
from trimesh.visual.material import PBRMaterial

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "models" / "plated_meat_dish.glb"

SECTIONS = 72


def rgba(color: list[float], alpha: float = 1.0) -> list[float]:
    return [*color, alpha] if len(color) == 3 else color


def scale_xyz(sx: float, sy: float, sz: float) -> np.ndarray:
    m = np.eye(4)
    m[0, 0], m[1, 1], m[2, 2] = sx, sy, sz
    return m


def pbr(
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


def translate(mesh: trimesh.Trimesh, xyz: tuple[float, float, float]) -> trimesh.Trimesh:
    mesh.apply_translation(xyz)
    return mesh


def wood_table() -> list[trimesh.Trimesh]:
    meshes: list[trimesh.Trimesh] = []
    rng = np.random.default_rng(3)
    plank_w = 1.55
    plank_count = 9
    for i in range(plank_count):
        y = -0.62 + i * (1.24 / (plank_count - 1))
        shade = 0.82 + rng.uniform(-0.08, 0.08)
        plank = trimesh.creation.box(extents=(2.5, plank_w / plank_count + 0.004, 0.055))
        plank.apply_transform(rotation_matrix(rng.uniform(-0.008, 0.008), [0.0, 0.0, 1.0]))
        plank.apply_translation([0.0, y, 0.028 + rng.uniform(-0.002, 0.002)])
        pbr(
            plank,
            [0.42 * shade, 0.36 * shade, 0.3 * shade],
            roughness=0.86,
            name=f"wood_plank_{i}",
        )
        meshes.append(plank)

        if i < plank_count - 1:
            gap = trimesh.creation.box(extents=(2.5, 0.003, 0.012))
            gap.apply_translation([0.0, y + plank_w / plank_count * 0.5, 0.058])
            pbr(gap, [0.18, 0.15, 0.12], roughness=0.95, name="wood_gap")
            meshes.append(gap)

    # Subtle worn edge bevel
    edge = trimesh.creation.box(extents=(2.52, 1.28, 0.006))
    edge.apply_translation([0.0, 0.0, 0.058])
    meshes.append(pbr(edge, [0.34, 0.29, 0.24], roughness=0.9, name="wood_edge"))
    return meshes


def ceramic_bowl(center: tuple[float, float, float]) -> list[trimesh.Trimesh]:
    cx, cy, cz = center
    profile = np.array(
        [
            [0.0, 0.0],
            [0.08, 0.004],
            [0.22, 0.012],
            [0.34, 0.028],
            [0.395, 0.055],
            [0.405, 0.072],
            [0.39, 0.084],
            [0.36, 0.088],
            [0.32, 0.082],
            [0.28, 0.055],
            [0.24, 0.028],
            [0.08, 0.012],
            [0.0, 0.008],
        ]
    )
    shell = revolve(profile, sections=SECTIONS)
    shell.apply_translation([cx, cy, cz])
    pbr(shell, [0.13, 0.13, 0.14], roughness=0.58, name="bowl_shell")

    inner_profile = np.array(
        [
            [0.0, 0.012],
            [0.24, 0.028],
            [0.33, 0.055],
            [0.345, 0.078],
            [0.31, 0.084],
            [0.0, 0.078],
        ]
    )
    inner = revolve(inner_profile, sections=SECTIONS)
    inner.apply_translation([cx, cy, cz + 0.004])
    pbr(inner, [0.07, 0.07, 0.075], roughness=0.72, name="bowl_inner")
    return [shell, inner]


def lettuce_cluster(center: tuple[float, float, float]) -> list[trimesh.Trimesh]:
    leaves: list[trimesh.Trimesh] = []
    specs = [
        ([1.2, 1.0, 0.14], [0.24, 0.55, 0.22], -0.28, 0.0),
        ([1.05, 0.92, 0.12], [0.2, 0.48, 0.18], -0.42, 0.45),
        ([0.95, 1.08, 0.1], [0.26, 0.58, 0.2], -0.18, -0.35),
    ]
    for scale, color, tilt, spin in specs:
        leaf = trimesh.creation.icosphere(subdivisions=4, radius=0.2)
        leaf.apply_transform(scale_xyz(*scale))
        leaf.apply_transform(rotation_matrix(tilt, [1.0, 0.0, 0.0]))
        leaf.apply_transform(rotation_matrix(spin, [0.0, 0.0, 1.0]))
        leaf.apply_translation(center)
        # Crinkle edges via vertex noise
        noise = np.random.default_rng(int(abs(spin * 100))).normal(0, 0.004, leaf.vertices.shape)
        noise[:, 2] *= 2.5
        leaf.vertices += noise
        leaves.append(pbr(leaf, color, roughness=0.82, name="lettuce"))
    return leaves


def meat_slice_stack(bowl_z: float) -> list[trimesh.Trimesh]:
    meshes: list[trimesh.Trimesh] = []
    rng = np.random.default_rng(9)

    slices = [
        # x, y, z, rot_z, scale_x, scale_y, thickness
        (0.0, 0.02, bowl_z + 0.11, 0.08, 1.0, 0.92, 0.095),
        (-0.05, -0.01, bowl_z + 0.118, 0.42, 0.95, 1.05, 0.09),
        (0.06, -0.04, bowl_z + 0.112, -0.25, 1.08, 0.88, 0.088),
        (-0.02, 0.05, bowl_z + 0.122, 0.75, 0.9, 1.0, 0.085),
        (0.03, -0.02, bowl_z + 0.128, -0.55, 1.02, 0.94, 0.08),
    ]

    for x, y, z, rot_z, sx, sy, thick in slices:
        meshes.extend(_meat_slice((x, y, z), rot_z, sx, sy, thick, rng))

    return meshes


def _meat_slice(
    center: tuple[float, float, float],
    rot_z: float,
    sx: float,
    sy: float,
    thick: float,
    rng: np.random.Generator,
) -> list[trimesh.Trimesh]:
    parts: list[trimesh.Trimesh] = []

    def xf(m: trimesh.Trimesh) -> trimesh.Trimesh:
        m.apply_transform(scale_xyz(sx, sy, 1.0))
        m.apply_transform(rotation_matrix(rot_z, [0.0, 0.0, 1.0]))
        m.apply_translation(center)
        return m

    # Main body — pink interior
    body = trimesh.creation.cylinder(radius=0.058, height=thick, sections=48)
    body.apply_transform(rotation_matrix(np.pi / 2.0, [0.0, 1.0, 0.0]))
    xf(body)
    pbr(body, [0.68, 0.32, 0.3], roughness=0.72, name="meat_body")

    # Seared top cap
    top = trimesh.creation.cylinder(radius=0.058, height=0.006, sections=48)
    top.apply_transform(rotation_matrix(np.pi / 2.0, [0.0, 1.0, 0.0]))
    top.apply_translation([0.0, thick / 2 - 0.003, 0.0])
    xf(top)
    pbr(top, [0.28, 0.14, 0.08], roughness=0.48, name="meat_sear_top")

    # Seared bottom cap
    bottom = trimesh.creation.cylinder(radius=0.056, height=0.005, sections=48)
    bottom.apply_transform(rotation_matrix(np.pi / 2.0, [0.0, 1.0, 0.0]))
    bottom.apply_translation([0.0, -thick / 2 + 0.0025, 0.0])
    xf(bottom)
    pbr(bottom, [0.32, 0.16, 0.09], roughness=0.52, name="meat_sear_bottom")

    # Char crust ring around edge
    crust = trimesh.creation.torus(
        major_radius=0.053,
        minor_radius=0.009,
        major_sections=48,
        minor_sections=12,
    )
    crust.apply_transform(rotation_matrix(np.pi / 2.0, [1.0, 0.0, 0.0]))
    xf(crust)
    pbr(crust, [0.22, 0.1, 0.06], roughness=0.55, name="meat_crust")

    # Fat marbling on visible top
    for _ in range(rng.integers(4, 8)):
        vein = trimesh.creation.icosphere(subdivisions=1, radius=rng.uniform(0.004, 0.009))
        vein.apply_transform(scale_xyz(rng.uniform(1.2, 2.0), rng.uniform(0.6, 1.0), 0.35))
        vein.apply_translation(
            [
                rng.uniform(-0.035, 0.035),
                thick / 2 - 0.001,
                rng.uniform(-0.035, 0.035),
            ]
        )
        xf(vein)
        parts.append(pbr(vein, [0.9, 0.82, 0.68], roughness=0.65, name="meat_fat"))

    # Juicy highlight streak
    streak = trimesh.creation.capsule(radius=0.004, height=0.05, count=[6, 6])
    streak.apply_transform(rotation_matrix(np.pi / 2.0, [1.0, 0.0, 0.0]))
    streak.apply_translation([0.015, thick / 2 - 0.001, 0.01])
    xf(streak)
    parts.append(pbr(streak, [0.55, 0.22, 0.18, 0.35], roughness=0.15, name="meat_juice"))

    return [body, top, bottom, crust, *parts]


def onion_rings(bowl_z: float) -> list[trimesh.Trimesh]:
    rings: list[trimesh.Trimesh] = []
    specs = [
        (0.01, 0.07, bowl_z + 0.195, 0.042, 0.18),
        (0.045, 0.03, bowl_z + 0.198, 0.035, 0.55),
        (-0.035, 0.055, bowl_z + 0.193, 0.03, 0.95),
        (0.02, 0.01, bowl_z + 0.2, 0.026, 1.25),
    ]
    for x, y, z, r, tilt in specs:
        ring = trimesh.creation.torus(
            major_radius=r,
            minor_radius=0.0032,
            major_sections=48,
            minor_sections=10,
        )
        ring.apply_transform(rotation_matrix(tilt, [1.0, 0.0, 0.0]))
        ring.apply_transform(rotation_matrix(0.15, [0.0, 1.0, 0.0]))
        ring.apply_translation([x, y, z])
        rings.append(
            pbr(
                ring,
                [0.88, 0.45, 0.42, 0.88],
                roughness=0.35,
                name="onion_ring",
            )
        )
    return rings


def curry_leaf_mesh(center: tuple[float, float, float], angle: float, tilt: float) -> trimesh.Trimesh:
    blade = trimesh.creation.capsule(radius=0.007, height=0.052, count=[10, 10])
    blade.apply_transform(scale_xyz(1.8, 0.55, 0.9))
    blade.apply_transform(rotation_matrix(tilt, [1.0, 0.0, 0.0]))
    blade.apply_transform(rotation_matrix(angle, [0.0, 0.0, 1.0]))
    blade.apply_translation(center)

    vein = trimesh.creation.box(extents=[0.048, 0.0015, 0.002])
    vein.apply_transform(rotation_matrix(angle, [0.0, 0.0, 1.0]))
    vein.apply_translation(center)
    pbr(vein, [0.08, 0.22, 0.1], metallic=0.1, roughness=0.3, name="leaf_vein")
    return pbr(blade, [0.1, 0.28, 0.12], metallic=0.12, roughness=0.28, name="curry_leaf")


def red_chili(center: tuple[float, float, float], scale: float, rot_z: float) -> list[trimesh.Trimesh]:
    parts: list[trimesh.Trimesh] = []
    segments = 8
    length = 0.12 * scale
    for i in range(segments):
        t = i / segments
        r = (0.014 * scale) * (1.0 - t * 0.55)
        seg = trimesh.creation.cylinder(radius=r, height=length / segments, sections=20)
        seg.apply_transform(rotation_matrix(np.pi / 2.15, [0.0, 1.0, 0.0]))
        seg.apply_transform(rotation_matrix(rot_z, [0.0, 0.0, 1.0]))
        seg.apply_translation(
            [
                center[0] + np.cos(rot_z) * t * length * 0.85,
                center[1] + np.sin(rot_z) * t * length * 0.85,
                center[2] + np.sin(t * np.pi) * 0.008,
            ]
        )
        color = [0.82 - t * 0.12, 0.06 + t * 0.02, 0.04]
        parts.append(pbr(seg, color, roughness=0.42, name="chili"))

    stem = trimesh.creation.cylinder(radius=0.0035 * scale, height=0.022 * scale, sections=10)
    stem.apply_translation([center[0] - 0.04 * scale, center[1], center[2] + 0.012 * scale])
    parts.append(pbr(stem, [0.22, 0.38, 0.14], roughness=0.75, name="chili_stem"))
    return parts


def cashew_nut(center: tuple[float, float, float], rot: float) -> trimesh.Trimesh:
    nut = trimesh.creation.icosphere(subdivisions=3, radius=0.024)
    nut.apply_transform(scale_xyz(0.68, 1.35, 0.48))
    nut.apply_transform(rotation_matrix(rot, [0.0, 0.0, 1.0]))
    nut.apply_translation(center)
    return pbr(nut, [0.92, 0.72, 0.4], roughness=0.58, name="cashew")


def herb_sprig(base: tuple[float, float, float], angle: float) -> list[trimesh.Trimesh]:
    parts: list[trimesh.Trimesh] = []
    for i in range(5):
        a = angle + i * 0.28
        h = 0.06 + i * 0.018
        stem = trimesh.creation.cylinder(radius=0.0018, height=h, sections=6)
        stem.apply_transform(rotation_matrix(0.35 + i * 0.06, [1.0, 0.0, 0.0]))
        stem.apply_transform(rotation_matrix(a, [0.0, 0.0, 1.0]))
        stem.apply_translation([base[0], base[1], base[2] + 0.008])
        parts.append(pbr(stem, [0.16, 0.42, 0.14], roughness=0.8, name="herb_stem"))

        for j in range(3):
            leaf = trimesh.creation.capsule(radius=0.004, height=0.018, count=[4, 4])
            leaf.apply_transform(scale_xyz(0.7, 1.6, 0.35))
            la = a + (j - 1) * 0.22
            leaf.apply_transform(rotation_matrix(0.5, [1.0, 0.0, 0.0]))
            leaf.apply_transform(rotation_matrix(la, [0.0, 0.0, 1.0]))
            leaf.apply_translation(
                [
                    base[0] + np.cos(la) * h * 0.55,
                    base[1] + np.sin(la) * h * 0.55,
                    base[2] + 0.02 + j * 0.012,
                ]
            )
            parts.append(pbr(leaf, [0.22, 0.56, 0.18], roughness=0.78, name="herb_leaf"))
    return parts


def chutney_ramekin(center: tuple[float, float, float]) -> list[trimesh.Trimesh]:
    cx, cy, cz = center
    profile = np.array(
        [
            [0.0, 0.0],
            [0.045, 0.002],
            [0.062, 0.012],
            [0.068, 0.028],
            [0.064, 0.034],
            [0.055, 0.036],
            [0.0, 0.034],
        ]
    )
    cup = revolve(profile, sections=40)
    cup.apply_translation([cx, cy, cz])
    pbr(cup, [0.95, 0.94, 0.91], roughness=0.48, name="ramekin")

    sauce = trimesh.creation.icosphere(subdivisions=3, radius=0.046)
    sauce.apply_transform(scale_xyz(1.0, 1.0, 0.38))
    sauce.apply_translation([cx, cy, cz + 0.034])
    pbr(sauce, [0.38, 0.2, 0.08], roughness=0.94, name="chutney")

    # Chunky texture lumps
    lumps: list[trimesh.Trimesh] = []
    rng = np.random.default_rng(5)
    for _ in range(6):
        lump = trimesh.creation.icosphere(subdivisions=1, radius=rng.uniform(0.006, 0.012))
        lump.apply_translation(
            [
                cx + rng.uniform(-0.035, 0.035),
                cy + rng.uniform(-0.035, 0.035),
                cz + 0.038 + rng.uniform(-0.004, 0.004),
            ]
        )
        lumps.append(pbr(lump, [0.32, 0.16, 0.06], roughness=0.96, name="chutney_lump"))
    return [cup, sauce, *lumps]


def main() -> None:
    meshes: list[trimesh.Trimesh] = []
    rng = np.random.default_rng(21)
    bowl_z = 0.08
    bowl_center = (0.04, 0.0)

    meshes.extend(wood_table())
    meshes.extend(ceramic_bowl((*bowl_center, bowl_z)))
    meshes.extend(lettuce_cluster((0.24, -0.17, bowl_z + 0.088)))
    meshes.extend(meat_slice_stack(bowl_z))
    meshes.extend(onion_rings(bowl_z))

    for pos, ang, tilt in [
        ((0.015, 0.085, bowl_z + 0.202), 0.35, 0.25),
        ((-0.042, 0.048, bowl_z + 0.198), 1.15, 0.4),
        ((0.055, -0.015, bowl_z + 0.201), 2.05, 0.18),
        ((-0.01, -0.02, bowl_z + 0.204), 2.8, 0.32),
    ]:
        meshes.append(curry_leaf_mesh(pos, ang, tilt))

    meshes.extend(red_chili((-0.015, 0.105, bowl_z + 0.205), 1.05, 0.55))
    meshes.extend(chutney_ramekin((-0.5, 0.2, bowl_z)))

    for _ in range(10):
        meshes.append(
            cashew_nut(
                (rng.uniform(-0.72, 0.72), rng.uniform(-0.5, 0.5), bowl_z + 0.001),
                rng.uniform(0, 2 * np.pi),
            )
        )

    meshes.extend(herb_sprig((-0.32, -0.32, bowl_z), 0.75))
    meshes.extend(herb_sprig((0.58, 0.32, bowl_z), 2.35))
    meshes.extend(herb_sprig((-0.58, 0.38, bowl_z), 1.55))
    meshes.extend(herb_sprig((0.35, -0.48, bowl_z), 3.8))

    meshes.extend(red_chili((0.6, -0.36, bowl_z + 0.002), 1.4, -0.35))
    meshes.extend(red_chili((-0.66, -0.26, bowl_z + 0.002), 1.25, 2.15))

    for _ in range(6):
        meshes.append(
            curry_leaf_mesh(
                (
                    rng.uniform(-0.58, 0.58),
                    rng.uniform(-0.42, 0.42),
                    bowl_z + 0.003,
                ),
                rng.uniform(0, 2 * np.pi),
                rng.uniform(0.1, 0.5),
            )
        )

    scene = trimesh.Scene(meshes)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    scene.export(str(OUTPUT))
    print(f"Wrote {OUTPUT} ({OUTPUT.stat().st_size} bytes), meshes={len(meshes)}")


if __name__ == "__main__":
    main()
