use axum::{routing::get, Router};

#[tokio::main]
async fn main() {
    async fn root_handler() -> String {
        "Hello World from Rust app".to_string()
    }

    let app = Router::new().route("/", get(root_handler));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
