"""Model comparison commands."""

import json
from pathlib import Path
from typing import Any

import typer
from rich.console import Console
from rich.table import Table
from rich.progress import Progress, SpinnerColumn, TextColumn

console = Console()


def load_metrics(metrics_file: Path) -> dict[str, Any]:
    """Load metrics from a JSON file."""
    with open(metrics_file, "r", encoding="utf-8") as f:
        return json.load(f)  # type: ignore[no-any-return]


def calculate_differences(
    baseline: dict[str, Any], fine_tuned: dict[str, Any]
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Calculate the differences between baseline and fine-tuned metrics."""
    baseline_metrics = baseline.get("metrics", {})
    fine_tuned_metrics = fine_tuned.get("metrics", {})
    
    differences: dict[str, Any] = {}
    improvements: dict[str, Any] = {}
    
    for metric_name in baseline_metrics.keys():
        if metric_name in fine_tuned_metrics:
            baseline_value = baseline_metrics[metric_name]
            fine_tuned_value = fine_tuned_metrics[metric_name]
            
            diff = fine_tuned_value - baseline_value
            differences[metric_name] = {
                "baseline": baseline_value,
                "fine_tuned": fine_tuned_value,
                "absolute_diff": diff,
                "percent_change": (diff / baseline_value * 100) if baseline_value != 0 else 0,
            }
            
            # Track improvements (positive changes)
            if diff > 0:
                improvements[metric_name] = differences[metric_name]
    
    return differences, improvements


def format_as_table(baseline: dict[str, Any], fine_tuned: dict[str, Any], 
                    differences: dict[str, Any]) -> None:
    """Display comparison as a formatted table."""
    table = Table(title="Model Performance Comparison", show_header=True, header_style="bold magenta")
    
    table.add_column("Metric", style="cyan")
    table.add_column("Baseline", justify="right", style="yellow")
    table.add_column("Fine-Tuned", justify="right", style="green")
    table.add_column("Difference", justify="right")
    table.add_column("% Change", justify="right")
    
    for metric_name, values in differences.items():
        baseline_val = values["baseline"]
        fine_tuned_val = values["fine_tuned"]
        abs_diff = values["absolute_diff"]
        pct_change = values["percent_change"]
        
        # Color code the difference
        if abs_diff > 0:
            diff_color = "[green]"
            diff_end = "[/green]"
        elif abs_diff < 0:
            diff_color = "[red]"
            diff_end = "[/red]"
        else:
            diff_color = "[yellow]"
            diff_end = "[/yellow]"
        
        table.add_row(
            metric_name.capitalize(),
            f"{baseline_val:.4f}",
            f"{fine_tuned_val:.4f}",
            f"{diff_color}{abs_diff:+.4f}{diff_end}",
            f"{diff_color}{pct_change:+.2f}%{diff_end}",
        )
    
    console.print(table)


def format_as_json(baseline: dict[str, Any], fine_tuned: dict[str, Any], 
                   differences: dict[str, Any], output_file: Path) -> None:
    """Save comparison as JSON."""
    comparison_result = {
        "baseline": baseline,
        "fine_tuned": fine_tuned,
        "comparison": {
            metric_name: {
                "baseline": values["baseline"],
                "fine_tuned": values["fine_tuned"],
                "absolute_diff": values["absolute_diff"],
                "percent_change": values["percent_change"],
            }
            for metric_name, values in differences.items()
        },
    }
    
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(comparison_result, f, indent=2)


def generate_html_report(baseline: dict[str, Any], fine_tuned: dict[str, Any],
                        differences: dict[str, Any], improvements: dict[str, Any],
                        output_file: Path) -> None:
    """Generate an HTML report with the comparison."""
    # Calculate summary statistics
    total_metrics = len(differences)
    improved_metrics = len(improvements)
    
    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Model Comparison Report</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }}
        
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            overflow: hidden;
        }}
        
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }}
        
        .header h1 {{
            font-size: 2.5em;
            margin-bottom: 10px;
        }}
        
        .header p {{
            font-size: 1.1em;
            opacity: 0.9;
        }}
        
        .summary {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            padding: 30px;
            background: #f8f9fa;
            border-bottom: 2px solid #e0e0e0;
        }}
        
        .summary-card {{
            background: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }}
        
        .summary-card h3 {{
            color: #667eea;
            font-size: 2em;
            margin-bottom: 10px;
        }}
        
        .summary-card p {{
            color: #666;
            font-size: 0.95em;
        }}
        
        .content {{
            padding: 40px;
        }}
        
        .section {{
            margin-bottom: 40px;
        }}
        
        .section h2 {{
            color: #333;
            margin-bottom: 20px;
            font-size: 1.5em;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
        }}
        
        table {{
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
        }}
        
        th {{
            background: #667eea;
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
        }}
        
        td {{
            padding: 12px 15px;
            border-bottom: 1px solid #e0e0e0;
        }}
        
        tr:hover {{
            background: #f8f9fa;
        }}
        
        .positive {{
            color: #27ae60;
            font-weight: bold;
        }}
        
        .negative {{
            color: #e74c3c;
            font-weight: bold;
        }}
        
        .neutral {{
            color: #95a5a6;
        }}
        
        .metric-name {{
            font-weight: 600;
            color: #333;
        }}
        
        .footer {{
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            border-top: 1px solid #e0e0e0;
            font-size: 0.9em;
        }}
        
        .progress-bar {{
            display: inline-block;
            background: #e0e0e0;
            height: 20px;
            border-radius: 10px;
            overflow: hidden;
            width: 100px;
            vertical-align: middle;
        }}
        
        .progress-fill {{
            background: linear-gradient(90deg, #27ae60, #2ecc71);
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 0.75em;
            font-weight: bold;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎯 Model Performance Comparison Report</h1>
            <p>Baseline vs Fine-Tuned Model Analysis</p>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <h3>{improved_metrics}/{total_metrics}</h3>
                <p>Metrics Improved</p>
            </div>
            <div class="summary-card">
                <h3>{baseline.get('num_samples', 'N/A')}</h3>
                <p>Samples Evaluated</p>
            </div>
            <div class="summary-card">
                <h3>{baseline['model_path']}</h3>
                <p>Baseline Model</p>
            </div>
            <div class="summary-card">
                <h3>{fine_tuned['model_path']}</h3>
                <p>Fine-Tuned Model</p>
            </div>
        </div>
        
        <div class="content">
            <div class="section">
                <h2>📊 Detailed Metrics Comparison</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Metric</th>
                            <th>Baseline</th>
                            <th>Fine-Tuned</th>
                            <th>Difference</th>
                            <th>Change %</th>
                        </tr>
                    </thead>
                    <tbody>
"""
    
    for metric_name, values in differences.items():
        baseline_val = values["baseline"]
        fine_tuned_val = values["fine_tuned"]
        abs_diff = values["absolute_diff"]
        pct_change = values["percent_change"]
        
        # Determine styling based on improvement
        if abs_diff > 0:
            diff_class = "positive"
        elif abs_diff < 0:
            diff_class = "negative"
        else:
            diff_class = "neutral"
        
        html_content += f"""                        <tr>
                            <td class="metric-name">{metric_name.capitalize()}</td>
                            <td>{baseline_val:.4f}</td>
                            <td>{fine_tuned_val:.4f}</td>
                            <td class="{diff_class}">{abs_diff:+.4f}</td>
                            <td class="{diff_class}">{pct_change:+.2f}%</td>
                        </tr>
"""
    
    html_content += """                    </tbody>
                </table>
            </div>
        </div>
        
        <div class="footer">
            <p>Generated by Model Experiments Framework</p>
        </div>
    </div>
</body>
</html>
"""
    
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(html_content)


def generate_visualization_plots(differences: dict[str, Any], output_dir: Path) -> None:
    """Generate visualization plots (stub for potential future enhancement with matplotlib)."""
    try:
        import matplotlib.pyplot as plt  # type: ignore[import-not-found]
        import numpy as np  # type: ignore[import-not-found]
        
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Extract data for plotting
        metrics = list(differences.keys())
        baseline_values = [differences[m]["baseline"] for m in metrics]
        fine_tuned_values = [differences[m]["fine_tuned"] for m in metrics]
        
        # Create comparison bar chart
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))  # type: ignore[attr-defined]
        
        # Bar chart comparing metrics
        x = np.arange(len(metrics))  # type: ignore[attr-defined]
        width = 0.35
        
        ax1.bar(x - width/2, baseline_values, width, label="Baseline", color="#ff9999")  # type: ignore[attr-defined]
        ax1.bar(x + width/2, fine_tuned_values, width, label="Fine-Tuned", color="#66bb6a")  # type: ignore[attr-defined]
        ax1.set_xlabel("Metrics")  # type: ignore[attr-defined]
        ax1.set_ylabel("Score")  # type: ignore[attr-defined]
        ax1.set_title("Metrics Comparison: Baseline vs Fine-Tuned")  # type: ignore[attr-defined]
        ax1.set_xticks(x)  # type: ignore[attr-defined]
        ax1.set_xticklabels(metrics)  # type: ignore[attr-defined]
        ax1.legend()  # type: ignore[attr-defined]
        ax1.grid(axis="y", alpha=0.3)  # type: ignore[attr-defined]
        
        # Improvements chart
        improvements = [differences[m]["percent_change"] for m in metrics]
        colors = ["#66bb6a" if imp > 0 else "#ff9999" for imp in improvements]
        ax2.bar(metrics, improvements, color=colors)  # type: ignore[attr-defined]
        ax2.set_ylabel("Improvement %")  # type: ignore[attr-defined]
        ax2.set_title("Percentage Improvement Over Baseline")  # type: ignore[attr-defined]
        ax2.axhline(y=0, color="black", linestyle="-", linewidth=0.5)  # type: ignore[attr-defined]
        ax2.grid(axis="y", alpha=0.3)  # type: ignore[attr-defined]
        
        plt.tight_layout()  # type: ignore[attr-defined]
        plt.savefig(output_dir / "comparison.png", dpi=100, bbox_inches="tight")  # type: ignore[attr-defined]
        console.print(f"[green]✓[/green] Saved comparison plot to {output_dir / 'comparison.png'}")
        plt.close()  # type: ignore[attr-defined]
        
    except ImportError:
        console.print("[yellow]⚠ matplotlib not installed, skipping plot generation[/yellow]")


