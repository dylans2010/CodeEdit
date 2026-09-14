use actix_web::{get, App, HttpResponse, HttpServer, Responder};
use serde::Serialize;

#[derive(Serialize)]
struct Status {
    project: String,
    status: String,
}

#[get("/")]
async def index() -> impl Responder {
    HttpResponse::Ok().json(Status {
        project: "{{PROJECT_NAME}}".to_string(),
        status: "active".to_string(),
    })
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    println!("Starting {{PROJECT_NAME}} on http://127.0.0.1:8080");
    HttpServer::new(|| {
        App::new().service(index)
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
