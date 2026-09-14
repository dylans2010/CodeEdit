import click
from rich.console import Console

console = Console()

@click.command()
@click.option("--name", default="User", help="Name to greet")
@click.option("--count", default=1, help="Number of greetings")
def main(name, count):
    """{{PROJECT_NAME}} CLI Tool."""
    console.print(f"[bold green]Executing {{PROJECT_NAME}}...[/bold green]")
    for _ in range(count):
        console.print(f"Hello, [bold blue]{name}[/bold blue]!")

if __name__ == "__main__":
    main()
