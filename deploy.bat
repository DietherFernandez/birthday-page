```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion

title GitHub Auto Deploy v2
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

:START
cls

echo.
echo ==========================================================
echo                  GITHUB AUTO DEPLOY v2
echo ==========================================================
echo.
echo Repository : %GITHUB_USERNAME%/%GITHUB_REPOSITORY%
echo Branch     : %GITHUB_BRANCH%
echo.

REM ==========================================================
REM CHECK GIT
REM ==========================================================

echo [1/8] Checking Git...

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
REM CHECK REPOSITORY
REM ==========================================================

echo [2/8] Checking local Git repository...

if not exist ".git" (

    echo.
    echo No Git repository detected.
    echo Initializing repository...
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
REM CONFIGURE BRANCH
REM ==========================================================

echo Configuring branch...

git branch -M "%GITHUB_BRANCH%"

if errorlevel 1 (
    color 0C
    echo.
    echo ERROR: Could not configure branch.
    pause
    exit /b 1
)

echo Branch: %GITHUB_BRANCH%
echo.

REM ==========================================================
REM CONFIGURE REMOTE
REM ==========================================================

echo [3/8] Configuring GitHub remote...

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

        echo Updating GitHub remote...

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

    echo No origin remote found.
    echo Adding GitHub remote...

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

echo [4/8] Checking project status...
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

echo [5/8] Adding project files...

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
REM CREATE COMMIT IF NEEDED
REM ==========================================================

echo Checking for local changes...

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

    echo No new local changes detected.

)

echo.

REM ==========================================================
REM FETCH GITHUB
REM ==========================================================

echo [6/8] Checking GitHub for remote changes...
echo.

git fetch origin

if errorlevel 1 (
    color 0C
    echo.
    echo ==========================================================
    echo                    FETCH FAILED
    echo ==========================================================
    echo.
    echo Could not connect to GitHub.
    echo.
    echo Check:
    echo - Internet connection
    echo - Repository name
    echo - GitHub authentication
    echo - Repository permissions
    echo.
    pause
    exit /b 1
)

echo GitHub synchronization check completed.
echo.

REM ==========================================================
REM CHECK WHETHER REMOTE BRANCH EXISTS
REM ==========================================================

git show-ref --verify --quiet "refs/remotes/origin/%GITHUB_BRANCH%"

if errorlevel 1 (

    echo.
    echo GitHub branch does not exist yet.
    echo The local branch will be uploaded.
    echo.

    goto PUSH

)

REM ==========================================================
REM CHECK LOCAL / REMOTE DIFFERENCES
REM ==========================================================

for /f %%A in ('git rev-list --count "origin/%GITHUB_BRANCH%..HEAD" 2^>nul') do set "LOCAL_AHEAD=%%A"

for /f %%A in ('git rev-list --count "HEAD..origin/%GITHUB_BRANCH%" 2^>nul') do set "REMOTE_AHEAD=%%A"

if not defined LOCAL_AHEAD set "LOCAL_AHEAD=0"
if not defined REMOTE_AHEAD set "REMOTE_AHEAD=0"

echo ==========================================================
echo                  SYNC INFORMATION
echo ==========================================================
echo.
echo Local commits ahead  : %LOCAL_AHEAD%
echo GitHub commits ahead : %REMOTE_AHEAD%
echo.

REM ==========================================================
REM NOTHING TO PUSH
REM ==========================================================

if "%LOCAL_AHEAD%"=="0" if "%REMOTE_AHEAD%"=="0" (

    echo Local project and GitHub are already synchronized.
    echo.
    goto SUCCESS

)

REM ==========================================================
REM LOCAL ONLY
REM ==========================================================

if "%REMOTE_AHEAD%"=="0" (

    echo Local project contains new commits.
    echo Ready to upload.
    echo.

    goto PUSH

)

REM ==========================================================
REM REMOTE ONLY
REM ==========================================================

if "%LOCAL_AHEAD%"=="0" (

    echo GitHub contains commits that are not local.
    echo.
    goto REMOTE_ONLY

)

REM ==========================================================
REM BOTH SIDES HAVE CHANGES
REM ==========================================================

echo Both local and GitHub contain changes.
echo A merge may be required.
echo.

goto CONFLICT_MENU

REM ==========================================================
REM REMOTE ONLY MENU
REM ==========================================================

:REMOTE_ONLY

echo ==========================================================
echo               GITHUB HAS NEWER CHANGES
echo ==========================================================
echo.
echo Choose an action:
echo.
echo [L] Keep LOCAL version
echo [R] Keep REMOTE/GitHub version
echo [C] Cancel
echo.

set "CHOICE="
set /p "CHOICE=Choice: "

if /I "%CHOICE%"=="L" goto KEEP_LOCAL
if /I "%CHOICE%"=="R" goto KEEP_REMOTE
if /I "%CHOICE%"=="C" goto CANCEL

echo.
echo Invalid choice.
echo Please enter L, R, or C.
echo.
pause
goto REMOTE_ONLY

REM ==========================================================
REM CONFLICT MENU
REM ==========================================================

:CONFLICT_MENU

echo ==========================================================
echo                    SYNC CONFLICT
echo ==========================================================
echo.
echo Your local project and GitHub both contain changes.
echo.
echo Choose how to resolve the conflict:
echo.
echo [L] Keep LOCAL files
echo [R] Keep REMOTE/GitHub files
echo [C] Cancel
echo.

set "CHOICE="
set /p "CHOICE=Choice: "

if /I "%CHOICE%"=="L" goto KEEP_LOCAL
if /I "%CHOICE%"=="R" goto KEEP_REMOTE
if /I "%CHOICE%"=="C" goto CANCEL

echo.
echo Invalid choice.
echo Please enter L, R, or C.
echo.
pause
goto CONFLICT_MENU

REM ==========================================================
REM KEEP LOCAL
REM ==========================================================

:KEEP_LOCAL

echo.
echo ==========================================================
echo                  KEEPING LOCAL VERSION
echo ==========================================================
echo.

REM If histories are unrelated, merge first.
git merge "origin/%GITHUB_BRANCH%" --allow-unrelated-histories --no-edit

if not errorlevel 1 (
    echo.
    echo Merge completed without conflicts.
    goto PUSH
)

echo.
echo Conflicts detected.
echo.

REM Get conflicted files
git diff --name-only --diff-filter=U > "%TEMP%\github_conflicts.txt"

if not exist "%TEMP%\github_conflicts.txt" (
    color 0C
    echo ERROR: Could not identify conflicted files.
    pause
    exit /b 1
)

echo Conflicted files:
echo.

type "%TEMP%\github_conflicts.txt"

echo.
echo Replacing conflicted files with LOCAL versions...
echo.

for /f "delims=" %%F in (%TEMP%\github_conflicts.txt) do (
    echo Keeping LOCAL: %%F
    git checkout --ours -- "%%F"
    git add -- "%%F"
)

del "%TEMP%\github_conflicts.txt" >nul 2>&1

echo.
echo Local versions selected.
echo Creating merge commit...

git commit -m "Merge GitHub changes - keep local version"

if errorlevel 1 (
    color 0C
    echo.
    echo ERROR: Could not create merge commit.
    echo.
    git status
    pause
    exit /b 1
)

echo.
echo Merge resolved using LOCAL files.
echo.

goto PUSH

REM ==========================================================
REM KEEP REMOTE
REM ==========================================================

:KEEP_REMOTE

echo.
echo ==========================================================
echo                 KEEPING REMOTE VERSION
echo ==========================================================
echo.

git merge "origin/%GITHUB_BRANCH%" --allow-unrelated-histories --no-edit

if not errorlevel 1 (
    echo.
    echo Merge completed without conflicts.
    goto PUSH
)

echo.
echo Conflicts detected.
echo.

git diff --name-only --diff-filter=U > "%TEMP%\github_conflicts.txt"

if not exist "%TEMP%\github_conflicts.txt" (
    color 0C
    echo ERROR: Could not identify conflicted files.
    pause
    exit /b 1
)

echo Conflicted files:
echo.

type "%TEMP%\github_conflicts.txt"

echo.
echo Replacing conflicted files with REMOTE versions...
echo.

for /f "delims=" %%F in (%TEMP%\github_conflicts.txt) do (
    echo Keeping REMOTE: %%F
    git checkout --theirs -- "%%F"
    git add -- "%%F"
)

del "%TEMP%\github_conflicts.txt" >nul 2>&1

echo.
echo Remote versions selected.
echo Creating merge commit...

git commit -m "Merge GitHub changes - keep remote version"

if errorlevel 1 (
    color 0C
    echo.
    echo ERROR: Could not create merge commit.
    echo.
    git status
    pause
    exit /b 1
)

echo.
echo Merge resolved using REMOTE files.
echo.

goto PUSH

REM ==========================================================
REM PUSH
REM ==========================================================

:PUSH

echo [7/8] Uploading project to GitHub...
echo.

git push -u origin "%GITHUB_BRANCH%"

if errorlevel 1 (

    color 0C

    echo.
    echo ==========================================================
    echo                    PUSH FAILED
    echo ==========================================================
    echo.
    echo GitHub rejected the push.
    echo.
    echo Running one final synchronization check...
    echo.

    git fetch origin

    if errorlevel 1 (
        echo.
        echo Could not fetch GitHub.
        pause
        exit /b 1
    )

    echo.
    echo Please run:
    echo.
    echo     git status
    echo.
    echo and inspect the result.
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
echo [8/8] DEPLOY COMPLETE
echo.
echo ==========================================================
echo                    DEPLOY SUCCESSFUL
echo ==========================================================
echo.
echo Repository:
echo https://github.com/%GITHUB_USERNAME%/%GITHUB_REPOSITORY%
echo.
echo Branch:
echo %GITHUB_BRANCH%
echo.
echo Your project is synchronized with GitHub.
echo.
echo ==========================================================
echo.

pause
exit /b 0

REM ==========================================================
REM CANCEL
REM ==========================================================

:CANCEL

color 0E

echo.
echo ==========================================================
echo                    DEPLOY CANCELLED
echo ==========================================================
echo.
echo No files were force-pushed.
echo Your repository has been left untouched.
echo.
echo ==========================================================
echo.

pause
exit /b 0
```
