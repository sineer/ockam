ARG BASE_IMAGE=debian:unstable-slim
FROM ${BASE_IMAGE}

ARG RUSTUP_INIT_VERSION=1.23.1
ARG RUSTUP_INIT_SHA256=ed7773edaf1d289656bdec2aacad12413b38ad0193fff54b2231f5140a4b07c5
ARG RUST_VERSION=1.49.0
ARG HOST=x86_64-unknown-linux-gnu

ENV RUSTUP_HOME=/opt/rust/rustup \
    CARGO_HOME=/usr/rust/cargo

# Setup rust
RUN apt-get -y update && apt-get -y install apt-utils curl llvm-11 clang-11 gcc-10 jq 
RUN ln -s /usr/bin/clang-11 /usr/bin/cc; \
    curl -sSOL \
      "https://static.rust-lang.org/rustup/archive/${RUSTUP_INIT_VERSION}/${HOST}/rustup-init" && \
    echo "${RUSTUP_INIT_SHA256}  rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal \
      --default-toolchain "$RUST_VERSION" --default-host $HOST; \
    rm rustup-init;\
    chmod -R a+w "$RUSTUP_HOME" "$CARGO_HOME"; 
RUN . /usr/rust/cargo/env && rustup toolchain install nightly-$HOST && rustup default nightly
RUN . /usr/rust/cargo/env && rustup component add llvm-tools-preview 
RUN . /usr/rust/cargo/env && cargo install cargo-binutils
COPY /coverage.sh /
