FROM debian:trixie-slim

# Install dependencies needed for Nix installation
RUN apt-get update && apt-get install -y \
    curl \
    xz-utils \
    sudo \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Define username and whether to pre-apply config as build arguments
ARG USERNAME=vdboerd
ARG PREAPPLY=true
ENV USERNAME=${USERNAME}

# Create user with sudo privileges
RUN useradd -m -s /bin/bash -u 1000 ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to user
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Install Nix (multi-user installation requires root, so we use single-user mode)
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon

# Configure Nix with flakes enabled
RUN mkdir -p /home/${USERNAME}/.config/nix && \
    echo "experimental-features = nix-command flakes" > /home/${USERNAME}/.config/nix/nix.conf

# Source nix profile in bashrc
RUN echo "if [ -e /home/${USERNAME}/.nix-profile/etc/profile.d/nix.sh ]; then . /home/${USERNAME}/.nix-profile/etc/profile.d/nix.sh; fi" >> /home/${USERNAME}/.bashrc

# Set up environment variables for the session
ENV USER=${USERNAME}
ENV HOME=/home/${USERNAME}
ENV PATH=/home/${USERNAME}/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Copy the nix configuration into the container
# Note: This Dockerfile is in hosts/hpc, so we copy from project root
COPY --chown=${USERNAME}:${USERNAME} . /home/${USERNAME}/nix

# Set working directory to nix config
WORKDIR /home/${USERNAME}/nix

# Build and optionally apply the home-manager configuration
RUN . /home/${USERNAME}/.nix-profile/etc/profile.d/nix.sh && \
    nix build .#homeConfigurations.hpc.activationPackage --show-trace && \
    if [ "$PREAPPLY" = "true" ]; then \
    echo "Applying home-manager configuration..." && \
    nix run home-manager/release-25.11 -- switch --flake .#hpc -b backup; \
    fi

# Default command: start fish if config is applied, otherwise show instructions
CMD ["/bin/bash", "-c", "source ~/.nix-profile/etc/profile.d/nix.sh && \
    if command -v fish &> /dev/null; then \
    echo '=== Home Manager Configuration Applied ===' && \
    echo 'Starting fish shell...' && \
    echo '' && \
    exec fish; \
    else \
    echo '=== Home Manager Test Environment ===' && \
    echo 'Configuration not yet applied.' && \
    echo '' && \
    echo 'To apply the home-manager configuration, run:' && \
    echo '  nix run home-manager/release-25.11 -- switch --flake ~/nix#hpc' && \
    echo '' && \
    exec /bin/bash; \
    fi"]
