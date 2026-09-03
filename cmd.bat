@echo off
echo 🚀 One‑click deploy to GitHub...
cd /d "%~dp0"

:: Add the ignore file (only needed the first time)
if exist .gitignore (
    git add .gitignore
)

:: Add your birthday page and all photos
git add index.html
git add *.jpg *.jpeg *.png *.gif *.webp

:: Commit everything
git commit -m "Update birthday page 🎂"

:: Push to your repo
git push origin main

echo ✅ Done! Live at: https://dietherfernandez.github.io/birthday/
pause