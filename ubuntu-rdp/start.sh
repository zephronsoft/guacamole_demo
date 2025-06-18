#!/bin/bash

# Enhanced startup script for FSBook developer containers
# Based on DigitalOcean Ubuntu 22.04 RDP tutorial best practices
echo "🚀 Starting FSBook Developer Container (Enhanced with DigitalOcean best practices)..."

# Clean up any stale PID files
echo "🧹 Cleaning up stale PID files..."
rm -f /var/run/xrdp/xrdp-sesman.pid
rm -f /var/run/xrdp/xrdp.pid

# Set developer name and password from environment variables
if [ ! -z "$DEVELOPER_NAME" ]; then
    # Check if user already exists
    if id "$DEVELOPER_NAME" &>/dev/null; then
        USER=$DEVELOPER_NAME
        echo "👤 Using existing user: $USER"
    else
        # Create new user if doesn't exist
        if id "developer" &>/dev/null; then
            usermod -l $DEVELOPER_NAME developer 2>/dev/null
            usermod -d /home/$DEVELOPER_NAME -m developer 2>/dev/null
            groupmod -n $DEVELOPER_NAME developer 2>/dev/null
        else
            useradd -m -s /bin/bash $DEVELOPER_NAME
            usermod -aG sudo $DEVELOPER_NAME
            echo "$DEVELOPER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        fi
        USER=$DEVELOPER_NAME
        echo "👤 Created/configured user: $USER"
    fi
else
    USER=developer
    echo "👤 Using default user: $USER"
fi

# Ensure user exists and set password
if ! id "$USER" &>/dev/null; then
    useradd -m -s /bin/bash $USER
    usermod -aG sudo $USER
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

if [ ! -z "$USER_PASSWORD" ]; then
    echo "$USER:$USER_PASSWORD" | chpasswd
    echo "🔐 Password set for user $USER"
fi

# Configure environment for optimal GUI performance
export DISPLAY=:0
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

# Ensure home directory exists
if [ ! -d "/home/$USER" ]; then
    mkdir -p /home/$USER
    chown $USER:$USER /home/$USER
fi

# Create or update .xsession file following DigitalOcean tutorial
echo "🔧 Configuring XFCE4 session..."
cat > /home/$USER/.xsession << 'EOF'
#!/bin/sh
# Simple XFCE4 session configuration

# Set locale
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

# Disable unnecessary services for better performance
export NO_AT_BRIDGE=1

# Start minimal XFCE4 session
exec xfce4-session
EOF

chmod +x /home/$USER/.xsession
chown $USER:$USER /home/$USER/.xsession

# Update XRDP configuration for the specific user
echo "⚙️ Configuring XRDP for user $USER..."
sed -i "s/startxfce4/\/home\/$USER\/.xsession/" /etc/xrdp/startwm.sh

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p /workspace
mkdir -p /home/$USER/Desktop
mkdir -p /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /home/$USER/.cache/sessions

# Create minimal working XFCE4 session configuration
echo "🔧 Creating minimal XFCE4 configuration..."

# Simple session configuration
cat > /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-session" version="1.0">
  <property name="general" type="empty">
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
cat > /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="show_frame_shadow" type="bool" value="false"/>
    <property name="show_dock_shadow" type="bool" value="false"/>
    <property name="show_popup_shadow" type="bool" value="false"/>
    <property name="box_move" type="bool" value="false"/>
    <property name="box_resize" type="bool" value="false"/>
  </property>
</channel>
EOF

# Set ownership of workspace and desktop
chown -R $USER:$USER /workspace 2>/dev/null || true
chown -R $USER:$USER /home/$USER 2>/dev/null || true

# Create additional desktop shortcuts
echo "🖥️ Setting up desktop shortcuts..."
cat > /home/$USER/Desktop/VSCode.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=VSCode Online
Comment=Open VS Code in browser
Icon=applications-development
Exec=firefox https://vscode.dev
Categories=Development;
EOF

cat > /home/$USER/Desktop/Python.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Python
Comment=Python 3 Interpreter
Icon=applications-development
Exec=xfce4-terminal -e python3
Categories=Development;
EOF

