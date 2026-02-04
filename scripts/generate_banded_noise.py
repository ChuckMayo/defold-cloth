#!/usr/bin/env python3
"""
Generate a seamless tileable banded noise texture for cloth simulation.
Creates horizontal bands by stretching noise on Y axis.
"""

import numpy as np
from PIL import Image
import os

def generate_seamless_noise(size=256, octaves=4, persistence=0.5, seed=42):
    """Generate seamless tileable Perlin-like noise."""
    np.random.seed(seed)

    # Generate multiple octaves of noise
    noise = np.zeros((size, size))
    amplitude = 1.0
    frequency = 1

    for _ in range(octaves):
        # Generate random gradients at grid points
        grid_size = frequency
        angles = np.random.uniform(0, 2 * np.pi, (grid_size + 1, grid_size + 1))

        # Make seamless by wrapping edges
        angles[grid_size, :] = angles[0, :]
        angles[:, grid_size] = angles[:, 0]

        # Generate gradient vectors
        gx = np.cos(angles)
        gy = np.sin(angles)

        # Calculate noise for this octave
        for y in range(size):
            for x in range(size):
                # Position within the grid
                px = (x / size) * grid_size
                py = (y / size) * grid_size

                # Grid cell coordinates
                x0 = int(px) % grid_size
                y0 = int(py) % grid_size
                x1 = (x0 + 1) % (grid_size + 1)
                y1 = (y0 + 1) % (grid_size + 1)

                # Local position within cell
                fx = px - int(px)
                fy = py - int(py)

                # Smoothstep interpolation
                sx = fx * fx * (3 - 2 * fx)
                sy = fy * fy * (3 - 2 * fy)

                # Dot products with gradient vectors
                n00 = gx[y0, x0] * fx + gy[y0, x0] * fy
                n10 = gx[y0, x1] * (fx - 1) + gy[y0, x1] * fy
                n01 = gx[y1, x0] * fx + gy[y1, x0] * (fy - 1)
                n11 = gx[y1, x1] * (fx - 1) + gy[y1, x1] * (fy - 1)

                # Bilinear interpolation
                nx0 = n00 * (1 - sx) + n10 * sx
                nx1 = n01 * (1 - sx) + n11 * sx
                value = nx0 * (1 - sy) + nx1 * sy

                noise[y, x] += value * amplitude

        amplitude *= persistence
        frequency *= 2

    # Normalize to 0-1 range
    noise = (noise - noise.min()) / (noise.max() - noise.min() + 1e-8)
    return noise


def generate_banded_noise_texture(
    output_path,
    size=256,
    band_stretch=8.0,  # How much to stretch horizontally (creates horizontal bands)
    softness=0.7,
    seed=42
):
    """
    Generate a banded noise texture with horizontal bands.

    Args:
        output_path: Where to save the PNG
        size: Output texture size (square)
        band_stretch: Aspect ratio stretch (higher = more elongated horizontal bands)
        softness: Smoothstep softness for band transitions
        seed: Random seed for reproducibility
    """
    # Generate base seamless noise at higher resolution for sampling
    base_size = size * 2
    base_noise = generate_seamless_noise(base_size, octaves=4, persistence=0.5, seed=seed)

    # Sample with stretched UVs to create horizontal bands
    # stretch Y coordinate = horizontal bands (thin on Y, full on X)
    output = np.zeros((size, size))

    for y in range(size):
        for x in range(size):
            # UV coordinates (0-1)
            u = x / size
            v = y / size

            # Stretch V coordinate (compress Y) to create horizontal bands
            # Higher band_stretch = more elongated horizontal bands
            stretched_v = (v * band_stretch) % 1.0

            # Sample from base noise
            sample_x = int(u * (base_size - 1))
            sample_y = int(stretched_v * (base_size - 1))

            output[y, x] = base_noise[sample_y, sample_x]

    # Apply smoothstep for softer transitions
    if softness > 0:
        output = output * output * (3 - 2 * output) * softness + output * (1 - softness)

    # Add a second layer with different stretch for more organic look
    second_layer = np.zeros((size, size))
    second_stretch = band_stretch * 0.6  # Different stretch for variation

    for y in range(size):
        for x in range(size):
            u = x / size
            v = y / size
            stretched_v = (v * second_stretch + 0.37) % 1.0  # Offset for variation

            sample_x = int(u * (base_size - 1))
            sample_y = int(stretched_v * (base_size - 1))

            second_layer[y, x] = base_noise[(sample_y + base_size // 3) % base_size, sample_x]

    # Blend layers
    output = output * 0.7 + second_layer * 0.3

    # Normalize again
    output = (output - output.min()) / (output.max() - output.min() + 1e-8)

    # Convert to 8-bit grayscale
    output_8bit = (output * 255).astype(np.uint8)

    # Create and save image
    img = Image.fromarray(output_8bit, mode='L')
    img.save(output_path)

    print(f"Generated banded noise texture: {output_path}")
    print(f"  Size: {size}x{size}")
    print(f"  Band stretch: {band_stretch}x")
    print(f"  Value range: {output_8bit.min()}-{output_8bit.max()}")

    return output_path


if __name__ == "__main__":
    # Output path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    output_path = os.path.join(project_dir, "cloth", "textures", "banded_noise.png")

    # Generate the texture
    generate_banded_noise_texture(
        output_path=output_path,
        size=256,
        band_stretch=8.0,  # Creates elongated horizontal bands
        softness=0.6,
        seed=42
    )
