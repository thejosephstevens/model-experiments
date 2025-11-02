"""Model management commands."""

from pathlib import Path
from typing import Optional

import typer
from rich.console import Console

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

    # TODO: Implement model download
    console.print("[yellow]⚠ Download not yet implemented[/yellow]")

