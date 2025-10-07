use lambda_http::{http::Method, run, service_fn, tracing, Body, Error, Request, Response};
use tracing::info;
mod handlers;
use handlers::{get_root_handler, not_found_handler};
#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing::init_default_subscriber();
    run(service_fn(router)).await
}
// Router
async fn router(event: Request) -> Result<Response<Body>, Error> {
    let method = event.method();
    let path = event.uri().path();
    info!("Method: {}", method);
    info!("Path: {}", path);
    match (method, path) {
        (&Method::GET, "/") => get_root_handler().await,
        _ => not_found_handler().await,
    }
}
