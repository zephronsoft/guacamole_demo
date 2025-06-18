#!/bin/bash

set -x
DISPLAY=:10
USER_NAME="${USERNAME:-developer}"
USER_UID="${UID:-1010}"
HOME_DIR="/home/$USER_NAME"
SSH_DIR="$HOME_DIR/.ssh"
KEY_NAME="bitbucket_repo_access"
KEY_PATH="$SSH_DIR/$KEY_NAME"
SHARED_KEY_DIR="/opt/guacamole-env/secrets/"
SHARED_KEY_PATH="$SHARED_KEY_DIR/${USER_NAME}.pub"

#echo "--- XRDP Configuration ---"
#cat /etc/xrdp/xrdp.ini
#echo "--- END XRDP CONFIGU ---"

XAUTHORITY=$HOME_DIR/.Xauthority

# Create .Xauthority file if it doesn't exist
touch $XAUTHORITY
sudo chown $USER_NAME:$USER_NAME $XAUTHORITY

if [ ! -f /etc/xrdp/rsakeys.ini ]; then
        xrdp-keygen xrdp auto
fi

# Verbose logging for XRDP
    sed -i 's/LogLevel=info/LogLevel=debug/' /etc/xrdp/xrdp.ini

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
for ip in $(dig +short bitbucket.org); do
    echo "Allowing SSH to Bitbucket IP: $ip"
    iptables -A OUTPUT -p tcp -d $ip --dport 22 -j ACCEPT
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

echo 'show user ID'
id $USERNAME

echo "giving permission to $SSH_DIR for UID $UID..."
sudo chown -R $UID:$UID $SSH_DIR
sudo chown -R $USERNAME:$USERNAME $HOME_DIR
# Set XFCE as default session
#echo "xfce4-session" > /home/$USERNAME/.xsession && chown $USERNAME:$USERNAME /home/$USERNAME/.xsession

#sed -i '/^test -x \/etc\/X11\/Xsession/ a \
#unset DBUS_SESSION_BUS_ADDRESS\n\
#unset XDG_RUNTIME_DIR\nstartxfce4' /etc/xrdp/startwm.sh

mkdir -p /home/$USER_NAME/.config/xfce4/xfconf/xfce-perchannel-xml
cp /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml /home/$USER_NAME/.config/xfce4/xfconf/xfce-perchannel-xml/
chown $USER_NAME:$USER_NAME /home/$USER_NAME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml


echo "USER_NAME: $USER_NAME"
echo "SSH_DIR: $SSH_DIR"
echo "KEY_PATH: $KEY_PATH"

if [[ ! -f "$KEY_PATH" ]]; then
  echo "Creating ssh key @ $KEY_PATH"
  sudo ssh-keygen -t rsa -b 4096 -C 'machine-only-access' -f $KEY_PATH -N ""
fi

# Set permissions
chown "$USER_NAME":"$USER_NAME" "$KEY_PATH" "$KEY_PATH.pub"
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

# Create Browser shortcut ~/Desktop/epiphany-browser.desktop
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
  chown "$USER_NAME":"$USER_NAME" "$SHORTCUT_FILE"
  chmod +x $SHORTCUT_FILE
fi

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
  chown "$USER_NAME":"$USER_NAME" "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
fi

# Show public key
echo -e "\n Public key for $USER_NAME:\n"
cat "$KEY_PATH.pub"

# Copy public key to shared volume for host access
#mkdir -p "$SHARED_KEY_DIR"
#cp "$KEY_PATH.pub" "$SHARED_KEY_PATH"
#chmod 644 "$SHARED_KEY_PATH"
sudo chown root:root $SSH_DIR
sudo chmod 700 $SSH_DIR

sudo apt update
sudo apt install -y wget gpg software-properties-common apt-transport-https
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update
sudo apt install -y code

echo -e "\n Starting XRDP server:\n"

if [ ! -d "/var/run/dbus" ]; then
        mkdir -p /var/run/dbus
fi

service dbus start

# Start XRDP session manager
#/usr/sbin/xrdp-sesman &

sed -i 's/LogLevel=info/LogLevel=debug/' /etc/xrdp/xrdp.ini

echo -e "Starting RDP"
/etc/init.d/xrdp start

# Wait and check XRDP status
sleep 5

#systemctl status xrdp || echo "XRDP service failed to start"


# Attempt to start Xorg
    Xorg $DISPLAY -keeptty -verbose 7 &
    XORG_PID=$!

    # Wait a moment
    sleep 5

    # Check if Xorg is running
    if ! kill -0 $XORG_PID 2>/dev/null; then
        echo "Xorg failed to start"
        return 1
    fi

    # Attempt to run an X11 app to validate
    su - $USER_NAME -c "DISPLAY=$DISPLAY xeyes" || echo "X11 validation failed"



# Tail logs to keep container running and provide debug info
tail -f /var/log/xrdp.log /var/log/xrdp-sesman.log
