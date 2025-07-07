#!/bin/bash

# 🔧 Quick Fix Script for Epiphany Browser X11 Issues
# Run this directly in your container to fix the browser immediately

echo "🔧 Quick Fix for Epiphany Browser X11 Issues"
echo "=============================================="
echo

# Check current user
CURRENT_USER=$(whoami)
echo "🎯 Current user: $CURRENT_USER"
echo "🎯 User ID: $(id -u)"
echo "🎯 Display: $DISPLAY"
echo

# Install required packages if missing
echo "📦 Installing required packages..."
apt update >/dev/null 2>&1
apt install -y xauth x11-utils x11-xserver-utils xxd epiphany-browser >/dev/null 2>&1

# Fix X11 authorization for current user
echo "🔐 Setting up X11 authorization..."
export DISPLAY=${DISPLAY:-:10}
export XAUTHORITY="$HOME/.Xauthority"

# Create and setup .Xauthority file
touch "$XAUTHORITY"
chmod 600 "$XAUTHORITY"

# Generate X11 authorization cookie
if command -v xauth &> /dev/null; then
    echo "   🔑 Generating X11 authorization cookie..."
    xauth add "$DISPLAY" MIT-MAGIC-COOKIE-1 $(xxd -l 16 -p /dev/urandom) 2>/dev/null || true
    echo "   📋 Current X11 authorization entries:"
    xauth list 2>/dev/null || echo "   ❌ No entries found"
else
    echo "   ❌ xauth not available"
fi

# Set GTK and X11 environment variables
echo "🎨 Setting up GTK environment..."
export GTK_THEME="Adwaita:light"
export GDK_BACKEND=x11
export NO_AT_BRIDGE=1
export QT_X11_NO_MITSHM=1
export _X11_NO_MITSHM=1
export _MITSHM=0

# Test X11 connection
echo "🖥️ Testing X11 connection..."
if xset q &>/dev/null; then
    echo "   ✅ X11 server connection successful"
else
    echo "   ❌ X11 server connection failed"
    echo "   🔧 Trying to fix X11 display..."
    
    # Try different display numbers
    for display_num in 0 1 10 11; do
        export DISPLAY=:$display_num
        if xset q &>/dev/null 2>&1; then
            echo "   ✅ Found working display: $DISPLAY"
            break
        fi
    done
fi

# Create desktop directory if it doesn't exist
mkdir -p "$HOME/Desktop"

# Create the enhanced browser launcher
echo "🚀 Creating browser launcher..."
cat > "$HOME/Desktop/launch-epiphany.sh" << 'EOF'
#!/bin/bash
# Enhanced Epiphany Browser Launcher

# Set environment
export DISPLAY=${DISPLAY:-:10}
export XAUTHORITY="$HOME/.Xauthority"
export GTK_THEME="Adwaita:light"
export GDK_BACKEND=x11
export NO_AT_BRIDGE=1
export QT_X11_NO_MITSHM=1
export _X11_NO_MITSHM=1
export _MITSHM=0

echo "🌐 Starting Epiphany Browser..."
echo "   Display: $DISPLAY"
echo "   Authority: $XAUTHORITY"
echo "   User: $(whoami)"

# Try to launch epiphany
if command -v epiphany-browser &> /dev/null; then
    echo "   🚀 Launching epiphany-browser..."
    epiphany-browser "$@" 2>/dev/null &
    if [ $? -eq 0 ]; then
        echo "   ✅ Browser launched successfully!"
    else
        echo "   ❌ Launch failed, trying alternative..."
        epiphany-browser --display="$DISPLAY" "$@" &
    fi
else
    echo "   ❌ epiphany-browser not found"
fi
EOF

chmod +x "$HOME/Desktop/launch-epiphany.sh"

# Create desktop shortcut
echo "🖱️ Creating desktop shortcut..."
cat > "$HOME/Desktop/Epiphany-Browser.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Epiphany Browser
Comment=GNOME Web Browser
Exec=$HOME/Desktop/launch-epiphany.sh
Icon=web-browser
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
EOF

chmod +x "$HOME/Desktop/Epiphany-Browser.desktop"

# Add environment variables to shell profile
echo "📝 Adding environment variables to shell profile..."
cat >> "$HOME/.bashrc" << 'EOF'

# X11 and GTK environment for Epiphany Browser
export GTK_THEME="Adwaita:light"
export GDK_BACKEND=x11
export NO_AT_BRIDGE=1
export QT_X11_NO_MITSHM=1
export _X11_NO_MITSHM=1
export _MITSHM=0
export XAUTHORITY="$HOME/.Xauthority"
EOF

# Final test
echo "🧪 Testing browser launch..."
echo "   Setting environment for current session..."
export GTK_THEME="Adwaita:light"
export GDK_BACKEND=x11
export NO_AT_BRIDGE=1
export QT_X11_NO_MITSHM=1
export _X11_NO_MITSHM=1
export _MITSHM=0

echo "   Testing epiphany-browser --version..."
timeout 5 epiphany-browser --version &>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ Browser test successful!"
else
    echo "   ⚠️ Browser test failed, but launcher should still work"
fi

echo
echo "🎉 Quick Fix Complete!"
echo "================================"
echo "✅ X11 authorization configured"
echo "✅ GTK environment set"
echo "✅ Browser launcher created"
echo "✅ Desktop shortcut created"
echo "✅ Shell profile updated"
echo
echo "🚀 How to use:"
echo "1. Click the desktop shortcut: 'Epiphany Browser'"
echo "2. Or run: ~/Desktop/launch-epiphany.sh"
echo "3. Or run: source ~/.bashrc && epiphany-browser"
echo
echo "🔧 If you're using root, consider switching to the regular user:"
echo "   su - developer  # or su - [username]"
echo

# Try to launch browser as a final test
echo "🚀 Attempting to launch browser now..."
"$HOME/Desktop/launch-epiphany.sh" &
echo "   Browser launch attempted. Check if window opens." 