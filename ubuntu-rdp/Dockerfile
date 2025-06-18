FROM ubuntu:22.04

# Set environment variables for performance
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=developer
ENV DISPLAY=:0
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install packages following DigitalOcean tutorial best practices
RUN apt-get update && apt-get install -y \
    # Minimal XFCE4 components only
    xfce4-session \
    xfce4-panel \
    xfce4-terminal \
    xfwm4 \
    xfdesktop4 \
    # RDP server
    xrdp \
    # Essential utilities
    sudo \
    wget \
    curl \
    git \
    vim \
    nano \
    # Development tools
    python3 \
    python3-pip \
    nodejs \
    npm \
    # Web browser
    firefox \
    # System utilities
    dbus-x11 \
    locales \
    openssh-server \
    # Network tools for monitoring
    net-tools \
    iproute2 \
    procps \
    # File manager
    thunar \
    # Clean up to reduce image size
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# Configure locales
RUN locale-gen en_US.UTF-8

# Create developer user with proper configuration
RUN useradd -m -s /bin/bash ${USER} \
    && echo "${USER}:developer123" | chpasswd \
    && usermod -aG sudo ${USER} \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add xrdp user to ssl-cert group (DigitalOcean tutorial recommendation)
RUN adduser xrdp ssl-cert

# Configure XRDP following DigitalOcean tutorial best practices
RUN sed -i 's/3389/3389/g' /etc/xrdp/xrdp.ini \
    && sed -i 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini \
    && sed -i 's/xserverbpp=24/xserverbpp=24/g' /etc/xrdp/xrdp.ini \
    && sed -i 's/#tcp_nodelay=1/tcp_nodelay=1/g' /etc/xrdp/xrdp.ini \
    && sed -i 's/#tcp_keepalive=1/tcp_keepalive=1/g' /etc/xrdp/xrdp.ini \
    && echo "use_fastpath=both" >> /etc/xrdp/xrdp.ini \
    && echo "crypt_level=low" >> /etc/xrdp/xrdp.ini \
    && echo "channel_code=0" >> /etc/xrdp/xrdp.ini

# Configure startwm.sh following the tutorial
RUN cat > /etc/xrdp/startwm.sh << 'EOF'
#!/bin/sh
# startwm.sh script for XRDP
# Minimal working configuration

if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi

# Simple XFCE4 startup
exec xfce4-session
EOF

RUN chmod 755 /etc/xrdp/startwm.sh

# Create user's .xsession file (simple version)
RUN echo "#!/bin/sh" > /home/${USER}/.xsession \
    && echo "exec xfce4-session" >> /home/${USER}/.xsession \
    && chmod +x /home/${USER}/.xsession \
    && chown ${USER}:${USER} /home/${USER}/.xsession

# Configure XFCE4 for better performance
RUN mkdir -p /home/${USER}/.config/xfce4/xfconf/xfce-perchannel-xml

# Create proper XFCE4 session configuration
RUN mkdir -p /home/${USER}/.config/xfce4 \
    && mkdir -p /home/${USER}/.cache/sessions

# Simple working session configuration
RUN cat > /home/${USER}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-session" version="1.0">
  <property name="general" type="empty">
    <property name="FailsafeSessionName" type="string" value="Failsafe"/>
    <property name="SessionName" type="string" value="Default"/>
    <property name="SaveOnExit" type="bool" value="false"/>
    <property name="PromptOnLogout" type="bool" value="false"/>
    <property name="AutoSave" type="bool" value="false"/>
  </property>
  <property name="startup" type="empty">
    <property name="screensaver" type="empty">
      <property name="enabled" type="bool" value="false"/>
    </property>
  </property>
</channel>
EOF

# Minimal window manager configuration
RUN cat > /home/${USER}/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="show_frame_shadow" type="bool" value="false"/>
    <property name="show_dock_shadow" type="bool" value="false"/>
    <property name="show_popup_shadow" type="bool" value="false"/>
  </property>
</channel>
EOF

# Set ownership of all config files
RUN chown -R ${USER}:${USER} /home/${USER}/.config

# Create workspace and desktop shortcuts
RUN mkdir -p /workspace \
    && chown ${USER}:${USER} /workspace \
    && mkdir -p /home/${USER}/Desktop

# Create desktop shortcuts
RUN cat > /home/${USER}/Desktop/Workspace.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Link
Name=Workspace
Comment=Development Workspace
Icon=folder
URL=file:///workspace
EOF

RUN cat > /home/${USER}/Desktop/Terminal.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Comment=Terminal Emulator
Icon=utilities-terminal
Exec=xfce4-terminal
Categories=System;TerminalEmulator;
EOF

RUN cat > /home/${USER}/Desktop/Firefox.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
Comment=Web Browser
Icon=firefox
Exec=firefox
Categories=Network;WebBrowser;
EOF

# Set desktop shortcuts permissions
RUN chown -R ${USER}:${USER} /home/${USER}/Desktop \
    && chmod +x /home/${USER}/Desktop/*.desktop

# Configure systemd services for better container compatibility
RUN mkdir -p /etc/systemd/system/xrdp.service.d \
    && echo "[Unit]" > /etc/systemd/system/xrdp.service.d/override.conf \
    && echo "After=dbus.service" >> /etc/systemd/system/xrdp.service.d/override.conf

# Add optimized startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose RDP port
EXPOSE 3389

# Set working directory
WORKDIR /home/${USER}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD netstat -ln | grep :3389 || exit 1

# Start services
CMD ["/start.sh"] 


