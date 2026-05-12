@echo off
echo Starting Asiaze Admin Dashboard with Real-Time Analytics...
echo.

echo Installing dependencies...
call npm install

echo.
echo Starting WebSocket server on port 3001...
start "WebSocket Server" cmd /k "npm run server"

timeout /t 3 /nobreak > nul

echo.
echo Starting Next.js dashboard on port 3000...
start "Dashboard" cmd /k "npm run dev"

echo.
echo Both servers are starting...
echo Dashboard: http://localhost:3000/dashboard
echo WebSocket: http://localhost:3001
echo.
pause