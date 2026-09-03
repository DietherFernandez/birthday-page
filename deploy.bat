@echo off
setlocal EnableExtensions EnableDelayedExpansion

title GitHub Auto Deploy
color 0A

REM ==========================================================
REM
REM                 GITHUB DEPLOY CONFIG
REM
REM        CHANGE ONLY THESE SETTINGS
REM
REM ==========================================================

set "GITHUB_USERNAME=DietherFernandez"
set "GITHUB_REPOSITORY=birthday-page"
set "GITHUB_BRANCH=main"

REM ==========================================================
REM
REM              DO NOT EDIT BELOW THIS LINE
REM
REM ==========================================================

set "REMOTE_URL=https://github.com/%GITHUB_USERNAME%/%GITHUB_REPOSITORY%.git"

echo.
echo ==========================================================
echo                 GITHUB AUTO DEPLOY
echo ==========================================================
echo.
echo   GitHub User : %GITHUB_USERNAME%
echo   Repository  : %GITHUB_REPOSITORY%
echo   Branch      : %GITHUB_BRANCH%
echo.
echo   Remote:
echo   %REMOTE_URL%
echo.
echo ==========================================================
echo.

REM ==========================================================
REM 1. CHECK GIT
REM ==========================================================

echo [1/7] Checking Git installation...
echo.

git --version >nul 2>&1

if errorlevel 1 (
    echo.
    echo ==========================================================
    echo ERROR: Git is not installed.
    echo ==========================================================
    echo.
    echo Install Git and make sure it is added to PATH.
    echo.
    pause
    exit /b 1
)

for /f "delims=" %%G in ('git --version') do echo %%G

echo.
echo Git is ready.
echo.

REM ==========================================================
REM 2. CHECK / INITIALIZE GIT REPOSITORY
REM ==========================================================

echo [2/7] Checking local Git repository...
echo.

if not exist ".git" (

    echo No Git repository found.
    echo.
    echo Initializing Git...
    echo.

    git init

    if errorlevel 1 (
        echo.
        echo ERROR: Git initialization failed.
        echo.
        pause
        exit /b 1
    )

    echo.
    echo Git repository initialized successfully.

) else (

    echo Git repository already exists.

)

echo.

REM ==========================================================
REM 3. CONFIGURE BRANCH
REM ==========================================================

echo [3/7] Configuring branch...
echo.

git branch -M "%GITHUB_BRANCH%"

if errorlevel 1 (
    echo.
    echo ERROR: Failed to configure branch.
    echo.
    pause
    exit /b 1
)

echo Current branch:
echo %GITHUB_BRANCH%
echo.

REM ==========================================================
REM 4. CONFIGURE GITHUB REMOTE
REM ==========================================================

echo [4/7] Configuring GitHub remote...
echo.

set "CURRENT_REMOTE="

for /f "delims=" %%R in ('git remote get-url origin 2^>nul') do (
    set "CURRENT_REMOTE=%%R"
)

if defined CURRENT_REMOTE (

    echo Existing remote:
    echo !CURRENT_REMOTE!
    echo.

    if /I "!CURRENT_REMOTE!"=="%REMOTE_URL%" (

        echo Remote is already configured correctly.

    ) else (

        echo Existing remote does not match.
        echo.
        echo Updating origin...
        echo.

        git remote set-url origin "%REMOTE_URL%"

        if errorlevel 1 (
            echo.
            echo ERROR: Failed to update GitHub remote.
            echo.
            pause
            exit /b 1
        )

        echo Remote updated successfully.

    )

) else (

    echo No origin remote found.
    echo.
    echo Adding GitHub repository:
    echo %REMOTE_URL%
    echo.

    git remote add origin "%REMOTE_URL%"

    if errorlevel 1 (
        echo.
        echo ERROR: Failed to add GitHub remote.
        echo.
        pause
        exit /b 1
    )

    echo Remote added successfully.

)

echo.

REM ==========================================================
REM 5. SHOW CURRENT STATUS
REM ==========================================================

echo [5/7] Checking project status...
echo.
echo ----------------------------------------------------------
echo.

git status

echo.
echo ----------------------------------------------------------
echo.

REM ==========================================================
REM 6. ASK FOR COMMIT MESSAGE
REM ==========================================================

echo [6/7] Preparing commit...
echo.
echo Enter your commit message.
echo.
echo Example:
echo   Updated birthday surprise
echo   Fixed mobile navigation
echo   Added new animation
echo.

set "COMMIT_MESSAGE="

set /p "COMMIT_MESSAGE=Commit message: "

REM Use default message if empty

if not defined COMMIT_MESSAGE (
    set "COMMIT_MESSAGE=Update project"
)

echo.
echo Commit message:
echo "%COMMIT_MESSAGE%"
echo.

REM ==========================================================
REM ADD ALL CHANGES
REM ==========================================================

echo Adding all changes...
echo.

git add .

if errorlevel 1 (
    echo.
    echo ==========================================================
    echo ERROR: git add failed.
    echo ==========================================================
    echo.
    pause
    exit /b 1
)

echo All changes staged successfully.
echo.

REM ==========================================================
REM CHECK WHETHER THERE ARE CHANGES
REM ==========================================================

git diff --cached --quiet

if errorlevel 1 (

    REM ======================================================
    REM CREATE COMMIT
    REM ======================================================

    echo Creating commit...
    echo.

    git commit -m "%COMMIT_MESSAGE%"

    if errorlevel 1 (
        echo.
        echo ==========================================================
        echo ERROR: Git commit failed.
        echo ==========================================================
        echo.
        pause
        exit /b 1
    )

    echo.
    echo Commit created successfully.

) else (

    echo No changes detected.
    echo Nothing new to commit.

)

echo.

REM ==========================================================
REM 7. PUSH TO GITHUB
REM ==========================================================

echo [7/7] Uploading to GitHub...
echo.
echo ----------------------------------------------------------
echo.
echo Repository:
echo %REMOTE_URL%
echo.
echo Branch:
echo %GITHUB_BRANCH%
echo.
echo ----------------------------------------------------------
echo.

git push -u origin "%GITHUB_BRANCH%"

if errorlevel 1 (

    echo.
    echo ==========================================================
    echo                 DEPLOYMENT FAILED
    echo ==========================================================
    echo.
    echo GitHub push was unsuccessful.
    echo.
    echo Possible reasons:
    echo.
    echo   1. The GitHub repository does not exist.
    echo   2. GitHub authentication is not configured.
    echo   3. You do not have permission to push.
    echo   4. The repository name is incorrect.
    echo   5. Your internet connection is unavailable.
    echo   6. GitHub rejected the push.
    echo.
    echo Repository:
    echo %REMOTE_URL%
    echo.
    echo Current Git remote:
    echo.

    git remote -v

    echo.
    echo ==========================================================
    echo.

    pause
    exit /b 1
)

REM ==========================================================
REM SUCCESS
REM ==========================================================

echo.
echo.
echo ==========================================================
echo.
echo              DEPLOYMENT SUCCESSFUL!
echo.
echo ==========================================================
echo.
echo   GitHub User : %GITHUB_USERNAME%
echo   Repository  : %GITHUB_REPOSITORY%
echo   Branch      : %GITHUB_BRANCH%
echo.
echo   Commit:
echo   %COMMIT_MESSAGE%
echo.
echo   Repository:
echo   %REMOTE_URL%
echo.
echo ==========================================================
echo.
echo Your changes have been uploaded to GitHub.
echo.
echo ==========================================================
echo.

pause
endlocal
exit /b 0