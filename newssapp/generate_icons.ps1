Write-Host "Generating app icons..." -ForegroundColor Green

# Run flutter pub get
Write-Host "`nRunning flutter pub get..." -ForegroundColor Yellow
& d:/flutter/bin/flutter pub get

# Run flutter_launcher_icons
Write-Host "`nGenerating icons with flutter_launcher_icons..." -ForegroundColor Yellow
& d:/flutter/bin/flutter pub run flutter_launcher_icons

Write-Host "`nDone! Now rebuild your app:" -ForegroundColor Green
Write-Host "  d:/flutter/bin/flutter clean" -ForegroundColor Cyan
Write-Host "  d:/flutter/bin/flutter run" -ForegroundColor Cyan
