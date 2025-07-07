# �� FSBook Guacamole - QuickStart Guide

**Organization**: FSBook  
**Project**: FSBook Developer Infrastructure  
**Version**: 2025.07.04  
**Environment**: Containerized Remote Desktop System

---

## 📋 **Table of Contents**

1. [One-Command Setup](#one-command-setup)
2. [System Access](#system-access)
3. [User Management](#user-management)
4. [Environment Organization](#environment-organization)
5. [Common Commands](#common-commands)
6. [Troubleshooting](#troubleshooting)
7. [Advanced Setup](#advanced-setup)

---

## ⚡ **One-Command Setup**

### **Complete System Setup**

```bash
# Make scripts executable and run complete setup
chmod +x *.sh && ./complete-fsbook-setup.sh
```

**This single command will:**
- ✅ Download official Guacamole database schema
- ✅ Build Ubuntu RDP containers with development tools
- ✅ Setup MySQL database with proper schema
- ✅ Configure admin user (`guacadmin` / `guacadmin`)
- ✅ Start all services in correct order
- ✅ Create pre-configured RDP connections
- ✅ Verify everything is working

### **Quick Verification**

```bash
# Check all services are running
docker-compose ps

# Verify Guacamole accessibility
curl -s http://localhost:8080/guacamole/ > /dev/null && echo "✅ Guacamole is accessible"
```

---

## 🎯 **System Access**

### **Web Interface Access**

1. **Guacamole Web Interface**: `http://localhost:8080/guacamole`
2. **Admin Login**: `guacadmin` / `guacadmin`
3. **Start Developer Containers**:
   ```bash
   docker-compose up -d dev-john dev-jane
   ```

### **Pre-configured Developer Connections**

| Developer | Container Name    | RDP Port | Username | Password     |
|-----------|-------------------|----------|----------|--------------|
| john      | fsbook-dev-john   | 3391     | john     | developer123 |
| jane      | fsbook-dev-jane   | 3392     | jane     | developer123 |

### **Connection Methods**

#### **Method 1: Web Interface (Recommended)**
- Access through Guacamole web interface
- No additional software needed
- Works on any device with a browser

#### **Method 2: Direct RDP Client**
```bash
# Connect directly via RDP client
# Host: localhost:3391 (for john)
# Username: john
# Password: developer123
```

---

## 👥 **User Management**

### **Adding New Developers**

#### **Basic Developer Setup**
```bash
# Add new developer with automatic port assignment
./add-developer.sh alice 3393

# Start the new developer container
docker-compose up -d dev-alice
```

#### **RDP-Only Developer Setup**
```bash
# Add RDP-only developer with custom credentials
./add-developer-rdp-only.sh alice 3394 alice alice123 dev

# Start the container
docker-compose up -d dev-alice
```

#### **Advanced Developer Setup**
```bash
# Add developer with advanced configuration
./add-developer-advanced.sh charlie 3395 charlie charlie123 dev
```

### **Managing Existing Developers**

```bash
# List all developer containers
docker-compose ps | grep dev-

# Stop specific developer
docker-compose stop dev-john

# Start specific developer
docker-compose up -d dev-john

# Remove developer container (keeps data)
docker-compose rm dev-john

# View developer logs
docker-compose logs dev-john
```

---

## 📁 **Environment Organization**

### **Development Environment**
```bash
# Add developers to development environment
./add-developer-rdp-only.sh alice 3394 alice alice123 dev
./add-developer-rdp-only.sh bob 3395 bob bob123 dev
```

### **QA Environment**
```bash
# Add developers to QA environment
./add-developer-rdp-only.sh qauser1 3396 qauser1 qa123 qa
./add-developer-rdp-only.sh qauser2 3397 qauser2 qa456 qa
```

### **Production Environment**
```bash
# Add developers to production environment
./add-developer-rdp-only.sh produser1 3398 produser1 prod123 prod
./add-developer-rdp-only.sh produser2 3399 produser2 prod456 prod
```

### **Organized Folder Structure**
```
📂 dev/
  🖥️ john
  🖥️ jane
  🖥️ alice
  🖥️ bob

📂 qa/
  🖥️ qauser1
  🖥️ qauser2

📂 prod/
  🖥️ produser1
  🖥️ produser2
```

---

## 🛠️ **Common Commands**

### **Service Management**

```bash
# View all services status
docker-compose ps

# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart guacamole

# View service logs
docker-compose logs guacamole
```

### **Developer Container Operations**

```bash
# Start multiple containers
docker-compose up -d dev-john dev-jane dev-alice

# Stop all developer containers
docker-compose stop $(docker-compose ps -q | grep dev-)

# Update container image
docker-compose pull fsbook/ubuntu-rdp:latest
docker-compose up -d --force-recreate dev-john
```

### **Database Operations**

```bash
# Check database status
docker-compose exec guacamole-db mysql -u guacamole_user -pguacamole_password -e "SHOW TABLES FROM guacamole_db;"

# Backup database
docker-compose exec guacamole-db mysqldump -u guacamole_user -pguacamole_password guacamole_db > backup.sql
```

### **Management Interface**

```bash
# Access management interface
./manage-fsbook.sh

# Available options:
# - List all containers
# - Start/stop services
# - View logs
# - Database operations
# - User management
```

---

## 🔧 **Troubleshooting**

### **Common Issues**

#### **Guacamole Not Accessible**
```bash
# Check if services are running
docker-compose ps

# Check specific logs
docker-compose logs guacamole
docker-compose logs guacamole-db

# Restart services
docker-compose restart guacamole
```

#### **Database Connection Issues**
```bash
# Fix database configuration
./fix-database.sh

# Check database connectivity
docker-compose exec guacamole-db mysql -u guacamole_user -pguacamole_password -e "SELECT 1;"
```

#### **RDP Connection Failed**
```bash
# Check developer container status
docker-compose ps dev-john

# Restart developer container
docker-compose restart dev-john

# Check container logs
docker-compose logs dev-john
```

#### **Container Build Issues**
```bash
# Clean up and rebuild
docker system prune -f
docker build --no-cache -t fsbook/ubuntu-rdp:latest ./ubuntu-rdp/
```

### **Complete System Reset**

```bash
# Complete reset (if needed)
docker-compose down -v
./complete-fsbook-setup.sh
```

### **Docker Compose Validation Issues**

```bash
# Fix docker-compose override issues
chmod +x fix-override.sh
./fix-override.sh
```

---

## 🚀 **Advanced Setup**

### **Custom Container Configuration**

```bash
# Build custom Ubuntu RDP image
docker build -t fsbook/ubuntu-rdp:latest ./ubuntu-rdp/

# Start with custom configuration
docker-compose up -d --force-recreate
```

### **Performance Optimization**

```bash
# RDP-only setup for better performance
# Removes VNC overhead and optimizes RDP settings
./add-developer-rdp-only.sh developer 3400 dev devpass123 dev
```

### **Security Enhancements**

```bash
# Change default passwords
# Update admin credentials
# Configure firewall rules
# Set up SSL/TLS certificates
```

### **Monitoring and Maintenance**

```bash
# Monitor resource usage
docker stats

# Check system health
docker system df

# Clean up unused resources
docker system prune -f
```

---

## 🎉 **What You Get**

### **Complete Infrastructure**
- **Apache Guacamole** web interface for remote desktop access
- **MySQL Database** with complete schema and admin user
- **Ubuntu RDP Containers** with XFCE desktop environment
- **Pre-configured Connections** ready to use
- **Management Scripts** for easy administration
- **Persistent Storage** for each developer's data

### **Development Tools**
- **Desktop Environment**: XFCE4 with themes
- **Web Browsers**: Firefox, Chrome, Epiphany
- **Development Tools**: VS Code, Git, Python3, Node.js, npm
- **Text Editors**: vim, nano, gedit
- **Terminal**: gnome-terminal
- **Build Tools**: gcc, make, build-essential

### **Organizational Features**
- **Environment Separation**: dev, qa, prod folders
- **User Management**: Easy addition and removal of developers
- **Access Control**: Role-based permissions
- **Monitoring**: Comprehensive logging and health checks

---

## 📊 **System Architecture**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Web Browser   │───▶│   Guacamole      │───▶│  Developer          │
│   (Port 8080)   │    │   Web Interface  │    │  Containers         │
└─────────────────┘    └──────────────────┘    │  (RDP: 3391+)       │
                              │                 └─────────────────────┘
                              ▼                 
                       ┌──────────────────┐    
                       │     MySQL        │    
                       │    Database      │    
                       └──────────────────┘    
```

---

## 🔗 **Quick Reference**

### **Essential Commands**
```bash
# Setup
chmod +x *.sh && ./complete-fsbook-setup.sh

# Add User
./add-developer.sh [name] [port]

# Start Services
docker-compose up -d

# Check Status
docker-compose ps

# View Logs
docker-compose logs [service]

# Management
./manage-fsbook.sh

# Cleanup
./cleanup-reset.sh
```

### **Access Points**
- **Web Interface**: `http://localhost:8080/guacamole`
- **Admin Login**: `guacadmin` / `guacadmin`
- **Developer Ports**: `3391+` (RDP)

### **File Structure**
```
fsbook-guacamole/
├── complete-fsbook-setup.sh    # ⭐ Main setup script
├── docker-compose.yml          # Container definitions
├── add-developer.sh           # Add new developers
├── add-developer-rdp-only.sh  # RDP-only developers
├── manage-fsbook.sh           # Management interface
├── cleanup-reset.sh           # Reset and cleanup
├── ubuntu-rdp/                # Ubuntu RDP container
│   ├── Dockerfile
│   └── start.sh
├── init/                      # Database initialization
│   ├── 01-initdb.sql
│   ├── 02-setup-connections.sql
│   └── 03-create-connections.sql
└── FSBook-Guacamole-Complete-Guide.md
```

---

## 🎯 **Ready to Use!**

Your FSBook Guacamole system is now fully operational and ready for your development team!

**Next Steps:**
1. **Run the setup**: `./complete-fsbook-setup.sh`
2. **Access the web interface**: `http://localhost:8080/guacamole`
3. **Start developer containers**: `docker-compose up -d dev-john dev-jane`
4. **Add more developers**: `./add-developer.sh [name] [port]`

---

*For detailed documentation, see: `FSBook-Guacamole-Complete-Guide.md`*  
*Last Updated: July 4, 2025*  
*FSBook Organization*