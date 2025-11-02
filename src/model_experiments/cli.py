"""Main CLI entry point for the Model Experiments Framework."""

import typer
from rich.console import Console

from model_experiments.commands import compare, dataset, evaluate, model, train

# Create the main CLI app
app = typer.Typer(
    name="model-experiments",
    help="A framework for fine-tuning language models with comprehensive evaluation and monitoring.",
    add_completion=True,
    rich_markup_mode="rich",
)

# Create console for rich output
console = Console()

# Add command groups
app.add_typer(dataset.app, name="dataset", help="Dataset management commands")
app.add_typer(model.app, name="model", help="Model management commands")

# Add standalone commands
app.command(name="train", help="Fine-tune a model on training data")(train.train)
app.command(name="evaluate", help="Evaluate model performance on test data")(evaluate.evaluate)
app.command(name="compare", help="Compare baseline and fine-tuned model performance")(
    compare.compare
)


@app.callback(invoke_without_command=True)
def main(
    ctx: typer.Context,
    version: bool = typer.Option(
        False,
        "--version",
        "-v",
        help="Show version and exit",
    ),
) -> None:
    """
    Model Experiments Framework - Fine-tune and evaluate language models.

    Use 'model-experiments --help' to see all available commands.
    """
    if version:
        from model_experiments import __version__

        console.print(f"[bold blue]Model Experiments Framework[/bold blue] v{__version__}")
        raise typer.Exit()

    if ctx.invoked_subcommand is None:
        console.print("[yellow]No command specified. Use --help to see available commands.[/yellow]")
        raise typer.Exit()


if __name__ == "__main__":
    app()

