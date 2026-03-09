@echo off
echo Installing flutter_launcher_icons...
call flutter pub get

echo.
echo Generating app icons...
call flutter pub run flutter_launcher_icons

echo.
echo Done! App icon has been set and app name changed to "asiazenews"
echo Please rebuild the app to see changes.
pause
