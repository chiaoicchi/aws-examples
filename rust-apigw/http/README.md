# web-backend

## Using aws-lambda-rust-runtime

Use [aws-lambda-rust-runtime](https://github.com/awslabs/aws-lambda-rust-runtime).

### Install

```bash
brew tap cargo-lambda/cargo-lambda
brew install cargo-lambda
```

### Init

```bash
cargo lambda new <function name>
```

### Build

```bash
cargo lambda build --release --arm64
```

### Upload to aws

```bash
cd target/lambda/http/
zip -j bootstrap.zip bootstrap
```

Use custom runtime and upload the zip file you created above command.
