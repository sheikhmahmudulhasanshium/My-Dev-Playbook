@echo off
cls
title Git Guardian - The Git Command-Line Partner

:MainMenu
cls
echo ----------------------------------------------------------------------
echo  Git Guardian - Your Interactive Git Partner (Batch Version)
echo ----------------------------------------------------------------------
if exist .git (
    for /f "tokens=*" %%a in ('git status --porcelain') do set git_status=Modified
    if not defined git_status set git_status=Clean
    for /f "tokens=*" %%a in ('git status --porcelain ^| find "UU"') do set git_status=CONFLICT
    echo Repository Status: %git_status%
) else (
    echo Repository Status: Not a Git Repository
)
set git_status=

echo.
echo --- Setup ---
echo [1] Authenticate ^& Configure (First-Time Setup)
echo.
echo --- New Project ---
echo [2] Initialize ^& Push a New Local Project to GitHub
echo.
echo --- Existing Project ---
echo [3] Clone a Repository from GitHub
echo [4] Manage a Local Repository (Pull, Branch, Update, Push)
echo.
echo --- Utilities ---
echo [5] AI-Powered Debugger ('Git Doctor')
echo [6] Nuke ^& Restart (Reset Local Repository)
echo.
echo [Q] Quit
echo.
set /p "choice=Enter your choice: "

if /i "%choice%"=="1" call :AuthAndConfig & goto MainMenu
if /i "%choice%"=="2" call :NewRepoWorkflow & goto MainMenu
if /i "%choice%"=="3" call :CloneRepo & goto MainMenu
if /i "%choice%"=="4" call :ManageLocalRepo & goto MainMenu
if /i "%choice%"=="5" call :AIDebugger & goto MainMenu
if /i "%choice%"=="6" call :NukeRepo & goto MainMenu
if /i "%choice%"=="q" goto :eof

echo Invalid choice.
pause
goto MainMenu

REM ============================================================================
REM  SUBROUTINES
REM ============================================================================

:AuthAndConfig
cls
echo --- [Authenticate ^& Configure] ---
git config user.name >nul 2>nul
if %errorlevel% neq 0 (
    echo Git user identity not set.
    set /p "git_name=Enter your full name for commits: "
    set /p "git_email=Enter your email for commits: "
    git config --global user.name "%git_name%"
    git config --global user.email "%git_email%"
    echo Git user identity configured globally.
) else (
    echo Git user identity is already configured.
)

echo.
echo Checking for GitHub CLI ('gh')...
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: GitHub CLI ('gh') not found.
    echo Please install it from: https://cli.github.com/
    pause
    exit /b
)
echo Checking GitHub authentication status...
gh auth status -h github.com >nul 2>nul
if %errorlevel% neq 0 (
    echo You are not logged in. Launching browser-based login...
    gh auth login --web
)
gh auth status
pause
exit /b

:NewRepoWorkflow
cls
echo --- [Initialize ^& Push New Project] ---
if exist .git ( echo ERROR: This folder is already a Git repository. & pause & exit /b )

for %%i in (.) do set "folder_name=%%~ni"
set /p "repo_name=Enter Repository Name (default: %folder_name%): "
if not defined repo_name set "repo_name=%folder_name%"
set /p "repo_desc=Enter a short description: "
set /p "repo_visibility=Make repository Public or Private? (Public/Private): "
if /i not "%repo_visibility%"=="public" if /i not "%repo_visibility%"=="private" set "repo_visibility=private"

set /p "create_gitignore=Create a .gitignore file? (y/n): "
if /i "%create_gitignore%"=="y" (
    echo # Generic .gitignore > .gitignore
    echo /node_modules >> .gitignore
    echo /dist >> .gitignore
    echo .env >> .gitignore
)

set /p "create_license=Create a LICENSE file (MIT)? (y/n): "
if /i "%create_license%"=="y" (
    (
        echo MIT License
        echo.
        echo Copyright (c^) 2024
        echo.
        echo Permission is hereby granted, free of charge, to any person obtaining a copy...
    ) > LICENSE
)

echo.
echo Initializing repository and pushing to GitHub...
git init -b main
git add .
git commit -m "Initial commit"
gh repo create "%repo_name%" --%repo_visibility% --description "%repo_desc%" --source=. --remote=origin --push
if %errorlevel% equ 0 ( echo Success! Repository created. ) else ( echo ERROR: Failed to create repository. )
pause
exit /b

:CloneRepo
cls
echo --- [Clone a Repository] ---
set /p "repo_url=Enter the full URL of the repository to clone: "
if defined repo_url ( git clone "%repo_url%" )
pause
exit /b

:ManageLocalRepo
:ManageLocalRepoLoop
cls
echo --- [Manage Local Repository] ---
if not exist .git ( echo ERROR: Not a Git repository. & pause & exit /b )
for /f "tokens=*" %%a in ('git branch --show-current') do set current_branch=%%a
echo Current Branch: %current_branch%
echo.
echo [1] Sync with Remote (Pull Changes)
echo [2] Branch Manager (Create, Switch, Merge, Delete)
echo [3] Update Repository Details (Description, README)
echo [4] Commit ^& Push Your Local Changes
echo [B] Back to Main Menu
echo.
set /p "manage_choice=Enter your choice: "

