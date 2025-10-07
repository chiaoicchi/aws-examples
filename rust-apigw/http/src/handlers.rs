use lambda_http::{Body, Error, Response};

pub(crate) async fn get_root_handler() -> Result<Response<Body>, Error> {
    let resp = Response::builder()
        .status(200)
        .header("content-type", "text/html")
        .body("Hello".into())
        .map_err(Box::new)?;
    Ok(resp)
}

pub(crate) async fn not_found_handler() -> Result<Response<Body>, Error> {
    let resp = Response::builder()
        .status(404)
        .header("content-type", "text/html")
        .body("Not found handlers".into())
        .map_err(Box::new)?;
    Ok(resp)
}
