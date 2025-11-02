"""Dataset management commands."""

from pathlib import Path
from typing import Optional

import typer
from rich.console import Console

app = typer.Typer(help="Dataset management commands")
console = Console()


@app.command()
def download(
    name: str = typer.Option(
        ...,
        "--name",
        help="Dataset name from HuggingFace Hub (e.g., 'imdb', 'ag_news')",
    ),
    output_dir: Path = typer.Option(
        ...,
        "--output-dir",
        help="Directory to save the downloaded dataset",
    ),
    max_samples: Optional[int] = typer.Option(
        None,
        "--max-samples",
        help="Maximum number of samples to download (useful for testing)",
    ),
    cache_dir: Optional[Path] = typer.Option(
        None,
        "--cache-dir",
        help="HuggingFace cache directory",
    ),
) -> None:
    """
    Download a dataset from HuggingFace Hub.

    Examples:
        model-experiments dataset download --name imdb --output-dir ./data

        model-experiments dataset download --name ag_news --output-dir ./data --max-samples 1000
    """
    console.print(f"[bold blue]Downloading dataset:[/bold blue] {name}")
    console.print(f"[dim]Output directory: {output_dir}[/dim]")
    if max_samples:
        console.print(f"[dim]Max samples: {max_samples}[/dim]")

    # TODO: Implement dataset download
    console.print("[yellow]⚠ Download not yet implemented[/yellow]")


@app.command()
def split(
    input_path: Path = typer.Option(
        ...,
        "--input-path",
        help="Path to the downloaded dataset",
    ),
    output_dir: Path = typer.Option(
        ...,
        "--output-dir",
        help="Directory to save train/validation splits",
    ),
    train_ratio: float = typer.Option(
        ...,
        "--train-ratio",
        help="Proportion of data for training (e.g., 0.9)",
    ),
    val_ratio: float = typer.Option(
        ...,
        "--val-ratio",
        help="Proportion of data for validation (e.g., 0.1)",
    ),
    seed: int = typer.Option(
        42,
        "--seed",
        help="Random seed for reproducibility",
    ),
    stratify: bool = typer.Option(
        False,
        "--stratify",
        help="Enable stratified splitting (maintains class distribution)",
    ),
) -> None:
    """
    Split dataset into training and validation sets.

    Examples:
        model-experiments dataset split \\
            --input-path ./data/imdb \\
            --output-dir ./data/splits \\
            --train-ratio 0.9 \\
            --val-ratio 0.1 \\
            --stratify
    """
    console.print("[bold blue]Splitting dataset[/bold blue]")
    console.print(f"[dim]Input: {input_path}[/dim]")
    console.print(f"[dim]Output: {output_dir}[/dim]")
    console.print(f"[dim]Train/Val ratio: {train_ratio}/{val_ratio}[/dim]")
    console.print(f"[dim]Seed: {seed}[/dim]")
    if stratify:
        console.print("[dim]Stratified: Yes[/dim]")

    # Validate ratios
    if not (0 < train_ratio < 1 and 0 < val_ratio < 1):
        console.print("[red]Error: Ratios must be between 0 and 1[/red]")
        raise typer.Exit(1)

    if abs((train_ratio + val_ratio) - 1.0) > 0.001:
        console.print("[red]Error: Train and validation ratios must sum to 1.0[/red]")
        raise typer.Exit(1)

    # TODO: Implement dataset splitting
    console.print("[yellow]⚠ Split not yet implemented[/yellow]")

