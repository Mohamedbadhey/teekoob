Write-Host "Starting Teekoob Backend..." -ForegroundColor Green
Write-Host ""
Write-Host "Make sure you have:" -ForegroundColor Yellow
Write-Host "1. MySQL running on localhost:3306" -ForegroundColor White
Write-Host "2. Created the 'teekoob' database" -ForegroundColor White
Write-Host "3. Run 'npm install' in the backend folder" -ForegroundColor White
Write-Host ""

Set-Location backend

Write-Host "Installing dependencies..." -ForegroundColor Cyan
npm install

Write-Host ""
Write-Host "Starting the server..." -ForegroundColor Cyan
npm run dev

Read-Host "Press Enter to exit"
