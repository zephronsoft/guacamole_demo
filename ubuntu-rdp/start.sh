#!/bin/bash

# Set developer name and password from environment variables if provided
if [ ! -z "$DEVELOPER_NAME" ]; then
    usermod -l $DEVELOPER_NAME developer
    usermod -d /home/$DEVELOPER_NAME -m $DEVELOPER_NAME
    USER=$DEVELOPER_NAME
else
    USER=developer
fi

if [ ! -z "$USER_PASSWORD" ]; then
    echo "$USER:$USER_PASSWORD" | chpasswd
fi

# Start XRDP service
service xrdp start

# Start VNC server as backup
if [ ! -z "$VNC_PASSWORD" ]; then
    su - $USER -c "mkdir -p ~/.vnc"
    su - $USER -c "echo '$VNC_PASSWORD' | vncpasswd -f > ~/.vnc/passwd"
    su - $USER -c "chmod 600 ~/.vnc/passwd"
    su - $USER -c "vncserver :0 -geometry 1920x1080 -depth 24"
fi

# Set ownership of workspace
chown -R $USER:$USER /workspace

# Keep container running
tail -f /var/log/xrdp.log 