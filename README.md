# Digital Gate Pass System

This repository contains a simple Digital Gate Pass System prototype (frontend + backend).

Overview:
- Frontend: static HTML/CSS/JS files (`index.html`, `2.html`, `3.html`, `4.html`, `api.js`) served via a small static server.
- Backend: Node.js + Express server in the `backend/` folder (`backend/server.js`) with MySQL persistence.
- Database: MySQL schema available in `setup_database.sql`.

Quick start (local):

1. Prepare MySQL and import `setup_database.sql`.
2. Install backend dependencies and start the server:

```powershell
cd backend
npm install
npm run dev
```

3. Serve frontend (from project root):

```powershell
# using Node static server (serve-static.js) or the provided static server script
node serve-static.js
# or if you have Python available:
python -m http.server 8000
```

4. Open `http://localhost:8000` in your browser.

Notes:
- `.env` contains DB credentials and should not be committed.
- Use admin account created during setup or register a new admin via the API.

If you want, I can initialize the git repo here and push to your GitHub — please provide the repository URL (or let me create a new GitHub repo for you and provide credentials/token).
