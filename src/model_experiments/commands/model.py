"""Model management commands."""

import json
import subprocess
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
    force: bool = typer.Option(
        False,
        "--force",
        help="Force re-download even if model already exists",
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

        model-experiments model download \\
            --name bert-base-uncased \\
            --output-dir ./models/base \\
            --force
    """
    console.print(f"[bold blue]Downloading model:[/bold blue] {name}")
    console.print(f"[dim]Output directory: {output_dir}[/dim]")
    if cache_dir:
        console.print(f"[dim]Cache directory: {cache_dir}[/dim]")

    try:
        # Create output directory if it doesn't exist
        output_dir.mkdir(parents=True, exist_ok=True)

        # Check if model already exists (unless force flag is set)
        metadata_file = output_dir / "model_metadata.json"
        if not force and metadata_file.exists():
            try:
                with open(metadata_file, "r", encoding="utf-8") as f:
                    metadata = json.load(f)
                
                # Verify the cached model is for the same model name
                if metadata.get("name") == name:
                    # Check if essential files exist
                    config_file = output_dir / "config.json"
                    if config_file.exists():
                        console.print("[yellow]ℹ[/yellow] Model already downloaded and cached")
                        console.print(f"[dim]Using cached model from {output_dir}[/dim]")
                        console.print("[dim]Use --force to re-download[/dim]")
                        return
                    else:
                        console.print("[yellow]⚠[/yellow] Cache incomplete, re-downloading...")
                else:
                    console.print(f"[yellow]⚠[/yellow] Cache is for different model ({metadata.get('name')}), downloading {name}...")
            except (json.JSONDecodeError, KeyError) as e:
                console.print(f"[yellow]⚠[/yellow] Cache metadata corrupted, re-downloading...")
        elif force:
            console.print("[dim]Force flag set, re-downloading...[/dim]")

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


@app.command()
def upload(
    model_dir: Path = typer.Option(
        ...,
        "--model-dir",
        help="Directory containing the model files to upload",
    ),
    repo_id: str = typer.Option(
        ...,
        "--repo-id",
        help="HuggingFace Hub repository ID (e.g., 'username/model-name')",
    ),
    commit_message: Optional[str] = typer.Option(
        None,
        "--commit-message",
        "-m",
        help="Commit message for the upload",
    ),
    private: bool = typer.Option(
        False,
        "--private",
        help="Make the repository private",
    ),
) -> None:
    """
    Upload a model to HuggingFace Hub using the HF CLI.

    Requires the 'huggingface-hub' package and HF CLI to be installed.
    You must also be logged in via 'huggingface-cli login'.

    Examples:
        model-experiments model upload \\
            --model-dir ./models/fine-tuned \\
            --repo-id my-username/my-model

        model-experiments model upload \\
            --model-dir ./models/fine-tuned \\
            --repo-id my-username/my-model \\
            --commit-message "v1.0: Initial fine-tuned model"

        model-experiments model upload \\
            --model-dir ./models/fine-tuned \\
            --repo-id my-username/my-model \\
            --private
    """
    console.print(f"[bold blue]Uploading model:[/bold blue] {model_dir}")
    console.print(f"[dim]Repository: {repo_id}[/dim]")

    try:
        # Verify model directory exists
        if not model_dir.exists():
            console.print(f"[red]✗ Error:[/red] Model directory does not exist: {model_dir}")
            raise typer.Exit(1)

        if not model_dir.is_dir():
            console.print(f"[red]✗ Error:[/red] Path is not a directory: {model_dir}")
            raise typer.Exit(1)

        # Check for required model files
        required_files = ["config.json"]
        missing_files = [f for f in required_files if not (model_dir / f).exists()]
        if missing_files:
            console.print(f"[yellow]⚠[/yellow] Missing files: {', '.join(missing_files)}")
            console.print(f"[dim]Model directory may not contain a valid model[/dim]")

        # Build the hf upload command
        cmd = ["hf", "upload", repo_id, str(model_dir)]

        if commit_message:
            cmd.extend(["--commit-message", commit_message])

        if private:
            cmd.append("--private")

        console.print(f"[dim]Running command: {' '.join(cmd)}[/dim]")

        # Execute the upload command
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Uploading model to HuggingFace Hub...", total=None)

            result = subprocess.run(
                cmd,
                capture_output=False,
                text=True,
                check=False,
            )

        if result.returncode != 0:
            console.print(f"[red]✗ Upload failed[/red]")
            console.print("[dim]Make sure you are logged in with 'huggingface-cli login'[/dim]")
            raise typer.Exit(result.returncode)

        console.print("[green]✓[/green] Model uploaded successfully to HuggingFace Hub")
        console.print(f"[dim]Repository URL: https://huggingface.co/{repo_id}[/dim]")

    except FileNotFoundError:
        console.print("[red]✗ Error:[/red] 'hf' CLI not found")
        console.print("[dim]Install it with: pip install huggingface-hub[cli][/dim]")
        raise typer.Exit(1)
    except Exception as e:
        console.print(f"[red]✗ Error uploading model:[/red] {str(e)}")
        raise typer.Exit(1)

