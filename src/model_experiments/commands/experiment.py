"""End-to-end experiment workflow command."""

import json
from datetime import datetime
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn

from model_experiments.commands import compare, dataset, evaluate, model, train

console = Console()


# Training profile configurations
TRAINING_PROFILES = {
    "quick": {
        "description": "Fast testing profile with minimal samples",
        "max_samples": 100,
        "epochs": 1,
        "batch_size": 32,
        "learning_rate": 2e-5,
        "warmup_steps": 50,
        "save_steps": 500,
        "logging_steps": 50,
        "eval_steps": 250,
    },
    "default": {
        "description": "Balanced training profile for typical experiments",
        "max_samples": 1000,
        "epochs": 3,
        "batch_size": 16,
        "learning_rate": 2e-5,
        "warmup_steps": 100,
        "save_steps": 500,
        "logging_steps": 50,
        "eval_steps": 250,
    },
    "full": {
        "description": "Complete training with all available data",
        "max_samples": None,  # No limit
        "epochs": 5,
        "batch_size": 8,
        "learning_rate": 2e-5,
        "warmup_steps": 200,
        "save_steps": 1000,
        "logging_steps": 100,
        "eval_steps": 500,
    },
}


def generate_experiment_name(dataset_name: str, model_name: str) -> str:
    """
    Generate a unique experiment directory name with timestamp.
    
    Args:
        dataset_name: Name of the dataset
        model_name: Name of the model
        
    Returns:
        Experiment directory name with format: exp_<timestamp>_<dataset>_<model_short>
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    # Extract model short name (e.g., "distilbert-base-uncased" -> "distilbert-base-uncased")
    # Handle organization/model format (e.g., "prajjwal1/bert-tiny" -> "bert-tiny")
    model_short = model_name.split("/")[-1] if "/" in model_name else model_name
    # Sanitize names for directory usage
    dataset_safe = dataset_name.replace("/", "_").replace(" ", "_")
    model_safe = model_short.replace("/", "_").replace(" ", "_")
    
    return f"exp_{timestamp}_{dataset_safe}_{model_safe}"


def run_experiment(
    dataset_name: str = typer.Option(
        ...,
        "--dataset-name",
        help="Dataset name from HuggingFace Hub (e.g., 'imdb', 'ag_news')",
    ),
    model_name: str = typer.Option(
        ...,
        "--model-name",
        help="Model name from HuggingFace Hub (e.g., 'distilbert-base-uncased')",
    ),
    profile: str = typer.Option(
        "default",
        "--profile",
        help="Training profile: 'quick' (fast testing), 'default' (balanced), or 'full' (complete training)",
    ),
    output_root: Path = typer.Option(
        Path("./experiments"),
        "--output-root",
        help="Root directory for experiments (experiment subdirectory will be created)",
    ),
    cache_dir: Optional[Path] = typer.Option(
        None,
        "--cache-dir",
        help="Cache directory for HuggingFace downloads",
    ),
) -> None:
    """
    Run a complete fine-tuning experiment end-to-end.
    
    This command orchestrates the full workflow:
    1. Download dataset from HuggingFace Hub
    2. Download base model from HuggingFace Hub
    3. Fine-tune the model on training data
    4. Evaluate both base and fine-tuned models
    5. Compare performance metrics
    6. Generate comprehensive reports
    
    The experiment will be saved in a timestamped directory with organized
    subdirectories for data, models, metrics, and comparison results.
    
    Examples:
        # Quick test run with minimal data
        model-experiments run-experiment \\
            --dataset-name imdb \\
            --model-name distilbert-base-uncased \\
            --profile quick
        
        # Balanced training run (default)
        model-experiments run-experiment \\
            --dataset-name imdb \\
            --model-name distilbert-base-uncased \\
            --profile default
        
        # Full training with all data
        model-experiments run-experiment \\
            --dataset-name imdb \\
            --model-name distilbert-base-uncased \\
            --profile full \\
            --output-root ./my_experiments
    """
    # Validate profile
    if profile not in TRAINING_PROFILES:
        console.print(
            f"[red]Error: Invalid profile '{profile}'. "
            f"Must be one of: {', '.join(TRAINING_PROFILES.keys())}[/red]"
        )
        raise typer.Exit(1)
    
    # Get profile configuration
    profile_config = TRAINING_PROFILES[profile]
    
    # Display experiment header
    console.print()
    console.print(Panel.fit(
        "[bold cyan]Model Fine-Tuning Experiment[/bold cyan]\n"
        f"[dim]End-to-end workflow with automated pipeline[/dim]",
        border_style="cyan"
    ))
    console.print()
    
    # Display configuration
    console.print("[bold blue]Experiment Configuration[/bold blue]")
    console.print(f"[dim]Dataset: {dataset_name}[/dim]")
    console.print(f"[dim]Model: {model_name}[/dim]")
    console.print(f"[dim]Profile: {profile} - {profile_config['description']}[/dim]")
    console.print(f"[dim]Output root: {output_root}[/dim]")
    if cache_dir:
        console.print(f"[dim]Cache directory: {cache_dir}[/dim]")
    console.print()
    
    # Generate experiment directory
    experiment_name = generate_experiment_name(dataset_name, model_name)
    experiment_dir = output_root / experiment_name
    
    console.print(f"[bold green]Experiment ID:[/bold green] {experiment_name}")
    console.print(f"[dim]Experiment directory: {experiment_dir}[/dim]")
    console.print()
    
    # Create experiment directory structure
    data_dir = experiment_dir / "data"
    models_dir = experiment_dir / "models"
    base_model_dir = models_dir / "base"
    fine_tuned_model_dir = models_dir / "fine-tuned"
    metrics_dir = experiment_dir / "metrics"
    predictions_dir = experiment_dir / "predictions"
    comparison_dir = experiment_dir / "comparison"
    cache_subdir = experiment_dir / "cache" if not cache_dir else cache_dir
    
    try:
        # =============================================================================
        # Step 1: Download Dataset
        # =============================================================================
        console.print("[bold cyan]═══════════════════════════════════════[/bold cyan]")
        console.print("[bold cyan]Step 1/6: Downloading Dataset[/bold cyan]")
        console.print("[bold cyan]═══════════════════════════════════════[/bold cyan]")
        console.print()
        
        dataset.download(
            name=dataset_name,
            output_dir=data_dir,
            max_samples=profile_config["max_samples"],
            cache_dir=cache_subdir,
            force=False,
        )
        
        console.print()
        
        # =============================================================================
        # Step 2: Download Base Model
        # =============================================================================
        console.print("[bold cyan]═══════════════════════════════════════[/bold cyan]")
        console.print("[bold cyan]Step 2/6: Downloading Base Model[/bold cyan]")
        console.print("[bold cyan]═══════════════════════════════════════[/bold cyan]")
        console.print()
        
        model.download(
            name=model_name,
            output_dir=base_model_dir,
            cache_dir=cache_subdir,
            force=False,
        )
        
        console.print()
        
        # =============================================================================
        # Step 3: Fine-tune Model
        # =============================================================================
        console.print("[bold cyan]═══════════════════════════════════════[/bold cyan]")
        console.print("[bold cyan]Step 3/6: Fine-tuning Model[/bold cyan]")
        console.print("[bold cyan]═══════════════════════════════════════[/bold cyan]")
        console.print()
        
        train_data_file = data_dir / "train" / "data.jsonl"
        # Try test split first, fallback to validation if test doesn't exist
        test_data_file = data_dir / "test" / "data.jsonl"
        if not test_data_file.exists():
            test_data_file = data_dir / "validation" / "data.jsonl"
        
        train.train(
            model_name=model_name,
            train_data=train_data_file,
            val_data=test_data_file,
            output_dir=fine_tuned_model_dir,
            epochs=profile_config["epochs"],
            batch_size=profile_config["batch_size"],
            learning_rate=profile_config["learning_rate"],
            warmup_steps=profile_config["warmup_steps"],
            save_steps=profile_config["save_steps"],
            logging_steps=profile_config["logging_steps"],
            eval_steps=profile_config["eval_steps"],
            max_length=512,
            gradient_accumulation_steps=2,
            fp16=False,
            seed=42,
        )
        
        console.print()
        
        # =============================================================================
        # Step 4: Evaluate Base Model
        # =============================================================================
        console.print("[bold cyan]═══════════════════════════════════════[/bold cyan]")
        console.print("[bold cyan]Step 4/6: Evaluating Base Model[/bold cyan]")
        console.print("[bold cyan]═══════════════════════════════════════[/bold cyan]")
        console.print()
        
        base_metrics_file = metrics_dir / "base_model_metrics.json"
        base_predictions_file = predictions_dir / "base_predictions.jsonl"
        
        evaluate.evaluate(
            model_path=base_model_dir,
            test_data=test_data_file,
            output_file=base_metrics_file,
            batch_size=32,
            max_length=512,
            metrics=["accuracy", "f1", "precision", "recall"],
            log_predictions=base_predictions_file,
        )
        
        console.print()
        
        # =============================================================================
        # Step 5: Evaluate Fine-tuned Model
        # =============================================================================
        console.print("[bold cyan]═══════════════════════════════════════[/bold cyan]")
        console.print("[bold cyan]Step 5/6: Evaluating Fine-tuned Model[/bold cyan]")
        console.print("[bold cyan]═══════════════════════════════════════[/bold cyan]")
        console.print()
        
        fine_tuned_metrics_file = metrics_dir / "fine_tuned_metrics.json"
        fine_tuned_predictions_file = predictions_dir / "fine_tuned_predictions.jsonl"
        
        evaluate.evaluate(
            model_path=fine_tuned_model_dir,
            test_data=test_data_file,
            output_file=fine_tuned_metrics_file,
            batch_size=32,
            max_length=512,
            metrics=["accuracy", "f1", "precision", "recall"],
            log_predictions=fine_tuned_predictions_file,
        )
        
        console.print()
        
        # =============================================================================
        # Step 6: Compare Models
        # =============================================================================
        console.print("[bold cyan]═══════════════════════════════════════[/bold cyan]")
        console.print("[bold cyan]Step 6/6: Comparing Model Performance[/bold cyan]")
        console.print("[bold cyan]═══════════════════════════════════════[/bold cyan]")
        console.print()
        
        compare.compare(
            baseline_metrics=base_metrics_file,
            fine_tuned_metrics=fine_tuned_metrics_file,
            output_dir=comparison_dir,
            generate_plots_flag=True,
            format="table",
            save_report=True,
        )
        
        console.print()
        
        # =============================================================================
        # Save Experiment Metadata
        # =============================================================================
        experiment_metadata = {
            "experiment_id": experiment_name,
            "dataset_name": dataset_name,
            "model_name": model_name,
            "profile": profile,
            "profile_config": profile_config,
            "timestamp": datetime.now().isoformat(),
            "directories": {
                "experiment_root": str(experiment_dir),
                "data": str(data_dir),
                "base_model": str(base_model_dir),
                "fine_tuned_model": str(fine_tuned_model_dir),
                "metrics": str(metrics_dir),
                "predictions": str(predictions_dir),
                "comparison": str(comparison_dir),
            },
            "files": {
                "base_metrics": str(base_metrics_file),
                "fine_tuned_metrics": str(fine_tuned_metrics_file),
                "base_predictions": str(base_predictions_file),
                "fine_tuned_predictions": str(fine_tuned_predictions_file),
                "comparison_report": str(comparison_dir / "report.html"),
            },
        }
        
        metadata_file = experiment_dir / "experiment_metadata.json"
        with open(metadata_file, "w", encoding="utf-8") as f:
            json.dump(experiment_metadata, f, indent=2)
        
        # =============================================================================
        # Final Summary
        # =============================================================================
        console.print()
        console.print("[bold green]═══════════════════════════════════════[/bold green]")
        console.print("[bold green]✓ Experiment Complete![/bold green]")
        console.print("[bold green]═══════════════════════════════════════[/bold green]")
        console.print()
        console.print("[bold blue]Results Summary:[/bold blue]")
        console.print(f"  • Experiment ID: [cyan]{experiment_name}[/cyan]")
        console.print(f"  • Experiment directory: [cyan]{experiment_dir}[/cyan]")
        console.print()
        console.print("[bold blue]Key Outputs:[/bold blue]")
        console.print(f"  • Base model metrics: {base_metrics_file}")
        console.print(f"  • Fine-tuned metrics: {fine_tuned_metrics_file}")
        console.print(f"  • Comparison report: {comparison_dir / 'report.html'}")
        console.print(f"  • Experiment metadata: {metadata_file}")
        console.print()
        console.print("[bold blue]Next Steps:[/bold blue]")
        console.print(f"  • View metrics: cat {base_metrics_file}")
        console.print(f"  • View comparison: open {comparison_dir / 'report.html'}")
        console.print(f"  • Use fine-tuned model: {fine_tuned_model_dir}")
        console.print()
        
    except Exception as e:
        console.print()
        console.print("[bold red]═══════════════════════════════════════[/bold red]")
        console.print("[bold red]✗ Experiment Failed[/bold red]")
        console.print("[bold red]═══════════════════════════════════════[/bold red]")
        console.print(f"[red]Error: {str(e)}[/red]")
        console.print()
        console.print("[dim]Partial results may be available in:[/dim]")
        console.print(f"[dim]{experiment_dir}[/dim]")
        console.print()
        raise typer.Exit(1)

