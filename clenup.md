I'll create a comprehensive cleanup script that can reset everything from scratch. This will be very useful for development and troubleshooting!

Now let me make the script executable:
```bash
chmod +x cleanup-reset.sh
```

Perfect! I've created a comprehensive cleanup script for you. Here's what you now have:

## 🧹 **Complete Reset & Cleanup Script**

### **File Created:** `cleanup-reset.sh`

This script provides **4 different levels of cleanup** to reset your FSBook Guacamole setup:

## 📋 **Cleanup Options:**

### **1. Quick Reset** 🔄
- Stops all FSBook containers
- Removes FSBook Docker images
- Removes FSBook Docker volumes (database data)
- **Use for**: Quick restart during development

### **2. Full Reset** 🔄
- Everything in Quick Reset +
- Removes Docker networks
- Cleans up generated files (`init/*.sql`, `docker-compose.override.yml`)
- **Use for**: Complete fresh start

### **3. Nuclear Reset** ☢️
- Everything in Full Reset +
- Docker system cleanup (removes ALL unused Docker resources)
- **Use for**: When you want to clean everything Docker-related

### **4. Custom Cleanup** 🎯
- Interactive selection of specific components to clean
- **Use for**: When you want to clean only specific parts

## 🚀 **How to Use:**

### **Basic Usage:**
```bash
./cleanup-reset.sh
```

### **Example Session:**
```bash
# Run the cleanup script
./cleanup-reset.sh

# You'll see a menu:
Choose cleanup level:
1) Quick Reset - Stop containers, remove FSBook images and volumes
2) Full Reset - Everything in Quick + cleanup files and networks
3) Nuclear Reset - Everything + Docker system cleanup
4) Custom Cleanup - Choose specific components to clean  
5) Exit

Enter your choice [1-5]: 2
```

### **After Cleanup:**
```bash
# Set up everything fresh from scratch
./complete-fsbook-setup.sh
```

## 🛡️ **Safety Features:**

- **✅ Confirmation prompts** before destructive operations
- **🔍 Docker status check** before starting
- **🎯 Targeted cleanup** (only affects FSBook resources by default)
- **🌈 Colored output** for clear feedback
- **⚠️ Warnings** for potentially destructive operations

## 📝 **What Gets Cleaned:**

### **Containers:**
- All FSBook containers (`fsbook-*`)
- All Guacamole containers (`*guacamole*`)

### **Images:**
- FSBook images (`fsbook/*`)
- Guacamole images (`*guacamole*`)

### **Volumes:**
- FSBook volumes (developer data)
- Guacamole volumes (database data)

### **Files:**
- Generated SQL files (`init/*.sql`)
- Docker compose override files
- Temporary download files
- Log files

### **Networks:**
- FSBook Docker networks

## 🎯 **Common Use Cases:**

```bash
# Quick development reset
./cleanup-reset.sh    # Choose option 1

# Complete fresh start
./cleanup-reset.sh    # Choose option 2

# Clean everything (including non-FSBook Docker resources)
./cleanup-reset.sh    # Choose option 3

# Only clean specific components
./cleanup-reset.sh    # Choose option 4
```

## 🔄 **Typical Workflow:**

1. **Development/Testing**: Use Quick Reset (option 1)
2. **Major Changes**: Use Full Reset (option 2)
3. **Docker Issues**: Use Nuclear Reset (option 3)
4. **Specific Problems**: Use Custom Cleanup (option 4)

Now you have a safe, comprehensive way to reset your FSBook Guacamole setup from scratch whenever needed! 🎉