# Set proper ownership and permissions for desktop files
chown $USER:$USER /home/$USER/Desktop/*.desktop
chmod +x /home/$USER/Desktop/*.desktop

# Start system services in proper order (DigitalOcean tutorial sequence)
echo "🔄 Starting system services..."

# Start D-Bus service first
echo "  - Starting D-Bus..."
service dbus start
if [ $? -eq 0 ]; then
    echo "    ✅ D-Bus started successfully"
else
    echo "    ❌ D-Bus failed to start"
fi

# Wait a moment for D-Bus to initialize
sleep 2

# Start XRDP service
echo "  - Starting XRDP..."
service xrdp start
if [ $? -eq 0 ]; then
    echo "    ✅ XRDP started successfully"
else
    echo "    ❌ XRDP failed to start, checking logs..."
    # Show XRDP logs for debugging
    tail -20 /var/log/xrdp.log 2>/dev/null || echo "No XRDP log found"
    tail -20 /var/log/xrdp-sesman.log 2>/dev/null || echo "No XRDP sesman log found"
fi

# Wait for XRDP to be fully ready
echo "⏳ Waiting for XRDP to be ready..."
for i in {1..30}; do
    if ss -tln | grep -q ":3389" || netstat -ln 2>/dev/null | grep -q ":3389"; then
        echo "✅ XRDP is listening on port 3389"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ XRDP failed to bind to port 3389 after 30 seconds"
        echo "🔍 Port check:"
        ss -tln | grep 3389 || echo "No process listening on port 3389"
        echo "🔍 XRDP processes:"
        ps aux | grep xrdp || echo "No XRDP processes found"
        exit 1
    fi
    sleep 1
done

# Display connection information
echo ""
echo "🎉 FSBook Developer Container is ready!"
echo "📋 Connection Details:"
echo "   🔗 RDP Port: 3389"
echo "   👤 Username: $USER"
echo "   🏠 Home Directory: /home/$USER"
echo "   💼 Workspace: /workspace"
echo "   🖥️ Desktop Environment: XFCE4 (Optimized)"
echo ""
echo "🔌 Connection Methods:"
echo "   1. Via Guacamole: http://localhost:8080/guacamole"
echo "   2. Direct RDP: localhost:3389"
echo ""
echo "🛠️ Available Tools:"
echo "   - Firefox Web Browser"
echo "   - Python 3 & pip"
echo "   - Node.js & npm"
echo "   - Git version control"
echo "   - Terminal & text editors"
echo ""

# Enhanced monitoring and restart functionality
echo "🔍 Starting enhanced monitoring..."

# Function to check and restart XRDP if needed
check_and_restart_xrdp() {
    if ! pgrep xrdp > /dev/null; then
        echo "⚠️ XRDP process not found, attempting restart..."
        # Clean up PID files before restart
        rm -f /var/run/xrdp/xrdp-sesman.pid
        rm -f /var/run/xrdp/xrdp.pid
        service xrdp start
        if [ $? -eq 0 ]; then
            echo "✅ XRDP restarted successfully"
        else
            echo "❌ Failed to restart XRDP"
            return 1
        fi
    fi
    
    # Check if port is still listening (use ss first, fallback to netstat)
    if ! ss -tln | grep -q ":3389" && ! netstat -ln 2>/dev/null | grep -q ":3389"; then
        echo "⚠️ XRDP not listening on port 3389, attempting restart..."
        service xrdp restart
        sleep 5
        if ss -tln | grep -q ":3389" || netstat -ln 2>/dev/null | grep -q ":3389"; then
            echo "✅ XRDP port restored"
        else
            echo "❌ XRDP port restoration failed"
            return 1
        fi
    fi
    
    return 0
}

# Main monitoring loop with enhanced error handling
monitor_count=0
while true; do
    # Check XRDP every 30 seconds
    if ! check_and_restart_xrdp; then
        echo "💥 Critical: Unable to maintain XRDP service"
        # Don't exit immediately, try a few more times
        ((monitor_count++))
        if [ $monitor_count -gt 3 ]; then
            echo "🚨 Too many failures, container needs restart"
            exit 1
        fi
    else
        # Reset counter on success
        monitor_count=0
    fi
    
    # Health check log every 10 minutes
    if [ $(($(date +%s) % 600)) -eq 0 ]; then
        echo "💓 Health check: Container running, XRDP active"
        echo "   📊 Active sessions: $(who | wc -l)"
        echo "   🔧 XRDP processes: $(pgrep xrdp | wc -l)"
    fi
    
    sleep 30
done 