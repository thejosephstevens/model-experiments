"""Dataset management commands."""

import json
from pathlib import Path
from typing import Optional

import typer
from datasets import load_dataset
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

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

    try:
        # Create output directory if it doesn't exist
        output_dir.mkdir(parents=True, exist_ok=True)

        # Set cache directory if provided
        cache_kwargs = {}
        if cache_dir:
            cache_dir.mkdir(parents=True, exist_ok=True)
            cache_kwargs["cache_dir"] = str(cache_dir)

        # Download dataset with progress indicator
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Fetching dataset from HuggingFace Hub...", total=None)

            # Load dataset from HuggingFace Hub
            dataset = load_dataset(name, **cache_kwargs)

        console.print("[green]✓[/green] Dataset downloaded successfully")

        # Process each split in the dataset
        total_samples = 0
        for split_name, split_data in dataset.items():
            # Limit samples if max_samples is specified
            if max_samples and len(split_data) > max_samples:
                split_data = split_data.select(range(max_samples))
                console.print(
                    f"[dim]  Split '{split_name}': Limited to {max_samples} samples[/dim]"
                )
            else:
                console.print(f"[dim]  Split '{split_name}': {len(split_data)} samples[/dim]")

            # Save split to disk
            split_output_path = output_dir / split_name
            split_output_path.mkdir(parents=True, exist_ok=True)

            # Save as JSON Lines format for easy reading
            output_file = split_output_path / "data.jsonl"
            with open(output_file, "w", encoding="utf-8") as f:
                for example in split_data:
                    f.write(json.dumps(example) + "\n")

            total_samples += len(split_data)

        # Save dataset metadata
        metadata = {
            "name": name,
            "total_samples": total_samples,
            "splits": list(dataset.keys()),
            "max_samples": max_samples,
        }
        metadata_file = output_dir / "metadata.json"
        with open(metadata_file, "w", encoding="utf-8") as f:
            json.dump(metadata, f, indent=2)

        console.print(f"[green]✓[/green] Dataset saved to {output_dir}")
        console.print(f"[dim]Total samples: {total_samples}[/dim]")

    except Exception as e:
        console.print(f"[red]✗ Error downloading dataset:[/red] {str(e)}")
        raise typer.Exit(1)


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

