use clap::Parser;

#[derive(Parser, Debug)]
#[command(author, version, about = "CLI built with Rust in {{PROJECT_NAME}}")]
struct Args {
    #[arg(short, long, default_value = "Developer")]
    name: String,
}

fn main() {
    let args = Args::parse();
    println!("Hello, {}! Welcome to {{PROJECT_NAME}}.", args.name);
}
