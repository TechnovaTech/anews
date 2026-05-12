@echo off
echo Restarting Next.js server with CORS fixes...
cd "d:\asiaze news\news admin"
echo Killing existing Next.js processes...
taskkill /f /im node.exe 2>nul
timeout /t 2 /nobreak >nul
echo Starting Next.js development server...
start cmd /k "npm run dev"
echo Server should be starting on http://localhost:3000
echo CORS headers have been added to API routes.
pause