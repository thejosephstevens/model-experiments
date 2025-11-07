"""Model training commands."""

import os

# Disable MPS on Apple Silicon BEFORE importing torch/transformers
# MPS backend has known issues with some loss functions
os.environ["PYTORCH_ENABLE_MPS_FALLBACK"] = "1"
os.environ["PYTORCH_MPS_PREFER_METAL"] = "0"

import hashlib
import json
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn
from datasets import Dataset
from transformers import (
    AutoModelForSequenceClassification,
    AutoTokenizer,
    TrainingArguments,
    Trainer,
    set_seed,
)

console = Console()


def load_jsonl_data(file_path: Path) -> list[dict]:
    """Load JSONL data from file."""
    data = []
    with open(file_path, "r", encoding="utf-8") as f:
        for line in f:
            if line.strip():
                data.append(json.loads(line))
    return data


def _compute_training_hash(
    model_name: str,
    epochs: int,
    batch_size: int,
    learning_rate: float,
    warmup_steps: int,
    save_steps: int,
    logging_steps: int,
    eval_steps: int,
    max_length: int,
    gradient_accumulation_steps: int,
    fp16: bool,
    seed: int,
) -> str:
    """Compute a hash of all training parameters for cache validation."""
    # Create a dictionary of all parameters
    params = {
        "model_name": model_name,
        "epochs": epochs,
        "batch_size": batch_size,
        "learning_rate": learning_rate,
        "warmup_steps": warmup_steps,
        "save_steps": save_steps,
        "logging_steps": logging_steps,
        "eval_steps": eval_steps,
        "max_length": max_length,
        "gradient_accumulation_steps": gradient_accumulation_steps,
        "fp16": fp16,
        "seed": seed,
    }
    
    # Create a stable string representation
    params_str = json.dumps(params, sort_keys=True)
    
    # Compute SHA256 hash
    return hashlib.sha256(params_str.encode()).hexdigest()


def _check_cache(
    output_dir: Path,
    model_name: str,
    train_data: Path,
    val_data: Path,
    config_hash: str,
) -> bool:
    """
    Check if a valid training cache exists.
    
    Returns True if cache is valid and can be used, False otherwise.
    """
    metadata_file = output_dir / "training_metadata.json"
    
    # Check if metadata file exists
    if not metadata_file.exists():
        return False
    
    try:
        with open(metadata_file, "r", encoding="utf-8") as f:
            metadata = json.load(f)
        
        # Check if training completed successfully
        if not metadata.get("completed", False):
            console.print("[yellow]⚠[/yellow] Previous training incomplete, re-training...")
            return False
        
        # Check if model name matches
        if metadata.get("model_name") != model_name:
            console.print(
                f"[yellow]⚠[/yellow] Cache is for different model "
                f"({metadata.get('model_name')}), training {model_name}..."
            )
            return False
        
        # Check if config hash matches
        if metadata.get("config_hash") != config_hash:
            console.print("[yellow]⚠[/yellow] Training configuration changed, re-training...")
            return False
        
        # Check if dataset paths match
        if metadata.get("train_data_path") != str(train_data):
            console.print("[yellow]⚠[/yellow] Training data path changed, re-training...")
            return False
        
        if metadata.get("val_data_path") != str(val_data):
            console.print("[yellow]⚠[/yellow] Validation data path changed, re-training...")
            return False
        
        # Check if dataset files still exist
        if not train_data.exists():
            console.print("[yellow]⚠[/yellow] Training data file no longer exists, re-training...")
            return False
        
        if not val_data.exists():
            console.print("[yellow]⚠[/yellow] Validation data file no longer exists, re-training...")
            return False
        
        # Check if dataset modification times match
        train_mtime = train_data.stat().st_mtime
        val_mtime = val_data.stat().st_mtime
        
        if metadata.get("train_data_mtime") != train_mtime:
            console.print("[yellow]⚠[/yellow] Training data has been modified, re-training...")
            return False
        
        if metadata.get("val_data_mtime") != val_mtime:
            console.print("[yellow]⚠[/yellow] Validation data has been modified, re-training...")
            return False
        
        # Check if essential model files exist
        config_file = output_dir / "config.json"
        if not config_file.exists():
            console.print("[yellow]⚠[/yellow] Model config file missing, re-training...")
            return False
        
        # Check for model weights (either safetensors or pytorch_model.bin)
        safetensors_file = output_dir / "model.safetensors"
        pytorch_file = output_dir / "pytorch_model.bin"
        
        if not safetensors_file.exists() and not pytorch_file.exists():
            console.print("[yellow]⚠[/yellow] Model weights missing, re-training...")
            return False
        
        # Cache is valid
        return True
        
    except (json.JSONDecodeError, KeyError, OSError) as e:
        console.print(f"[yellow]⚠[/yellow] Cache metadata corrupted ({str(e)}), re-training...")
        return False


