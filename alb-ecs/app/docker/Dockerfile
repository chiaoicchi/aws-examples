FROM rust:1.89 AS builder
WORKDIR /build
COPY . .
RUN cargo build --release

FROM rust:1.89
WORKDIR /app
COPY --from=builder /build/target/release/app .
RUN chmod +x ./app
CMD ["./app"]
