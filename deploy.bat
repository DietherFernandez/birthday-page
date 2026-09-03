```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion

title GitHub Auto Deploy - LOCAL WINS
color 0A

REM ==========================================================
REM                 GITHUB DEPLOY CONFIG
REM ==========================================================

set "GITHUB_USERNAME=DietherFernandez"
set "GITHUB_REPOSITORY=birthday-page"
set "GITHUB_BRANCH=main"

REM Automatic commit message
set "COMMIT_MESSAGE=Update project"

set "REMOTE_URL=https://github.com/%GITHUB_USERNAME%/%GITHUB_REPOSITORY%.git"

REM ==========================================================
REM                    START DEPLOY
REM ==========================================================

cls

echo.
echo ==========================================================
echo             GITHUB AUTO DEPLOY
echo             LOCAL VERSION WINS
echo ==========================================================
echo.
echo Repository : %GITHUB_USERNAME%/%GITHUB_REPOSITORY%
echo Branch     : %GITHUB_BRANCH%
echo.
echo Starting deployment...
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
REM INITIALIZE REPOSITORY IF NEEDED
REM ==========================================================

echo [2/7] Checking local repository...

if not exist ".git" (

    echo No Git repository found.
    echo Initializing Git...

    git init

    if errorlevel 1 (
        color 0C
        echo.
        echo ERROR: Could not initialize Git.
        pause
        exit /b 1
    )
)

git branch -M "%GITHUB_BRANCH%"

echo Repository ready.
echo.

REM ==========================================================
REM CONFIGURE REMOTE
REM ==========================================================

echo [3/7] Configuring GitHub remote...

set "CURRENT_REMOTE="

for /f "delims=" %%R in ('git remote get-url origin 2^>nul') do (
    set "CURRENT_REMOTE=%%R"
)

if defined CURRENT_REMOTE (

    if /I not "!CURRENT_REMOTE!"=="%REMOTE_URL%" (
        echo Updating GitHub remote...
        git remote set-url origin "%REMOTE_URL%"
    ) else (
        echo GitHub remote already configured.
    )

) else (

    echo Adding GitHub remote...
    git remote add origin "%REMOTE_URL%"

)

echo.
echo Remote:
echo %REMOTE_URL%
echo.

REM ==========================================================
REM CANCEL ANY BROKEN OLD MERGE
REM ==========================================================

if exist ".git\MERGE_HEAD" (

    echo Previous merge detected.
    echo Aborting previous merge...

    git merge --abort >nul 2>&1

    echo Previous merge cleared.
    echo.
)

REM ==========================================================
REM SAVE LOCAL CHANGES FIRST
REM ==========================================================

echo [4/7] Saving local changes...

git add .

git diff --cached --quiet

if errorlevel 1 (

    git commit -m "%COMMIT_MESSAGE%"

    if errorlevel 1 (
        color 0C
        echo.
        echo ERROR: Could not create local commit.
        echo.
        pause
        exit /b 1
    )

    echo Local changes committed.

) else (

    echo No new local changes.

)

echo.

REM ==========================================================
REM FETCH GITHUB
REM ==========================================================

echo [5/7] Checking GitHub...

git fetch origin

if errorlevel 1 (
    color 0C
    echo.
    echo ==========================================================
    echo                     FETCH FAILED
    echo ==========================================================
    echo.
    echo Could not connect to GitHub.
    echo Check your internet connection and GitHub login.
    echo.
    pause
    exit /b 1
)

echo GitHub changes downloaded.
echo.

REM ==========================================================
REM CHECK IF REMOTE BRANCH EXISTS
REM ==========================================================

git show-ref --verify --quiet "refs/remotes/origin/%GITHUB_BRANCH%"

if errorlevel 1 (

    echo GitHub branch does not exist yet.
    echo Preparing first upload...
    echo.
    goto PUSH

)

REM ==========================================================
REM CHECK WHETHER LOCAL AND REMOTE ARE DIFFERENT
REM ==========================================================

set "LOCAL_AHEAD=0"
set "REMOTE_AHEAD=0"

for /f %%A in ('git rev-list --count "origin/%GITHUB_BRANCH%..HEAD" 2^>nul') do (
    set "LOCAL_AHEAD=%%A"
)

for /f %%A in ('git rev-list --count "HEAD..origin/%GITHUB_BRANCH%" 2^>nul') do (
    set "REMOTE_AHEAD=%%A"
)

echo ==========================================================
echo                    SYNC STATUS
echo ==========================================================
echo.
echo Local commits ahead  : !LOCAL_AHEAD!
echo GitHub commits ahead : !REMOTE_AHEAD!
echo.

REM ==========================================================
REM ALREADY SYNCHRONIZED
REM ==========================================================

if "!LOCAL_AHEAD!"=="0" if "!REMOTE_AHEAD!"=="0" (

    echo Local project and GitHub are already synchronized.
    goto SUCCESS

)

REM ==========================================================
REM ONLY LOCAL CHANGES
REM ==========================================================

if "!REMOTE_AHEAD!"=="0" (

    echo Only local changes detected.
    goto PUSH

)

REM ==========================================================
REM ONLY REMOTE CHANGES
REM
REM IMPORTANT:
REM LOCAL PROJECT IS ALWAYS THE SOURCE OF TRUTH.
REM We merge remote, then keep local files for conflicts.
REM ==========================================================

if "!LOCAL_AHEAD!"=="0" (

    echo GitHub contains changes not present locally.
    echo.
    echo Synchronizing while keeping LOCAL files...
    goto MERGE_LOCAL

)

REM ==========================================================
REM BOTH LOCAL AND REMOTE HAVE CHANGES
REM ==========================================================

echo Both local and GitHub contain changes.
echo.
echo Automatically keeping LOCAL files.
echo.

:MERGE_LOCAL

echo ==========================================================
echo             MERGING GITHUB CHANGES
echo             LOCAL FILES HAVE PRIORITY
echo ==========================================================
echo.

REM Merge GitHub into local branch.
REM Conflicts are expected and will be automatically resolved.

git merge "origin/%GITHUB_BRANCH%" --allow-unrelated-histories --no-edit

if not errorlevel 1 (

    echo.
    echo Merge completed without conflicts.
    goto PUSH

)

REM ==========================================================
REM AUTOMATICALLY RESOLVE ALL CONFLICTS USING LOCAL
REM ==========================================================

echo.
echo Merge conflicts detected.
echo.
echo Automatically keeping LOCAL versions...
echo.

git diff --name-only --diff-filter=U > "%TEMP%\birthday_conflicts.txt"

if not exist "%TEMP%\birthday_conflicts.txt" (
    color 0C
    echo.
    echo ERROR: Could not identify conflicted files.
    echo.
    git status
    pause
    exit /b 1
)

for /f "delims=" %%F in (%TEMP%\birthday_conflicts.txt) do (

    echo Keeping LOCAL:
    echo %%F

    git checkout --ours -- "%%F"

    if errorlevel 1 (
        color 0C
        echo.
        echo ERROR resolving:
        echo %%F
        pause
        exit /b 1
    )

    git add -- "%%F"
)

del "%TEMP%\birthday_conflicts.txt" >nul 2>&1

echo.
echo All conflicts resolved using LOCAL files.
echo.

REM ==========================================================
REM CHECK FOR REMAINING CONFLICTS
REM ==========================================================

git diff --name-only --diff-filter=U | findstr . >nul

if not errorlevel 1 (

    color 0C
    echo.
    echo ERROR: Some conflicts are still unresolved.
    echo.
    git status
    pause
    exit /b 1

)

REM ==========================================================
REM COMPLETE MERGE
REM ==========================================================

echo Completing merge...

git commit -m "Merge GitHub changes - keep local version"

if errorlevel 1 (

    color 0C
    echo.
    echo ERROR: Could not complete merge.
    echo.
    git status
    pause
    exit /b 1

)

echo Merge completed.
echo.

REM ==========================================================
REM PUSH
REM ==========================================================

:PUSH

echo [6/7] Uploading project to GitHub...
echo.

git push -u origin "%GITHUB_BRANCH%"

if errorlevel 1 (

    color 0C

    echo.
    echo ==========================================================
    echo                     PUSH FAILED
    echo ==========================================================
    echo.
    echo GitHub rejected the upload.
    echo.
    echo Your local files were NOT force-pushed.
    echo.
    echo Run deploy.bat again after checking the error above.
    echo.

    pause
    exit /b 1

)

REM ==========================================================
REM SUCCESS
REM ==========================================================

:SUCCESS

echo [7/7] Deployment finished.

color 0A

echo.
echo ==========================================================
echo                 DEPLOYMENT COMPLETE
echo ==========================================================
echo.
echo Your LOCAL project is now uploaded to GitHub.
echo.
echo Repository:
echo https://github.com/%GITHUB_USERNAME%/%GITHUB_REPOSITORY%
echo.
echo Branch:
echo %GITHUB_BRANCH%
echo.
echo Commit:
echo %COMMIT_MESSAGE%
echo.
echo ==========================================================
echo.
echo You can close this window.
echo.

pause
exit /b 0
```