def train(
    model_name: str = typer.Option(
        ...,
        "--model-name",
        help="Model to fine-tune (HuggingFace model name)",
    ),
    train_data: Path = typer.Option(
        ...,
        "--train-data",
        help="Path to training data (JSONL format)",
    ),
    val_data: Path = typer.Option(
        ...,
        "--val-data",
        help="Path to validation data (JSONL format)",
    ),
    output_dir: Path = typer.Option(
        ...,
        "--output-dir",
        help="Directory to save fine-tuned model",
    ),
    epochs: int = typer.Option(
        3,
        "--epochs",
        help="Number of training epochs",
    ),
    batch_size: int = typer.Option(
        16,
        "--batch-size",
        help="Training batch size",
    ),
    learning_rate: float = typer.Option(
        2e-5,
        "--learning-rate",
        help="Learning rate",
    ),
    warmup_steps: int = typer.Option(
        100,
        "--warmup-steps",
        help="Number of warmup steps",
    ),
    save_steps: int = typer.Option(
        500,
        "--save-steps",
        help="Save checkpoint every N steps",
    ),
    logging_steps: int = typer.Option(
        50,
        "--logging-steps",
        help="Log metrics every N steps",
    ),
    eval_steps: int = typer.Option(
        250,
        "--eval-steps",
        help="Evaluate every N steps",
    ),
    max_length: int = typer.Option(
        512,
        "--max-length",
        help="Maximum sequence length",
    ),
    gradient_accumulation_steps: int = typer.Option(
        1,
        "--gradient-accumulation-steps",
        help="Number of gradient accumulation steps",
    ),
    fp16: bool = typer.Option(
        False,
        "--fp16",
        help="Enable mixed precision training (FP16)",
    ),
    seed: int = typer.Option(
        42,
        "--seed",
        help="Random seed for reproducibility",
    ),
    force: bool = typer.Option(
        False,
        "--force",
        help="Force re-training even if model already trained with same config",
    ),
) -> None:
    """
    Fine-tune a model on training data.

    Examples:
        model-experiments train \\
            --model-name distilbert-base-uncased \\
            --train-data ./data/splits/train.jsonl \\
            --val-data ./data/splits/val.jsonl \\
            --output-dir ./models/fine-tuned \\
            --epochs 3 \\
            --batch-size 16 \\
            --fp16
    """
    console.print("[bold blue]Training Configuration[/bold blue]")
    console.print(f"[dim]Model: {model_name}[/dim]")
    console.print(f"[dim]Training data: {train_data}[/dim]")
    console.print(f"[dim]Validation data: {val_data}[/dim]")
    console.print(f"[dim]Output directory: {output_dir}[/dim]")
    console.print(f"[dim]Epochs: {epochs}[/dim]")
    console.print(f"[dim]Batch size: {batch_size}[/dim]")
    console.print(f"[dim]Learning rate: {learning_rate}[/dim]")
    console.print(f"[dim]FP16: {fp16}[/dim]")
    console.print(f"[dim]Seed: {seed}[/dim]")

    # Validate inputs
    if not train_data.exists():
        console.print(f"[red]Error: Training data not found: {train_data}[/red]")
        raise typer.Exit(1)

    if not val_data.exists():
        console.print(f"[red]Error: Validation data not found: {val_data}[/red]")
        raise typer.Exit(1)

    # Compute configuration hash for cache validation
    config_hash = _compute_training_hash(
        model_name=model_name,
        epochs=epochs,
        batch_size=batch_size,
        learning_rate=learning_rate,
        warmup_steps=warmup_steps,
        save_steps=save_steps,
        logging_steps=logging_steps,
        eval_steps=eval_steps,
        max_length=max_length,
        gradient_accumulation_steps=gradient_accumulation_steps,
        fp16=fp16,
        seed=seed,
    )
    
    # Check if training cache exists (unless force flag is set)
    if not force and output_dir.exists():
        if _check_cache(
            output_dir=output_dir,
            model_name=model_name,
            train_data=train_data,
            val_data=val_data,
            config_hash=config_hash,
        ):
            console.print("[yellow]ℹ[/yellow] Model already trained with this configuration")
            console.print(f"[dim]Using cached trained model from {output_dir}[/dim]")
            
            # Load and display cached metadata
            metadata_file = output_dir / "training_metadata.json"
            with open(metadata_file, "r", encoding="utf-8") as f:
                metadata = json.load(f)
            
            console.print(f"[dim]Training samples: {metadata.get('training_samples', 'unknown')}[/dim]")
            console.print(f"[dim]Validation samples: {metadata.get('validation_samples', 'unknown')}[/dim]")
            console.print(f"[dim]Epochs: {metadata.get('training_params', {}).get('epochs', 'unknown')}[/dim]")
            console.print("[dim]Use --force to re-train[/dim]")
            
            console.print("\n[bold green]═══════════════════════════════════════[/bold green]")
            console.print("[bold green]Using cached training result![/bold green]")
            console.print("[bold green]═══════════════════════════════════════[/bold green]")
            console.print(f"[green]✓[/green] Trained model available at: {output_dir}")
            return
    elif force:
        console.print("[dim]Force flag set, re-training even if cache exists...[/dim]")

    try:
        # Set random seed for reproducibility
        set_seed(seed)

        # Create output directory
        output_dir.mkdir(parents=True, exist_ok=True)

        console.print("\n[bold blue]Step 1/4: Loading data[/bold blue]")
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Loading training data...", total=None)
            train_data_list = load_jsonl_data(train_data)

        console.print(f"[green]✓[/green] Loaded {len(train_data_list)} training samples")

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Loading validation data...", total=None)
            val_data_list = load_jsonl_data(val_data)

        console.print(f"[green]✓[/green] Loaded {len(val_data_list)} validation samples")

        # Create datasets
        train_dataset = Dataset.from_dict({
            "text": [item.get("text", "") for item in train_data_list],
            "label": [item.get("label", 0) for item in train_data_list],
        })

        val_dataset = Dataset.from_dict({
            "text": [item.get("text", "") for item in val_data_list],
            "label": [item.get("label", 0) for item in val_data_list],
        })

        console.print("\n[bold blue]Step 2/4: Loading model and tokenizer[/bold blue]")
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Loading model from HuggingFace Hub...", total=None)
            # Get the number of unique labels
            num_labels = len(set(item.get("label", 0) for item in train_data_list))
            model = AutoModelForSequenceClassification.from_pretrained(
                model_name,
                num_labels=num_labels,
                problem_type="single_label_classification" if num_labels > 1 else None,
            )

        console.print("[green]✓[/green] Model loaded successfully")

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Loading tokenizer...", total=None)
            tokenizer = AutoTokenizer.from_pretrained(model_name)

        console.print("[green]✓[/green] Tokenizer loaded successfully")

        # Tokenize datasets
        def tokenize_function(examples: dict) -> dict:
            return tokenizer(
                examples["text"],
                padding="max_length",
                truncation=True,
                max_length=max_length,
            )

        console.print("\n[bold blue]Step 3/4: Tokenizing data[/bold blue]")
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Tokenizing training data...", total=None)
            train_dataset = train_dataset.map(tokenize_function, batched=True)

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Tokenizing validation data...", total=None)
            val_dataset = val_dataset.map(tokenize_function, batched=True)

        console.print("[green]✓[/green] Data tokenization complete")

        # Setup training arguments
        # Convert model to float32 explicitly to avoid dtype issues
        import torch
        model = model.float()  # Ensure all parameters are float32
        
        training_args = TrainingArguments(
            output_dir=str(output_dir),
            num_train_epochs=epochs,
            per_device_train_batch_size=batch_size,
            per_device_eval_batch_size=batch_size,
            warmup_steps=warmup_steps,
            save_steps=save_steps,
            logging_steps=logging_steps,
            eval_steps=eval_steps,
            learning_rate=learning_rate,
            gradient_accumulation_steps=gradient_accumulation_steps,
            fp16=False,  # Disable FP16 to avoid dtype issues
            eval_strategy="steps",
            save_strategy="steps",
            load_best_model_at_end=True,
            logging_dir=str(output_dir / "logs"),
            seed=seed,
            use_mps_device=False,  # Disable MPS due to known issues
        )

        # Create trainer
        trainer = Trainer(
            model=model,
            args=training_args,
            train_dataset=train_dataset,
            eval_dataset=val_dataset,
        )

        console.print("\n[bold blue]Step 4/4: Training model[/bold blue]")
        console.print("[dim]This may take a while depending on dataset size and hardware...[/dim]")

        # Train the model
        trainer.train()

        console.print("[green]✓[/green] Training completed successfully")

        # Save the model
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Saving model...", total=None)
            model.save_pretrained(str(output_dir))
            tokenizer.save_pretrained(str(output_dir))

        console.print("[green]✓[/green] Model and tokenizer saved")

        # Save training metadata with cache information
        train_mtime = train_data.stat().st_mtime
        val_mtime = val_data.stat().st_mtime
        
        metadata = {
            "model_name": model_name,
            "train_data_path": str(train_data),
            "train_data_mtime": train_mtime,
            "val_data_path": str(val_data),
            "val_data_mtime": val_mtime,
            "config_hash": config_hash,
            "training_params": {
                "epochs": epochs,
                "batch_size": batch_size,
                "learning_rate": learning_rate,
                "warmup_steps": warmup_steps,
                "save_steps": save_steps,
                "logging_steps": logging_steps,
                "eval_steps": eval_steps,
                "max_length": max_length,
                "gradient_accumulation_steps": gradient_accumulation_steps,
                "fp16": fp16,
                "seed": seed,
            },
            "training_samples": len(train_data_list),
            "validation_samples": len(val_data_list),
            "total_steps": len(train_dataset) // batch_size * epochs,
            "completed": True,
        }

        metadata_file = output_dir / "training_metadata.json"
        with open(metadata_file, "w", encoding="utf-8") as f:
            json.dump(metadata, f, indent=2)

        console.print("\n[bold green]═══════════════════════════════════════[/bold green]")
        console.print("[bold green]Training complete![/bold green]")
        console.print("[bold green]═══════════════════════════════════════[/bold green]")
        console.print(f"[green]✓[/green] Model saved to: {output_dir}")
        console.print(f"[green]✓[/green] Training logs: {output_dir}/logs")
        console.print(f"[green]✓[/green] Training metadata: {metadata_file}")

    except Exception as e:
        console.print(f"[red]✗ Error during training:[/red] {str(e)}")
        import traceback
        console.print(f"[red]{traceback.format_exc()}[/red]")
        raise typer.Exit(1)

