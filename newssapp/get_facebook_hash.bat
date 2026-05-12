@echo off
echo Generating Facebook Key Hash...
echo.
echo Make sure you have OpenSSL installed
echo.
keytool -exportcert -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" | openssl sha1 -binary | openssl base64
echo.
echo For release keystore, use:
echo keytool -exportcert -alias YOUR_RELEASE_KEY_ALIAS -keystore YOUR_RELEASE_KEYSTORE_PATH | openssl sha1 -binary | openssl base64
pause
