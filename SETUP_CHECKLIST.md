# ✅ MySQL Setup Checklist

## Phase 1: MySQL Installation
- [ ] Download MySQL from https://www.mysql.com/downloads/
- [ ] Run the MSI installer
- [ ] Choose "Custom" installation
- [ ] Select "MySQL Server"
- [ ] Set root password (remember it!)
- [ ] Complete installation
- [ ] Verify service is running (Windows Services)

## Phase 2: Add to System PATH (Windows)
- [ ] Press Windows Key + R → type `services.msc`
- [ ] Find "MySQL80" or your version
- [ ] Verify it shows "Running"
- [ ] Press Windows Key → search "Environment Variables"
- [ ] Click "Edit system environment variables"
- [ ] Click "Environment Variables" button
- [ ] Find "Path" in System variables → Click "Edit"
- [ ] Click "New" and add: `C:\Program Files\MySQL\MySQL Server 8.0\bin`
- [ ] Click OK on all dialogs
- [ ] Restart PowerShell to apply changes

## Phase 3: Create Database

### Option 1: Using MySQL Command Line
- [ ] Open PowerShell
- [ ] Run: `mysql -u root -p`
- [ ] Enter your root password
- [ ] Copy-paste all SQL from `setup_database.sql`
- [ ] Press Enter to execute

### Option 2: Using MySQL Workbench
- [ ] Open MySQL Workbench
- [ ] Connect to localhost
- [ ] Open new query tab
- [ ] Copy-paste all SQL from `setup_database.sql`
- [ ] Click Execute (lightning bolt)

### Option 3: Import SQL File
- [ ] Open PowerShell
- [ ] Run: `mysql -u root -p gate_pass_system < setup_database.sql`
- [ ] Enter your root password

## Phase 4: Verify Database Setup
- [ ] Open PowerShell
- [ ] Run: `mysql -u root -p`
- [ ] Run: `USE gate_pass_system;`
- [ ] Run: `SHOW TABLES;`
- [ ] Should see: visitors, admins, security_staff, qr_codes, visitor_logs

## Phase 5: Update Backend Configuration
- [ ] Open `backend\.env`
- [ ] Set `DB_PASSWORD=` to your MySQL root password
- [ ] Save file

## Phase 6: Start Backend
- [ ] Open PowerShell in project folder
- [ ] Run: `cd backend`
- [ ] Run: `npm install`
- [ ] Run: `npm start`
- [ ] Verify: "✅ Database connected successfully"

## Phase 7: Test Frontend
- [ ] Open `index.html` in browser
- [ ] Try registering a visitor
- [ ] Should work without errors!

---

## If You Get Stuck

### MySQL not found
- [ ] Add MySQL to PATH (Phase 2)
- [ ] Restart PowerShell after adding to PATH

### Can't connect to database
- [ ] Verify MySQL is running (`services.msc`)
- [ ] Verify password is correct in `.env`
- [ ] Check database name is `gate_pass_system`

### Backend won't start
- [ ] Run `npm install` in backend folder
- [ ] Check `.env` file has correct credentials
- [ ] Look for error messages in console

### Frontend shows error
- [ ] Check console (F12) for error messages
- [ ] Verify backend is running (`npm start`)
- [ ] Verify database has tables (`SHOW TABLES;`)

---

**All done?** Your system is ready to use! 🎉
