"""Model management commands."""

import json
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn
from transformers import AutoModelForSequenceClassification, AutoTokenizer

app = typer.Typer(help="Model management commands")
console = Console()


@app.command()
def download(
    name: str = typer.Option(
        ...,
        "--name",
        help="Model name from HuggingFace Hub (e.g., 'bert-base-uncased')",
    ),
    output_dir: Path = typer.Option(
        ...,
        "--output-dir",
        help="Directory to save the downloaded model",
    ),
    cache_dir: Optional[Path] = typer.Option(
        None,
        "--cache-dir",
        help="HuggingFace cache directory",
    ),
) -> None:
    """
    Download a pre-trained model from HuggingFace Hub.

    Examples:
        model-experiments model download \\
            --name distilbert-base-uncased \\
            --output-dir ./models/base

        model-experiments model download \\
            --name bert-base-uncased \\
            --output-dir ./models/base \\
            --cache-dir ./cache
    """
    console.print(f"[bold blue]Downloading model:[/bold blue] {name}")
    console.print(f"[dim]Output directory: {output_dir}[/dim]")
    if cache_dir:
        console.print(f"[dim]Cache directory: {cache_dir}[/dim]")

    try:
        # Create output directory if it doesn't exist
        output_dir.mkdir(parents=True, exist_ok=True)

        # Set cache directory if provided
        cache_kwargs = {}
        if cache_dir:
            cache_dir.mkdir(parents=True, exist_ok=True)
            cache_kwargs["cache_dir"] = str(cache_dir)

        # Download model with progress indicator
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Downloading model from HuggingFace Hub...", total=None)

            # Load and save model with classification head
            # Using num_labels=2 for binary classification (common use case)
            model = AutoModelForSequenceClassification.from_pretrained(name, num_labels=2, **cache_kwargs)
            model.save_pretrained(str(output_dir))

        console.print("[green]✓[/green] Model downloaded successfully")

        # Download and save tokenizer
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Downloading tokenizer from HuggingFace Hub...", total=None)

            tokenizer = AutoTokenizer.from_pretrained(name, **cache_kwargs)
            tokenizer.save_pretrained(str(output_dir))

        console.print("[green]✓[/green] Tokenizer downloaded successfully")

        # Save metadata
        metadata = {
            "name": name,
            "model_type": "transformers",
            "saved_path": str(output_dir),
            "cache_dir": str(cache_dir) if cache_dir else None,
        }
        metadata_file = output_dir / "model_metadata.json"
        with open(metadata_file, "w", encoding="utf-8") as f:
            json.dump(metadata, f, indent=2)

        console.print(f"[green]✓[/green] Model and tokenizer saved to {output_dir}")
        console.print(f"[dim]Metadata saved to {metadata_file}[/dim]")

    except Exception as e:
        console.print(f"[red]✗ Error downloading model:[/red] {str(e)}")
        raise typer.Exit(1)

