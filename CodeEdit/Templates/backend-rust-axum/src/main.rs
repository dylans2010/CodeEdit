use axum::{routing::get, Json, Router};
use serde::Serialize;
use std::net::SocketAddr;

#[derive(Serialize)]
struct ApiResponse {
    service: &'static str,
    status: &'static str,
}

async def root() -> Json<ApiResponse> {
    Json(ApiResponse {
        service: "{{PROJECT_NAME}}",
        status: "operational",
    })
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/", get(root));
    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));
    println!("Axum listening on http://{}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
