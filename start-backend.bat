@echo off
echo Starting Teekoob Backend...
echo.
echo Make sure you have:
echo 1. MySQL running on localhost:3306
echo 2. Created the 'teekoob' database
echo 3. Run 'npm install' in the backend folder
echo.
cd backend
echo Installing dependencies...
npm install
echo.
echo Starting the server...
npm run dev
pause