def compare(
    baseline_metrics: Path = typer.Option(
        ...,
        "--baseline-metrics",
        help="Path to baseline model metrics (JSON format)",
    ),
    fine_tuned_metrics: Path = typer.Option(
        ...,
        "--fine-tuned-metrics",
        help="Path to fine-tuned model metrics (JSON format)",
    ),
    output_dir: Path = typer.Option(
        ...,
        "--output-dir",
        help="Directory to save comparison results",
    ),
    generate_plots_flag: bool = typer.Option(
        False,
        "--generate-plots",
        help="Generate visualization charts",
    ),
    format: str = typer.Option(
        "table",
        "--format",
        help="Output format: 'table', 'json', or 'html'",
    ),
    save_report: bool = typer.Option(
        False,
        "--save-report",
        help="Save an HTML report",
    ),
) -> None:
    """
    Compare baseline and fine-tuned model performance.

    Examples:
        model-experiments compare \\
            --baseline-metrics ./metrics/base.json \\
            --fine-tuned-metrics ./metrics/fine_tuned.json \\
            --output-dir ./comparison \\
            --generate-plots \\
            --save-report
    """
    console.print("[bold blue]Comparison Configuration[/bold blue]")
    console.print(f"[dim]Baseline metrics: {baseline_metrics}[/dim]")
    console.print(f"[dim]Fine-tuned metrics: {fine_tuned_metrics}[/dim]")
    console.print(f"[dim]Output directory: {output_dir}[/dim]")
    console.print(f"[dim]Format: {format}[/dim]")
    console.print(f"[dim]Generate plots: {generate_plots_flag}[/dim]")
    console.print(f"[dim]Save report: {save_report}[/dim]")

    # Validate inputs
    if not baseline_metrics.exists():
        console.print(f"[red]Error: Baseline metrics not found: {baseline_metrics}[/red]")
        raise typer.Exit(1)

    if not fine_tuned_metrics.exists():
        console.print(f"[red]Error: Fine-tuned metrics not found: {fine_tuned_metrics}[/red]")
        raise typer.Exit(1)

    # Validate format
    valid_formats = ["table", "json", "html"]
    if format not in valid_formats:
        console.print(f"[red]Error: Invalid format '{format}'. Must be one of: {', '.join(valid_formats)}[/red]")
        raise typer.Exit(1)

    try:
        # Create output directory
        output_dir.mkdir(parents=True, exist_ok=True)

        console.print("\n[bold blue]Step 1/2: Loading metrics[/bold blue]")
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Loading baseline metrics...", total=None)
            baseline = load_metrics(baseline_metrics)
            
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Loading fine-tuned metrics...", total=None)
            fine_tuned = load_metrics(fine_tuned_metrics)

        console.print("[green]✓[/green] Metrics loaded successfully")

        console.print("\n[bold blue]Step 2/2: Computing comparison[/bold blue]")
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            progress.add_task(description="Calculating differences...", total=None)
            result = calculate_differences(baseline, fine_tuned)
            differences: dict[str, Any] = result[0]
            improvements: dict[str, Any] = result[1]

        console.print("[green]✓[/green] Comparison computed")

        # Display comparison based on format
        console.print(f"\n[bold blue]Results ({format.upper()} Format)[/bold blue]")
        
        if format == "table":
            format_as_table(baseline, fine_tuned, differences)
        elif format == "json":
            json_file = output_dir / "comparison.json"
            format_as_json(baseline, fine_tuned, differences, json_file)
            console.print(f"[green]✓[/green] JSON comparison saved to {json_file}")
        elif format == "html":
            format_as_json(baseline, fine_tuned, differences, output_dir / "comparison.json")
            console.print(f"[green]✓[/green] JSON comparison saved to {output_dir / 'comparison.json'}")

        # Generate HTML report if requested
        if save_report:
            console.print("\n[bold blue]Generating HTML report[/bold blue]")
            report_file = output_dir / "report.html"
            generate_html_report(baseline, fine_tuned, differences, improvements, report_file)
            console.print(f"[green]✓[/green] HTML report saved to {report_file}")

        # Generate plots if requested
        if generate_plots_flag:
            console.print("\n[bold blue]Generating plots[/bold blue]")
            plots_dir = output_dir / "plots"
            generate_visualization_plots(differences, plots_dir)

        # Print summary statistics
        console.print("\n[bold green]═══════════════════════════════════════[/bold green]")
        console.print("[bold green]Comparison Complete![/bold green]")
        console.print("[bold green]═══════════════════════════════════════[/bold green]")
        console.print(f"[green]✓[/green] Baseline model: {baseline['model_path']}")
        console.print(f"[green]✓[/green] Fine-tuned model: {fine_tuned['model_path']}")
        console.print(f"[green]✓[/green] Samples evaluated: {baseline.get('num_samples', 'N/A')}")
        
        console.print(f"\n[bold blue]Summary:[/bold blue]")
        console.print(f"  Metrics improved: {len(improvements)}/{len(differences)}")
        
        if improvements:
            console.print(f"\n[bold blue]Top Improvements:[/bold blue]")
            sorted_improvements = sorted(
                improvements.items(),
                key=lambda x: x[1]["percent_change"],
                reverse=True
            )
            for metric_name, values in sorted_improvements[:3]:
                console.print(f"  • {metric_name.capitalize()}: {values['percent_change']:+.2f}%")

    except Exception as e:
        console.print(f"[red]✗ Error during comparison:[/red] {str(e)}")
        raise typer.Exit(1)

