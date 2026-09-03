@echo off
echo 🚀 Auto-committing to GitHub...

cd /d "%~dp0"

:: 1. If .gitignore exists, add it to stop tracking those junk files
if exist .gitignore (
    git add .gitignore
)

:: 2. Add all valid files (respects .gitignore, so Try.html won't be added)
git add .

:: 3. Commit changes (silently handles "nothing to commit")
git commit -m "birthday"

:: 4. Push to main
git push origin main

echo ✅ All done!
pause