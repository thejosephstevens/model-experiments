"""Model evaluation commands."""

import json
from pathlib import Path
from typing import List, Optional

import typer
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn
import numpy as np
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score
from transformers import AutoModelForSequenceClassification, AutoTokenizer, pipeline

console = Console()


def load_jsonl_data(file_path: Path) -> list[dict]:
    """Load JSONL data from file."""
    data = []
    with open(file_path, "r", encoding="utf-8") as f:
        for line in f:
            if line.strip():
                data.append(json.loads(line))
    return data


def compute_metrics(true_labels: list[int], pred_labels: list[int], requested_metrics: List[str]) -> dict:
    """Compute evaluation metrics."""
    metrics_result = {}
    
    for metric in requested_metrics:
        if metric == "accuracy":
            metrics_result["accuracy"] = float(accuracy_score(true_labels, pred_labels))
        elif metric == "f1":
            metrics_result["f1"] = float(f1_score(true_labels, pred_labels, average="weighted", zero_division=0))
        elif metric == "precision":
            metrics_result["precision"] = float(precision_score(true_labels, pred_labels, average="weighted", zero_division=0))
        elif metric == "recall":
            metrics_result["recall"] = float(recall_score(true_labels, pred_labels, average="weighted", zero_division=0))
    
    return metrics_result


def evaluate(
    model_path: Path = typer.Option(
        ...,
        "--model-path",
        help="Path to model (base or fine-tuned)",
    ),
    test_data: Path = typer.Option(
        ...,
        "--test-data",
        help="Path to test/validation data (JSONL format)",
    ),
    output_file: Path = typer.Option(
        ...,
        "--output-file",
        help="Path to save metrics (JSON format)",
    ),
    batch_size: int = typer.Option(
        32,
        "--batch-size",
        help="Batch size for inference",
    ),
    max_length: int = typer.Option(
        512,
        "--max-length",
        help="Maximum sequence length",
    ),
    metrics: List[str] = typer.Option(
        ["accuracy", "f1", "precision", "recall"],
        "--metrics",
        help="Metrics to compute (can specify multiple)",
    ),
    log_predictions: Optional[Path] = typer.Option(
        None,
        "--log-predictions",
        help="Optional path to save predictions (JSONL format)",
    ),
) -> None:
    """
    Evaluate model performance on test data.

    Examples:
        model-experiments evaluate \\
            --model-path ./models/fine-tuned \\
            --test-data ./data/splits/val.jsonl \\
            --output-file ./metrics/results.json \\
            --metrics accuracy \\
            --metrics f1 \\
            --metrics precision \\
            --metrics recall \\
            --log-predictions ./predictions/output.jsonl
    """
    console.print("[bold blue]Evaluation Configuration[/bold blue]")
    console.print(f"[dim]Model: {model_path}[/dim]")
    console.print(f"[dim]Test data: {test_data}[/dim]")
    console.print(f"[dim]Output file: {output_file}[/dim]")
    console.print(f"[dim]Batch size: {batch_size}[/dim]")
    console.print(f"[dim]Metrics: {', '.join(metrics)}[/dim]")
    if log_predictions:
        console.print(f"[dim]Predictions log: {log_predictions}[/dim]")

    # Validate inputs
    if not model_path.exists():
        console.print(f"[red]Error: Model not found: {model_path}[/red]")
        raise typer.Exit(1)

    if not test_data.exists():
        console.print(f"[red]Error: Test data not found: {test_data}[/red]")
        raise typer.Exit(1)

    try:
        # Create output directory
        output_file.parent.mkdir(parents=True, exist_ok=True)
        if log_predictions:
            log_predictions.parent.mkdir(parents=True, exist_ok=True)

        console.print("\n[bold blue]Step 1/3: Loading data[/bold blue]")
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Loading test data...", total=None)
            test_data_list = load_jsonl_data(test_data)

        console.print(f"[green]✓[/green] Loaded {len(test_data_list)} test samples")

        console.print("\n[bold blue]Step 2/3: Loading model[/bold blue]")
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Loading model from path...", total=None)
            model = AutoModelForSequenceClassification.from_pretrained(str(model_path))
            tokenizer = AutoTokenizer.from_pretrained(str(model_path))

        console.print("[green]✓[/green] Model and tokenizer loaded successfully")

        # Create text classification pipeline
        classifier = pipeline(
            "text-classification",
            model=model,
            tokenizer=tokenizer,
            device=0 if __import__("torch").cuda.is_available() else -1,
            truncation=True,
            max_length=max_length,
        )

        console.print("\n[bold blue]Step 3/3: Running inference[/bold blue]")
        console.print("[dim]This may take a while depending on dataset size...[/dim]")

        # Extract texts and true labels
        texts = [item.get("text", "") for item in test_data_list]
        true_labels = [item.get("label", 0) for item in test_data_list]

        # Run inference with progress
        predictions_list = []
        true_pred_labels = []

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            task = progress.add_task(description="Running inference...", total=len(texts))
            
            for i in range(0, len(texts), batch_size):
                batch_texts = texts[i : i + batch_size]
                batch_predictions = classifier(batch_texts, top_k=None)

                for j, (text, true_label, pred) in enumerate(zip(batch_texts, true_labels[i : i + batch_size], batch_predictions)):
                    # Get predicted label (highest score)
                    predicted_label = int(pred[0]["label"].split("_")[-1]) if "LABEL_" in pred[0]["label"] else 0
                    
                    # Try to extract label number from classification output
                    try:
                        predicted_label = int(pred[0]["label"].split("_")[-1])
                    except (ValueError, IndexError):
                        predicted_label = 0 if pred[0]["score"] < 0.5 else 1

                    true_pred_labels.append(predicted_label)

                    predictions_list.append({
                        "text": text,
                        "true_label": true_label,
                        "predicted_label": predicted_label,
                        "confidence": float(pred[0]["score"]),
                    })

                progress.update(task, advance=len(batch_texts))

        console.print("[green]✓[/green] Inference completed")

        # Compute metrics
        console.print("\n[bold blue]Computing metrics...[/bold blue]")
        computed_metrics = compute_metrics(true_labels, true_pred_labels, metrics)

        # Add metadata
        evaluation_result = {
            "model_path": str(model_path),
            "num_samples": len(test_data_list),
            "metrics": computed_metrics,
            "requested_metrics": metrics,
        }

        # Save metrics to file
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(evaluation_result, f, indent=2)

        console.print(f"[green]✓[/green] Metrics saved to {output_file}")

        # Save predictions if requested
        if log_predictions:
            with open(log_predictions, "w", encoding="utf-8") as f:
                for pred in predictions_list:
                    f.write(json.dumps(pred) + "\n")

            console.print(f"[green]✓[/green] Predictions saved to {log_predictions}")

        # Print results
        console.print("\n[bold green]═══════════════════════════════════════[/bold green]")
        console.print("[bold green]Evaluation Complete![/bold green]")
        console.print("[bold green]═══════════════════════════════════════[/bold green]")
        console.print(f"[green]✓[/green] Model: {model_path}")
        console.print(f"[green]✓[/green] Samples evaluated: {len(test_data_list)}")
        console.print(f"[green]✓[/green] Metrics computed: {', '.join(metrics)}")
        
        console.print("\n[bold blue]Metrics Results:[/bold blue]")
        for metric_name, metric_value in computed_metrics.items():
            console.print(f"  {metric_name.capitalize()}: {metric_value:.4f}")

    except Exception as e:
        console.print(f"[red]✗ Error during evaluation:[/red] {str(e)}")
        raise typer.Exit(1)

