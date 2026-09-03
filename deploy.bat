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

cls

echo.
echo ==========================================================
echo                  GITHUB AUTO DEPLOY
echo ==========================================================
echo.
echo Repository : %GITHUB_USERNAME%/%GITHUB_REPOSITORY%
echo Branch     : %GITHUB_BRANCH%
echo.

REM ==========================================================
REM CHECK GIT
REM ==========================================================

echo [1/7] Checking Git...

git --version >nul 2>&1

if errorlevel 1 (
    color 0C
    echo.
    echo ERROR: Git is not installed or not available in PATH.
    echo.
    pause
    exit /b 1
)

echo Git detected.
echo.

REM ==========================================================
REM CHECK PROJECT DIRECTORY
REM ==========================================================

echo [2/7] Checking project...

if not exist "%CD%" (
    echo ERROR: Project directory not found.
    pause
    exit /b 1
)

echo Project directory:
echo %CD%
echo.

REM ==========================================================
REM INITIALIZE GIT
REM ==========================================================

echo [3/7] Checking Git repository...

if not exist ".git" (
    echo.
    echo Git repository not found.
    echo Initializing Git repository...
    echo.

    git init

    if errorlevel 1 (
        color 0C
        echo.
        echo ERROR: Failed to initialize Git.
        pause
        exit /b 1
    )

    echo Git repository initialized.
)

echo.

REM ==========================================================
REM SET BRANCH
REM ==========================================================

echo Setting branch to %GITHUB_BRANCH%...

git branch -M "%GITHUB_BRANCH%"

if errorlevel 1 (
    color 0C
    echo ERROR: Failed to configure branch.
    pause
    exit /b 1
)

echo Branch configured.
echo.

REM ==========================================================
REM CONFIGURE REMOTE
REM ==========================================================

echo Configuring GitHub remote...

set "CURRENT_REMOTE="

for /f "delims=" %%R in ('git remote get-url origin 2^>nul') do (
    set "CURRENT_REMOTE=%%R"
)

if defined CURRENT_REMOTE (

    echo Existing remote:
    echo !CURRENT_REMOTE!
    echo.

    if /I "!CURRENT_REMOTE!"=="%REMOTE_URL%" (

        echo Remote is already correct.

    ) else (

        echo Updating remote...
        git remote set-url origin "%REMOTE_URL%"

        if errorlevel 1 (
            color 0C
            echo.
            echo ERROR: Failed to update GitHub remote.
            pause
            exit /b 1
        )

        echo Remote updated.
    )

) else (

    echo No GitHub remote found.
    echo Adding remote...

    git remote add origin "%REMOTE_URL%"

    if errorlevel 1 (
        color 0C
        echo.
        echo ERROR: Failed to add GitHub remote.
        pause
        exit /b 1
    )

    echo GitHub remote added.
)

echo.

REM ==========================================================
REM SHOW STATUS
REM ==========================================================

echo [4/7] Checking project status...
echo.

git status

echo.

REM ==========================================================
REM COMMIT MESSAGE
REM ==========================================================

echo ==========================================================
echo                    COMMIT MESSAGE
echo ==========================================================
echo.

set "COMMIT_MESSAGE="

set /p "COMMIT_MESSAGE=Enter commit message: "

if not defined COMMIT_MESSAGE (
    set "COMMIT_MESSAGE=Update project"
)

echo.
echo Commit message:
echo %COMMIT_MESSAGE%
echo.

REM ==========================================================
REM ADD FILES
REM ==========================================================

echo [5/7] Adding files...

git add .

if errorlevel 1 (
    color 0C
    echo.
    echo ERROR: Failed to add files.
    pause
    exit /b 1
)

echo Files added.
echo.

REM ==========================================================
REM CHECK FOR CHANGES
REM ==========================================================

echo Checking for changes...

git diff --cached --quiet

