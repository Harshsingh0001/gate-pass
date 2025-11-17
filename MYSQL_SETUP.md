# 🗄️ MySQL Setup Guide for Windows

## Step 1: Download MySQL

1. Visit: https://www.mysql.com/downloads/
2. Click on "MySQL Community Server"
3. Download the **Windows MSI Installer** (latest version)
4. File should be named like: `mysql-installer-community-8.x.x.x.msi`

## Step 2: Install MySQL

1. Run the downloaded `.msi` file
2. Click "Next" on welcome screen
3. Choose "Custom" setup type
4. Select:
   - ✅ MySQL Server (latest)
   - ✅ MySQL Workbench (optional but helpful)
5. Click "Next" and continue
6. Choose "Standalone" configuration
7. Click "Next"
8. On "Configure MySQL Server" page:
   - **Port:** 3306 (default)
   - **Config Type:** Development Machine
9. Click "Next"
10. On "MySQL Server User Accounts":
    - Username: `root` (default)
    - Password: **IMPORTANT - REMEMBER THIS!** (set a password like `root123` or `password123`)
    - Confirm password
11. Click "Next"
12. Configure MySQL as Windows Service (leave default)
13. Click "Finish"

## Step 3: Verify MySQL is Running

### On Windows:
1. Press `Windows Key + R`
2. Type: `services.msc`
3. Look for **"MySQL80"** (or your version) in the list
4. It should show **Status: Running**

If not running, right-click it and select "Start"

## Step 4: Add MySQL to System PATH (Optional but Recommended)

This allows you to use `mysql` command from anywhere in PowerShell.

### Steps:
1. Press `Windows Key` and search for "Environment Variables"
2. Click "Edit the system environment variables"
3. Click "Environment Variables" button at bottom
4. Under "System variables", find "Path" and click "Edit"
5. Click "New"
6. Enter the MySQL bin path:
   - Default: `C:\Program Files\MySQL\MySQL Server 8.0\bin`
   - (Adjust "8.0" if you installed a different version)
7. Click OK on all dialogs

### Verify PATH is set:
Open PowerShell and run:
```powershell
mysql --version
```

Should show: `mysql Ver 8.0.x ... (MySQL Community Server - GPL)`

## Step 5: Connect to MySQL

Open PowerShell and run:

```powershell
mysql -u root -p
```

It will ask for password. Enter the password you set during installation.

You should see:
```
Welcome to the MySQL monitor. Commands end with ; or \g.
mysql>
```

## Next Steps

Once connected to MySQL, follow the database setup steps in QUICK_START.md

Type `exit` to quit MySQL.

---

**Having issues?** 
- Make sure MySQL service is running (check services.msc)
- Double-check your password
- Try reinstalling if nothing works