if /i "%manage_choice%"=="1" (
    cls & echo --- [Sync with Remote] ---
    set /p "sync_type=Choose sync strategy [1] Rebase, [2] Merge: "
    if "%sync_type%"=="1" ( git pull --rebase ) else ( git pull )
    pause
    goto ManageLocalRepoLoop
)
if /i "%manage_choice%"=="2" (
    cls & echo --- [Branch Manager] ---
    echo Current branches: & git branch
    echo.
    set /p "branch_op=Operation: [c]reate, [s]witch, [m]erge, [d]elete: "
    if /i "%branch_op%"=="c" ( set /p "new_branch=Enter new branch name: " & git checkout -b "%new_branch%" )
    if /i "%branch_op%"=="s" ( set /p "switch_branch=Enter branch name to switch to: " & git checkout "%switch_branch%" )
    if /i "%branch_op%"=="m" ( set /p "merge_branch=Enter branch name to merge into '%current_branch%': " & git merge "%merge_branch%" )
    if /i "%branch_op%"=="d" (
        set /p "delete_branch=Enter local branch name to delete: "
        git branch -d "%delete_branch%"
        set /p "delete_remote=Delete remote branch too? (y/n): "
        if /i "%delete_remote%"=="y" git push origin --delete "%delete_branch%"
    )
    pause
    goto ManageLocalRepoLoop
)
if /i "%manage_choice%"=="3" (
    cls & echo --- [Update Repository Details] ---
    set /p "update_desc=Update GitHub repository description? (y/n): "
    if /i "%update_desc%"=="y" (
        set /p "new_desc=Enter the new description: "
        gh repo edit --description "%new_desc%"
    )
    set /p "update_readme=Edit the README.md file? (y/n): "
    if /i "%update_readme%"=="y" (
        if not exist README.md ( echo # New Project > README.md )
        echo Opening README.md in Notepad. Save and close it, then continue.
        start "" notepad README.md
        pause
        git add README.md
        git commit -m "docs: update README.md"
        echo README.md has been committed. Use option [4] to push.
    )
    pause
    goto ManageLocalRepoLoop
)
if /i "%manage_choice%"=="4" (
    cls & echo --- [Commit ^& Push] ---
    set /p "commit_msg=Enter commit message: "
    git add .
    git commit -m "%commit_msg%"
    git push
    pause
    goto ManageLocalRepoLoop
)
if /i "%manage_choice%"=="b" ( exit /b )
goto ManageLocalRepoLoop

:AIDebugger
cls
echo --- [AI-Powered Git Doctor] ---
set "error_file=temp_error.txt"
if exist %error_file% del %error_file%
echo Paste the full Git error message below. Press Ctrl+Z and then Enter when done.
copy con %error_file% >nul
set /p "user_goal=What were you trying to do? (e.g., 'push my changes'): "

(
    echo ### ROLE AND GOAL ###
    echo You are an expert Git troubleshooter.
    echo.
    echo ### MY GOAL ###
    echo %user_goal%
    echo.
    echo ### GIT ERROR MESSAGE ###
    echo ^`^`^`
    type %error_file%
    echo ^`^`^`
    echo.
    echo ### CONTEXT: GIT STATUS ###
    echo ^`^`^`
) > prompt-for-ai.txt
git status >> prompt-for-ai.txt
(
    echo ^`^`^`
    echo.
    echo ### CONTEXT: RECENT COMMITS ###
    echo ^`^`^`
) >> prompt-for-ai.txt
git log -n 5 --pretty=oneline >> prompt-for-ai.txt
(
    echo ^`^`^`
    echo.
    echo ### YOUR TASK ###
    echo 1.  **Explain the Error:** In simple terms, what does this error mean?
    echo 2.  **Provide the Solution:** Give me the exact `git` commands to run.
    echo 3.  **Explain the Fix:** Briefly explain why these commands solve the issue.
) >> prompt-for-ai.txt

if exist %error_file% del %error_file%
echo Success! A prompt file named 'prompt-for-ai.txt' has been created.
echo Copy its content and paste it into your favorite AI chat.
pause
exit /b

:NukeRepo
cls
echo --- [Nuke ^& Restart (Reset Repository)] ---
echo.
echo *** EXTREME WARNING ***
echo This will PERMANENTLY delete the local .git directory.
echo All commit history in this local repository will be lost.
echo.
set /p "confirm1=Are you sure you want to do this? (y/n): "
if /i not "%confirm1%"=="y" exit /b

set /p "confirm2=Are you ABSOLUTELY sure? This cannot be undone. (y/n): "
if /i not "%confirm2%"=="y" exit /b

for %%i in (.) do set "folder_name=%%~ni"
set /p "confirm3=To confirm, please type the name of the folder ('%folder_name%'): "
if not "%confirm3%"=="%folder_name%" (
    echo Confirmation failed. Aborting.
    pause
    exit /b
)

echo Deleting .git directory...
rmdir /s /q .git
echo Repository reset successfully.
pause
exit /b