if errorlevel 1 (

    echo Changes detected.
    echo Creating commit...

    git commit -m "%COMMIT_MESSAGE%"

    if errorlevel 1 (
        color 0C
        echo.
        echo ERROR: Commit failed.
        pause
        exit /b 1
    )

    echo.
    echo Commit created successfully.

) else (

    echo.
    echo No new changes to commit.
    echo Continuing to GitHub...

)

echo.

REM ==========================================================
REM FIRST PUSH ATTEMPT
REM ==========================================================

echo [6/7] Uploading to GitHub...
echo.

git push -u origin "%GITHUB_BRANCH%"

if not errorlevel 1 (
    goto SUCCESS
)

REM ==========================================================
REM PUSH FAILED
REM AUTOMATIC REMOTE SYNC
REM ==========================================================

echo.
echo ==========================================================
echo                 PUSH WAS REJECTED
echo ==========================================================
echo.
echo GitHub contains changes that are not in your local copy.
echo.
echo This commonly happens when the GitHub repository was
echo created with a README, .gitignore, license, or other
echo files before this local project was connected.
echo.
echo Attempting to synchronize with GitHub...
echo.

REM ==========================================================
REM FETCH REMOTE
REM ==========================================================

echo Fetching GitHub changes...

git fetch origin

if errorlevel 1 (
    color 0C
    echo.
    echo ERROR: Could not fetch from GitHub.
    echo.
    echo Possible causes:
    echo - No internet connection
    echo - Incorrect repository name
    echo - GitHub authentication problem
    echo - Repository does not exist
    echo.
    pause
    exit /b 1
)

echo.
echo GitHub changes downloaded.
echo.

REM ==========================================================
REM CHECK REMOTE BRANCH
REM ==========================================================

git show-ref --verify --quiet "refs/remotes/origin/%GITHUB_BRANCH%"

if errorlevel 1 (

    echo Remote branch does not exist yet.
    echo Retrying push...

    git push -u origin "%GITHUB_BRANCH%"

    if errorlevel 1 (
        color 0C
        echo.
        echo ERROR: Push failed.
        pause
        exit /b 1
    )

    goto SUCCESS
)

REM ==========================================================
REM MERGE REMOTE CHANGES
REM ==========================================================

echo ==========================================================
echo                 MERGING GITHUB CHANGES
echo ==========================================================
echo.

git merge "origin/%GITHUB_BRANCH%" --allow-unrelated-histories --no-edit

if errorlevel 1 (

    color 0C

    echo.
    echo ==========================================================
    echo                    MERGE CONFLICT
    echo ==========================================================
    echo.
    echo GitHub and your local project contain conflicting files.
    echo.
    echo The automatic merge has been stopped to protect your work.
    echo.
    echo Run:
    echo.
    echo     git status
    echo.
    echo Resolve the conflicts, then run:
    echo.
    echo     git add .
    echo     git commit -m "Resolve merge conflicts"
    echo     git push -u origin %GITHUB_BRANCH%
    echo.

    pause
    exit /b 1
)

echo.
echo GitHub changes merged successfully.
echo.

REM ==========================================================
REM PUSH AFTER MERGE
REM ==========================================================

echo Uploading merged project to GitHub...
echo.

git push -u origin "%GITHUB_BRANCH%"

if errorlevel 1 (
    color 0C
    echo.
    echo ==========================================================
    echo                    PUSH FAILED
    echo ==========================================================
    echo.
    echo The merge completed, but the final push failed.
    echo.
    echo Run:
    echo.
    echo     git status
    echo     git push -u origin %GITHUB_BRANCH%
    echo.
    pause
    exit /b 1
)

goto SUCCESS

REM ==========================================================
REM SUCCESS
REM ==========================================================

:SUCCESS

color 0A

echo.
echo ==========================================================
echo                    DEPLOY SUCCESSFUL
echo ==========================================================
echo.
echo GitHub repository:
echo https://github.com/%GITHUB_USERNAME%/%GITHUB_REPOSITORY%
echo.
echo Branch:
echo %GITHUB_BRANCH%
echo.
echo Your latest changes are now uploaded.
echo.
echo ==========================================================
echo.

pause
exit /b 0