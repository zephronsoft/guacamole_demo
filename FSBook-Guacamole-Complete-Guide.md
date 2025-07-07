# 🏢 FSBook Guacamole - Complete Infrastructure Guide

**Organization**: FSBook  
**Project**: FSBook Developer Infrastructure  
**Version**: 2025.07.04  
**Environment**: Containerized Remote Desktop System

---

## 📋 **Table of Contents**

1. [Project Overview](#project-overview)
2. [System Architecture](#system-architecture)
3. [Quick Start](#quick-start)
4. [Detailed Setup Process](#detailed-setup-process)
5. [User Management](#user-management)
6. [Access and Usage](#access-and-usage)
7. [Management Operations](#management-operations)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Configuration](#advanced-configuration)
10. [Cleanup and Reset](#cleanup-and-reset)

---

## 🎯 **Project Overview**

FSBook Guacamole is a **containerized remote desktop infrastructure** that provides web-based access to Ubuntu development environments. It's designed as "Development-as-a-Service" where developers can access full Ubuntu desktops through their web browsers.

### **Key Features:**
- 🌐 **Web-based Remote Desktop** - Access through any browser
- 🔐 **Centralized Authentication** - Single sign-on for all developers
- 📦 **Containerized Environments** - Isolated developer workspaces
- 💾 **Persistent Storage** - Developer data preserved across sessions
- 🛠️ **Pre-configured Tools** - VS Code, browsers, development tools
- 📱 **Cross-platform Access** - Works on any device with web browser

### **What You Get:**
- Apache Guacamole web interface
- MySQL database for user management
- Ubuntu RDP containers with XFCE desktop
- Multiple browser support (Firefox, Chrome, Epiphany)
- Development tools (VS Code, Git, Python, Node.js)
- Automated setup and management scripts

---

## 🏗️ **System Architecture**

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

### **Core Components:**

#### **1. Apache Guacamole**
- Web-based remote desktop gateway
- Handles authentication and session management
- Accessible at `http://localhost:8080/guacamole`

#### **2. MySQL Database**
- Stores user credentials and connection configurations
- Manages permissions and access control
- Initialized with official Guacamole schema

#### **3. Ubuntu RDP Containers**
- Individual developer workspaces
- XFCE desktop environment
- Pre-installed development tools

#### **4. Management Scripts**
- Automated setup and configuration
- User management utilities
- Maintenance and cleanup tools

---

## 🚀 **Quick Start**

### **⚡ One-Command Complete Setup**

```bash
# Make all scripts executable and run complete setup
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

### **🎯 Immediate Access**

Once setup completes:

1. **Web Interface**: `http://localhost:8080/guacamole`
2. **Login**: `guacadmin` / `guacadmin`
3. **Start Developer Containers**:
   ```bash
   docker-compose up -d dev-john dev-jane
   ```

---

## 🔧 **Detailed Setup Process**

### **Step 1: Environment Preparation**

```bash
# Ensure Docker and Docker Compose are installed
docker --version
docker-compose --version

# Clone or navigate to the project directory
cd /path/to/fsbook-guacamole

# Make scripts executable
chmod +x *.sh
```

### **Step 2: Database Schema Setup**

```bash
# Download official Guacamole schema (done automatically by setup script)
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > init/01-initdb.sql

# Verify schema download
ls -la init/
```

### **Step 3: Container Image Building**

```bash
# Build Ubuntu RDP image
docker build -t fsbook/ubuntu-rdp:latest ./ubuntu-rdp/

# Verify image creation
docker images | grep fsbook
```

### **Step 4: Services Startup**

```bash
# Start database first
docker-compose up -d guacamole-db

# Wait for database initialization
sleep 60

# Start Guacamole services
docker-compose up -d guacd guacamole

# Start developer containers
docker-compose up -d dev-john dev-jane
```

### **Step 5: Verification**

```bash
# Check all services are running
docker-compose ps

# Verify Guacamole accessibility
curl -s http://localhost:8080/guacamole/ > /dev/null && echo "✅ Guacamole is accessible"

# Check database tables
docker-compose exec guacamole-db mysql -u guacamole_user -pguacamole_password -e "SHOW TABLES FROM guacamole_db;"
```

---

## 👥 **User Management**

### **Pre-configured Users**

| Developer | Container Name    | RDP Port | Username | Password     |
|-----------|-------------------|----------|----------|--------------|
| john      | fsbook-dev-john   | 3391     | john     | developer123 |
| jane      | fsbook-dev-jane   | 3392     | jane     | developer123 |

### **Adding New Developers**

#### **Method 1: Using Add Developer Script**

```bash
# Add a new developer with automatic port assignment
./add-developer.sh alice 3393

# Add a developer with custom ports
./add-developer.sh bob 3394 5904

# Start the new developer container
docker-compose up -d dev-alice
```

#### **Method 2: Using RDP-Only Script**

```bash
# Add RDP-only developer for development environment
./add-developer-rdp-only.sh alice 3394 alice alice123 dev

# Add RDP-only developer for QA environment
./add-developer-rdp-only.sh qauser1 3396 qauser1 qa123 qa

# Add RDP-only developer for production environment
./add-developer-rdp-only.sh produser1 3398 produser1 prod123 prod
```

#### **Method 3: Advanced Developer Setup**

```bash
# Add developer with advanced configuration
./add-developer-advanced.sh charlie 3395 charlie charlie123 dev
```

### **Managing Existing Users**

```bash
# List all developer containers
docker-compose ps | grep dev-

# Stop specific developer container
docker-compose stop dev-john

# Remove developer container (keeps data)
docker-compose rm dev-john

# Start developer container
docker-compose up -d dev-john

# View developer container logs
docker-compose logs dev-john
```

---

## 🌐 **Access and Usage**

### **Web Interface Access**

1. **Open Browser**: Navigate to `http://localhost:8080/guacamole`
2. **Login**: Use `guacadmin` / `guacadmin`
3. **Select Connection**: Choose from available developer connections
4. **Connect**: Click to establish RDP session

### **Direct RDP Access**

```bash
# Using RDP client directly
# Host: localhost
# Port: 339X (where X is developer number)
# Username: [developer_name]
# Password: developer123

# Example for john:
rdesktop localhost:3391 -u john -p developer123
```

### **Available Applications**

Each developer container includes:
- **🖥️ Desktop Environment**: XFCE4
- **🌐 Web Browsers**: Firefox, Chrome, Epiphany
- **💻 Development Tools**: VS Code, Git, Python3, Node.js
- **🛠️ Build Tools**: gcc, make, pip, npm
- **📝 Text Editors**: vim, nano
- **🗂️ File Management**: Thunar file manager

### **Browser Configuration**

#### **Firefox (Default)**
- Full-featured browser
- Pre-configured for development
- Extensions can be installed

#### **Chrome**
- Google Chrome browser
- Installed from official repository
- Full functionality available

#### **Epiphany (Lightweight)**
- GNOME Web browser
- Lightweight and fast
- Good for container environments

---

## 🛠️ **Management Operations**

### **Service Management**

```bash
# View all containers status
docker-compose ps

# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart guacamole

# View service logs
docker-compose logs guacamole
docker-compose logs guacamole-db
```

### **Database Management**

```bash
# Access MySQL database
docker-compose exec guacamole-db mysql -u guacamole_user -pguacamole_password guacamole_db

# Backup database
docker-compose exec guacamole-db mysqldump -u guacamole_user -pguacamole_password guacamole_db > backup.sql

# Restore database
docker-compose exec -T guacamole-db mysql -u guacamole_user -pguacamole_password guacamole_db < backup.sql
```

### **Container Management**

```bash
# Update developer container
docker-compose pull fsbook/ubuntu-rdp:latest
docker-compose up -d --force-recreate dev-john

# Access container shell
docker-compose exec dev-john bash

# Copy files to/from container
docker cp file.txt fsbook-dev-john:/home/john/
docker cp fsbook-dev-john:/home/john/file.txt ./
```

### **Using Management Script**

```bash
# Access management interface
./manage-fsbook.sh

# Available options:
# 1. List all containers
# 2. Start/stop services
# 3. View logs
# 4. Database operations
# 5. User management
```

---

## 🔍 **Troubleshooting**

### **Common Issues and Solutions**

#### **1. Guacamole Not Accessible**

```bash
# Check if Guacamole is running
docker-compose ps guacamole

# Restart Guacamole
docker-compose restart guacamole

# Check logs
docker-compose logs guacamole
```

#### **2. Database Connection Issues**

```bash
# Check database status
docker-compose ps guacamole-db

# Verify database initialization
docker-compose exec guacamole-db mysql -u guacamole_user -pguacamole_password -e "SHOW TABLES FROM guacamole_db;"

# Fix database issues
./fix-database.sh
```

#### **3. RDP Connection Failed**

```bash
# Check developer container status
docker-compose ps dev-john

# Restart developer container
docker-compose restart dev-john

# Check container logs
docker-compose logs dev-john
```

#### **4. Browser Issues in RDP**

```bash
# Access container and check browser installation
docker-compose exec dev-john bash

# Test browser launch
epiphany-browser --version
firefox --version

# Fix Epiphany display issues
./quick-fix-epiphany.sh
```

### **Database Troubleshooting**

```bash
# Reset database completely
./fix-database.sh

# Verify admin user exists
docker-compose exec guacamole-db mysql -u guacamole_user -pguacamole_password -e "SELECT * FROM guacamole_db.guacamole_user;"

# Fix override configurations
./fix-override.sh
```

### **Log Analysis**

```bash
# View all service logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f guacamole

# Filter logs by timestamp
docker-compose logs --since="2h" guacamole
```

---

## ⚙️ **Advanced Configuration**

### **Environment Variables**

```bash
# Database Configuration
MYSQL_ROOT_PASSWORD=guacamole_root_password
MYSQL_DATABASE=guacamole_db
MYSQL_USER=guacamole_user
MYSQL_PASSWORD=guacamole_password

# Developer Container Configuration
DEVELOPER_NAME=john
USER_PASSWORD=developer123
```

### **Port Assignments**

| Service              | Port  | Description                    |
|---------------------|-------|--------------------------------|
| Guacamole Web       | 8080  | Web interface                  |
| John RDP            | 3391  | John's RDP connection          |
| Jane RDP            | 3392  | Jane's RDP connection          |
| Custom Developer    | 3393+ | Additional developer ports     |

### **Volume Management**

```bash
# List all volumes
docker volume ls | grep fsbook

# Inspect volume
docker volume inspect dev-john-home

# Backup volume
docker run --rm -v dev-john-home:/data -v $(pwd):/backup alpine tar czf /backup/john-backup.tar.gz /data

# Restore volume
docker run --rm -v dev-john-home:/data -v $(pwd):/backup alpine tar xzf /backup/john-backup.tar.gz -C /
```

### **Custom Docker Compose Override**

```yaml
# docker-compose.override.yml
services:
  dev-newdeveloper:
    image: fsbook/ubuntu-rdp:latest
    container_name: fsbook-dev-newdeveloper
    environment:
      - DEVELOPER_NAME=newdeveloper
      - USER_PASSWORD=developer123
    ports:
      - "3395:3389"
    volumes:
      - dev-newdeveloper-home:/home/newdeveloper
      - dev-newdeveloper-workspace:/workspace
    networks:
      - fsbook-guacamole-network
    restart: unless-stopped
```

---

## 🧹 **Cleanup and Reset**

### **Cleanup Options**

```bash
# Run cleanup script
./cleanup-reset.sh

# Available cleanup levels:
# 1. Quick Reset - Stop containers, remove FSBook images and volumes
# 2. Full Reset - Everything + cleanup files and networks
# 3. Nuclear Reset - Everything + Docker system cleanup
# 4. Custom Cleanup - Choose specific components
```

### **Manual Cleanup Commands**

#### **Quick Reset**
```bash
# Stop all FSBook containers
docker-compose down

# Remove FSBook images
docker rmi $(docker images "fsbook/*" -q) 2>/dev/null

# Remove FSBook volumes
docker volume rm $(docker volume ls -q | grep fsbook) 2>/dev/null
```

#### **Full Reset**
```bash
# Stop and remove everything
docker-compose down -v

# Remove all FSBook resources
docker system prune -f

# Clean generated files
rm -f init/*.sql
rm -f docker-compose.override.yml
```

#### **Nuclear Reset**
```bash
# WARNING: This removes ALL Docker resources
docker system prune -a --volumes -f

# Remove all containers, images, volumes, networks
docker container prune -f
docker image prune -a -f
docker volume prune -f
docker network prune -f
```

### **Reset and Rebuild**

```bash
# Complete reset and fresh setup
./cleanup-reset.sh          # Choose Full Reset
./complete-fsbook-setup.sh   # Fresh setup
```

---

## 🔐 **Security Considerations**

### **Important Security Notes**

⚠️ **Production Security Checklist:**

1. **Change Default Passwords**
   ```bash
   # Update admin password in database
   # Change developer passwords
   # Use strong passwords
   ```

2. **Network Security**
   ```bash
   # Limit port exposure
   # Use VPN for remote access
   # Configure firewall rules
   ```

3. **Container Security**
   ```bash
   # Regular security updates
   # Monitor container access
   # Audit user permissions
   ```

### **Access Control**

```bash
# Admin access management
# User permission configuration
# Connection restrictions
```

---

## 📊 **Monitoring and Maintenance**

### **Health Checks**

```bash
# System health check
docker-compose ps
curl -s http://localhost:8080/guacamole/ > /dev/null && echo "✅ Guacamole OK"

# Database health
docker-compose exec guacamole-db mysql -u guacamole_user -pguacamole_password -e "SELECT 1;" > /dev/null && echo "✅ Database OK"

# Container health
docker-compose exec dev-john ps aux | grep xrdp && echo "✅ RDP OK"
```

### **Performance Monitoring**

```bash
# Resource usage
docker stats

# Container-specific stats
docker stats fsbook-dev-john

# Disk usage
docker system df
```

### **Maintenance Tasks**

```bash
# Regular maintenance
docker system prune -f                    # Weekly cleanup
docker-compose pull                       # Update images
docker-compose up -d --force-recreate    # Recreate containers
```

---

## 🎯 **Best Practices**

### **Setup Best Practices**
1. Always use the complete setup script for initial installation
2. Verify each step completes successfully
3. Keep backups of important data
4. Document any customizations

### **Operation Best Practices**
1. Regular monitoring of container health
2. Periodic cleanup of unused resources
3. Keep containers and images updated
4. Monitor disk usage and performance

### **Security Best Practices**
1. Change all default passwords
2. Use strong authentication
3. Limit network exposure
4. Regular security updates
5. Monitor access logs

### **Troubleshooting Best Practices**
1. Check logs first
2. Verify service status
3. Test connectivity
4. Use systematic approach
5. Document solutions

---

## 📞 **Support and Resources**

### **Quick Reference Commands**

```bash
# Setup
./complete-fsbook-setup.sh

# Add User
./add-developer.sh [name] [port]

# Management
./manage-fsbook.sh

# Cleanup
./cleanup-reset.sh

# Status Check
docker-compose ps
```

### **File Structure**

```
fsbook-guacamole/
├── complete-fsbook-setup.sh    # ⭐ Main setup script
├── docker-compose.yml          # Container definitions
├── add-developer.sh           # Add new developers
├── manage-fsbook.sh           # Management interface
├── cleanup-reset.sh           # Cleanup and reset
├── ubuntu-rdp/                # Ubuntu RDP container
│   ├── Dockerfile
│   └── start.sh
├── init/                      # Database initialization
│   ├── 01-initdb.sql
│   ├── 02-setup-connections.sql
│   └── 03-create-connections.sql
└── FSBook-Guacamole-Complete-Guide.md # This guide
```

---

## 🎉 **Conclusion**

FSBook Guacamole provides a comprehensive, containerized remote desktop solution that enables teams to have consistent, managed development environments accessible from anywhere through a web browser. With automated setup, user management, and maintenance tools, it delivers "Development-as-a-Service" capabilities for modern development teams.

**Key Benefits:**
- 🌐 **Universal Access** - Any device, any browser
- 🔐 **Secure** - Centralized authentication and access control
- 📦 **Scalable** - Easy to add new developers and environments
- 🛠️ **Complete** - All development tools pre-configured
- 🔧 **Maintainable** - Automated management and monitoring

**Get Started Now:**
```bash
chmod +x *.sh && ./complete-fsbook-setup.sh
```

Your FSBook Guacamole system will be ready in minutes! 🚀

---

*Last Updated: July 4, 2025*  
*Version: 1.0*  
*FSBook Organization* 