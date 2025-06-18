FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=developer

# Install necessary packages (removing problematic ones)
RUN apt-get update && apt-get install -y \
    xrdp \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    sudo \
    wget \
    curl \
    git \
    vim \
    nano \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm \
    firefox \
    gedit \
    file-roller \
    gnome-terminal \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Visual Studio Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ \
    && sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' \
    && apt-get update \
    && apt-get install -y code \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create developer user
RUN useradd -m -s /bin/bash ${USER} \
    && echo "${USER}:developer123" | chpasswd \
    && usermod -aG sudo ${USER} \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure XRDP
RUN echo "exec startxfce4" > /home/${USER}/.xsession \
    && chmod +x /home/${USER}/.xsession \
    && chown ${USER}:${USER} /home/${USER}/.xsession

# Configure xrdp
RUN sed -i 's/3389/3389/g' /etc/xrdp/xrdp.ini \
    && sed -i 's/max_bpp=32/#max_bpp=32\nmax_bpp=128/g' /etc/xrdp/xrdp.ini \
    && sed -i 's/xserverbpp=24/#xserverbpp=24\nxserverbpp=128/g' /etc/xrdp/xrdp.ini

# Create workspace directory
RUN mkdir -p /workspace && chown ${USER}:${USER} /workspace

# Add startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose RDP and VNC ports
EXPOSE 3389 5900

# Set working directory
WORKDIR /home/${USER}

# Start services
CMD ["/start.sh"] 