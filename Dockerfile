ARG DEBIAN_FRONTEND=noninteractive

# Build stage
FROM ubuntu:19.04 as builder

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        cmake \
        golang \
        protobuf-compiler \
        curl \
        git \
        sudo \
        && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    useradd rust --user-group --create-home --shell /bin/bash --groups sudo && \
    echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

WORKDIR /home/rust/

# Run all further code as user `rust`, and create our working directories
# as the appropriate user.
USER rust
RUN	git clone --depth 1 https://github.com/libra/libra.git libra
RUN mkdir -p /home/rust/libra/target

ENV PATH=/home/rust/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN \
    curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable && \
    rustup update && \
    rustup component add rustfmt && \
    rustup component add clippy

WORKDIR /home/rust/libra
RUN cargo build --release

FROM ubuntu:19.04
WORKDIR /app

COPY --from=builder /home/rust/libra/target/release/client /app
COPY --from=builder /home/rust/libra/scripts/cli/trusted_peers.config.toml /app/trusted_peers.config.toml
CMD ["/app/client", "--host", "ac.testnet.libra.org", "--port", "80", "-s", "trusted_peers.config.toml"]