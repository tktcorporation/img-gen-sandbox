#!/usr/bin/env python3
"""
Flux2 Image Generation Script for Apple Silicon Mac
Uses MPS (Metal Performance Shaders) backend for GPU acceleration
"""

import argparse
import sys
from pathlib import Path

import torch
from diffusers import FluxPipeline
from PIL import Image


def check_device():
    """Check and return the best available device."""
    if torch.backends.mps.is_available():
        print("Using MPS (Metal Performance Shaders) backend")
        return torch.device("mps")
    elif torch.cuda.is_available():
        print("Using CUDA backend")
        return torch.device("cuda")
    else:
        print("Warning: No GPU acceleration available, using CPU (this will be slow)")
        return torch.device("cpu")


def load_pipeline(model_id: str, device: torch.device):
    """
    Load the Flux pipeline with memory optimizations.

    Args:
        model_id: Hugging Face model ID
        device: Target device (mps, cuda, or cpu)

    Returns:
        Loaded FluxPipeline
    """
    print(f"Loading model: {model_id}")
    print("This may take a while on first run (downloading model)...")

    # Load with float16 for memory efficiency
    # Note: MPS works best with float32 for some operations
    pipe = FluxPipeline.from_pretrained(
        model_id,
        torch_dtype=torch.float16,
    )

    # Enable memory optimizations
    pipe.enable_attention_slicing()

    # Enable VAE slicing for lower memory usage
    if hasattr(pipe, 'vae'):
        pipe.vae.enable_slicing()

    # Move to device
    pipe = pipe.to(device)

    print("Model loaded successfully!")
    return pipe


def generate_image(
    pipe,
    prompt: str,
    output_path: str,
    width: int = 512,
    height: int = 512,
    num_inference_steps: int = 20,
    guidance_scale: float = 3.5,
    seed: int | None = None,
):
    """
    Generate an image from a text prompt.

    Args:
        pipe: Loaded FluxPipeline
        prompt: Text description of the image to generate
        output_path: Path to save the generated image
        width: Image width (default 512 for memory efficiency)
        height: Image height (default 512 for memory efficiency)
        num_inference_steps: Number of denoising steps
        guidance_scale: How closely to follow the prompt
        seed: Random seed for reproducibility
    """
    print(f"\nGenerating image for prompt: '{prompt}'")
    print(f"Size: {width}x{height}, Steps: {num_inference_steps}")

    # Set seed for reproducibility
    generator = None
    if seed is not None:
        generator = torch.Generator().manual_seed(seed)
        print(f"Using seed: {seed}")

    # Generate image
    with torch.inference_mode():
        result = pipe(
            prompt=prompt,
            width=width,
            height=height,
            num_inference_steps=num_inference_steps,
            guidance_scale=guidance_scale,
            generator=generator,
        )

    # Save image
    image = result.images[0]
    image.save(output_path)
    print(f"\nImage saved to: {output_path}")

    return image


def main():
    parser = argparse.ArgumentParser(
        description="Generate images using Flux2 on Apple Silicon Mac"
    )
    parser.add_argument(
        "prompt",
        type=str,
        help="Text prompt describing the image to generate",
    )
    parser.add_argument(
        "-o", "--output",
        type=str,
        default="output.png",
        help="Output file path (default: output.png)",
    )
    parser.add_argument(
        "-m", "--model",
        type=str,
        default="black-forest-labs/FLUX.1-schnell",
        help="Model ID (default: FLUX.1-schnell for 16GB RAM)",
    )
    parser.add_argument(
        "--width",
        type=int,
        default=512,
        help="Image width (default: 512)",
    )
    parser.add_argument(
        "--height",
        type=int,
        default=512,
        help="Image height (default: 512)",
    )
    parser.add_argument(
        "--steps",
        type=int,
        default=4,
        help="Number of inference steps (default: 4 for schnell)",
    )
    parser.add_argument(
        "--guidance",
        type=float,
        default=0.0,
        help="Guidance scale (default: 0.0 for schnell)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=None,
        help="Random seed for reproducibility",
    )

    args = parser.parse_args()

    # Check device
    device = check_device()

    # Load pipeline
    pipe = load_pipeline(args.model, device)

    # Generate image
    generate_image(
        pipe=pipe,
        prompt=args.prompt,
        output_path=args.output,
        width=args.width,
        height=args.height,
        num_inference_steps=args.steps,
        guidance_scale=args.guidance,
        seed=args.seed,
    )

    print("\nDone!")


if __name__ == "__main__":
    main()
