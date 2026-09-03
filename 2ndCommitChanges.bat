@echo off
setlocal

title GitHub Deploy - DietherFernandez
color 0A

echo ==========================================
echo       GITHUB DEPLOYMENT
echo       User: DietherFernandez
echo ==========================================
echo.

REM Check if Git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git is not installed or not in PATH.
    echo Please install Git first.
    pause
    exit /b 1
)

REM Check if this is a Git repository
if not exist ".git" (
    echo [ERROR] This folder is not a Git repository.
    echo.
    echo Run:
    echo     git init
    echo.
    pause
    exit /b 1
)

echo [1/5] Checking Git status...
git status
if errorlevel 1 (
    echo.
    echo [ERROR] Git status failed.
    pause
    exit /b 1
)

echo.
echo [2/5] Adding all changes...
git add .
if errorlevel 1 (
    echo.
    echo [ERROR] Failed to stage changes.
    pause
    exit /b 1
)

echo.
echo [3/5] Creating commit...

set "COMMIT_MESSAGE=%~1"

if "%COMMIT_MESSAGE%"=="" (
    set "COMMIT_MESSAGE=Update website"
)

git diff --cached --quiet

if not errorlevel 1 (
    echo No changes to commit.
) else (
    git commit -m "%COMMIT_MESSAGE%"
    if errorlevel 1 (
        echo.
        echo [ERROR] Commit failed.
        pause
        exit /b 1
    )
)

echo.
echo [4/5] Detecting current branch...

for /f "delims=" %%B in ('git branch --show-current') do set "BRANCH=%%B"

if "%BRANCH%"=="" (
    echo [ERROR] Could not determine current branch.
    pause
    exit /b 1
)

echo Current branch: %BRANCH%

echo.
echo [5/5] Uploading changes to GitHub...
echo GitHub User: DietherFernandez
echo Branch: %BRANCH%
echo.

git push origin %BRANCH%

if errorlevel 1 (
    echo.
    echo ==========================================
    echo [ERROR] GitHub upload failed.
    echo ==========================================
    echo.
    echo Check:
    echo 1. Your GitHub login/authentication
    echo 2. The origin remote
    echo 3. Your internet connection
    echo 4. Your repository permissions
    echo.
    echo Current remote:
    git remote -v
    echo.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo       DEPLOYMENT SUCCESSFUL!
echo ==========================================
echo.
echo GitHub User: DietherFernandez
echo Branch: %BRANCH%
echo.
echo Your changes have been committed
echo and uploaded to GitHub successfully.
echo ==========================================
echo.

pause
endlocal