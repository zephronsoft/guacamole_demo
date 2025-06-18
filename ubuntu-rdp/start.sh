#!/bin/bash

# Enhanced startup script for FSBook developer containers
# Based on DigitalOcean Ubuntu 22.04 RDP tutorial best practices
echo "🚀 Starting FSBook Developer Container (Enhanced with DigitalOcean best practices)..."

# Set debugging mode and additional environment variables
set -x
export DISPLAY=${DISPLAY:-:10}
USER_NAME="${USERNAME:-${DEVELOPER_NAME:-developer}}"
USER_UID="${UID:-1010}"
HOME_DIR="/home/$USER_NAME"
SSH_DIR="$HOME_DIR/.ssh"
KEY_NAME="bitbucket_repo_access"
KEY_PATH="$SSH_DIR/$KEY_NAME"
SHARED_KEY_DIR="/opt/guacamole-env/secrets/"
SHARED_KEY_PATH="$SHARED_KEY_DIR/${USER_NAME}.pub"

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
    USER=$USER_NAME
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
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

# Setup XAUTHORITY
XAUTHORITY=$HOME_DIR/.Xauthority
touch $XAUTHORITY
sudo chown $USER:$USER $XAUTHORITY

# Ensure home directory exists
if [ ! -d "/home/$USER" ]; then
    mkdir -p /home/$USER
    chown $USER:$USER /home/$USER
fi

# Configure iptables for security
echo "🔒 Configuring iptables security rules..."
# Flush and reset iptables
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow localhost
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow SSH to Bitbucket
for ip in $(dig +short bitbucket.org 2>/dev/null); do
    if [ ! -z "$ip" ]; then
        echo "Allowing SSH to Bitbucket IP: $ip"
        iptables -A OUTPUT -p tcp -d $ip --dport 22 -j ACCEPT
    fi
done

# XRDP port (3389) for remote desktop
iptables -A INPUT -p tcp --dport 3389 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 3389 -j ACCEPT

# Open necessary ports
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 5000:5010 -j ACCEPT

iptables -A OUTPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --dport 8080 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --dport 5000:5010 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Set proper ownership
echo "🔧 Setting proper ownership..."
echo "User ID: $(id $USER)"
sudo chown -R $USER_UID:$USER_UID $SSH_DIR 2>/dev/null || true
sudo chown -R $USER:$USER $HOME_DIR

# Generate XRDP keys if needed
if [ ! -f /etc/xrdp/rsakeys.ini ]; then
    xrdp-keygen xrdp auto
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

# Set verbose logging for XRDP
sed -i 's/LogLevel=info/LogLevel=debug/' /etc/xrdp/xrdp.ini

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p /workspace
mkdir -p /home/$USER/Desktop
mkdir -p /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /home/$USER/.cache/sessions
mkdir -p $SSH_DIR

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

# Copy system XFCE configuration if it exists
if [ -f /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml ]; then
    cp /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true
fi

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

# Generate SSH key for repository access
echo "🔑 Setting up SSH key for repository access..."
if [[ ! -f "$KEY_PATH" ]]; then
    echo "Creating SSH key @ $KEY_PATH"
    sudo ssh-keygen -t rsa -b 4096 -C 'machine-only-access' -f $KEY_PATH -N ""
fi

# Set SSH key permissions
chown "$USER":"$USER" "$KEY_PATH" "$KEY_PATH.pub" 2>/dev/null || true
chmod 600 "$KEY_PATH" 2>/dev/null || true
chmod 644 "$KEY_PATH.pub" 2>/dev/null || true

# Create SSH config
CONFIG_FILE="$SSH_DIR/config"
if ! grep -q "$KEY_PATH" "$CONFIG_FILE" 2>/dev/null; then
    cat >> "$CONFIG_FILE" <<EOF
Host bitbucket.org
  HostName bitbucket.org
  User git
  IdentityFile $KEY_PATH
  IdentitiesOnly yes
EOF
    chown "$USER":"$USER" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
fi

# Show public key
echo -e "\n🔑 Public key for $USER:\n"
cat "$KEY_PATH.pub" 2>/dev/null || echo "SSH key not yet available"

# Set final SSH directory permissions
sudo chown root:root $SSH_DIR 2>/dev/null || true
sudo chmod 700 $SSH_DIR 2>/dev/null || true

# Install VSCode
echo "💻 Installing Visual Studio Code..."
sudo apt update
sudo apt install -y wget gpg software-properties-common apt-transport-https
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update
sudo apt install -y code

# Set ownership of workspace and desktop
chown -R $USER:$USER /workspace 2>/dev/null || true
chown -R $USER:$USER /home/$USER 2>/dev/null || true

# Create additional desktop shortcuts
echo "🖥️ Setting up desktop shortcuts..."
cat > /home/$USER/Desktop/VSCode.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=VSCode
Comment=Visual Studio Code
Icon=applications-development
Exec=code
Categories=Development;
EOF

# Create Browser shortcut (Epiphany)
SHORTCUT_FILE="$HOME_DIR/Desktop/epiphany-browser.desktop"
if [[ ! -f "$SHORTCUT_FILE" ]]; then
cat >> "$SHORTCUT_FILE" <<EOF
[Desktop Entry]
Version=1.0
Name=Epiphany Browser
Comment=Lightweight GNOME web browser
Exec=epiphany
Icon=web-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF
  chown "$USER":"$USER" "$SHORTCUT_FILE"
  chmod +x $SHORTCUT_FILE
fi

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

# Ensure D-Bus directory exists
if [ ! -d "/var/run/dbus" ]; then
    mkdir -p /var/run/dbus
fi

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

# Start Xorg server
echo "  - Starting Xorg server..."
Xorg $DISPLAY -keeptty -verbose 7 &
XORG_PID=$!
sleep 5

# Check if Xorg is running
if ! kill -0 $XORG_PID 2>/dev/null; then
    echo "    ❌ Xorg failed to start"
else
    echo "    ✅ Xorg started successfully"
    # Attempt to run an X11 app to validate
    su - $USER -c "DISPLAY=$DISPLAY xeyes" || echo "    ⚠️ X11 validation failed"
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
echo "   - Visual Studio Code"
echo "   - Epiphany Web Browser"
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