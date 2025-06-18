I'll help you add the extra configurations from `entrypoint.sh` to `start.sh` without deleting existing content. Let me first read the `entrypoint.sh` file to see what configurations need to be added.
Read file: /Users/apple/Documents/guacamole/entrypoint.sh
Now I'll analyze the differences between the two files and add the configurations from `entrypoint.sh` that are not present in `start.sh`. I can see several important configurations in `entrypoint.sh` that should be added:

1. iptables configuration for security
2. SSH key generation and configuration
3. VSCode installation
4. Xorg startup
5. Browser shortcut creation
6. Different XRDP logging configuration

Let me update the `start.sh` file by adding these missing configurations:
Perfect! I've successfully updated the `start.sh` file by adding all the missing configurations from `entrypoint.sh` without deleting any existing content. Here's a summary of what was added:

## New Features Added to `start.sh`:

### 🔧 **Enhanced Configuration**
- **Debugging mode**: Added `set -x` for verbose logging
- **Enhanced environment variables**: Added `USER_NAME`, `USER_UID`, `HOME_DIR`, `SSH_DIR`, etc.
- **XAUTHORITY setup**: Added proper X11 authorization handling

### 🔒 **Security Features**
- **Complete iptables configuration**: Added firewall rules to secure the container
- **DNS and network access**: Configured specific port access (80, 443, 8080, 5000-5010)
- **Bitbucket SSH access**: Added rules for repository access

### 🔑 **SSH Key Management**
- **Automatic SSH key generation**: Creates RSA 4096-bit keys for repository access
- **SSH configuration**: Sets up Bitbucket access configuration
- **Proper permissions**: Ensures secure file permissions for SSH keys

### 💻 **Software Installation**
- **Visual Studio Code**: Added complete VSCode installation from Microsoft repository
- **Updated desktop shortcuts**: VSCode now launches the actual application instead of web version

### 🖥️ **Desktop Environment**
- **Epiphany Browser shortcut**: Added lightweight browser option
- **Enhanced XFCE configuration**: Added system configuration copying
- **Xorg server startup**: Added proper X11 server initialization with validation

### 🔧 **System Services**
- **Enhanced D-Bus handling**: Improved service directory management
- **XRDP verbose logging**: Added debug logging for troubleshooting
- **Xorg validation**: Added X11 functionality testing

### 🔍 **Monitoring Improvements**
- **Better error handling**: Enhanced restart mechanisms
- **Comprehensive logging**: More detailed status reporting

All existing functionality has been preserved, and the script now combines the best features from both files. The container will be more secure, feature-rich, and stable with these enhancements.