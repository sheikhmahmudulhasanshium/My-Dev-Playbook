@echo off
cls
title My-Dev-Playbook: The AI Prompt Architect (Batch Version)

echo --- [My-Dev-Playbook: The AI Prompt Architect (Batch Version)] ---
echo You can type 'exit' at any prompt to abort the script.
echo.

REM --- Cleanup previous temporary files ---
if exist temp_context.txt del temp_context.txt >nul 2>nul
if exist temp_guidelines.txt del temp_guidelines.txt >nul 2>nul
if exist temp_constraints.txt del temp_constraints.txt >nul 2>nul
if exist temp_prompt.txt del temp_prompt.txt >nul 2>nul

REM =============================================================================
REM  MAIN SCRIPT FLOW
REM =============================================================================

call :GetShell
if %ERRORLEVEL% equ 1 goto :AbortScript

call :GetProjectType
if %ERRORLEVEL% equ 1 goto :AbortScript

REM --- Branch based on project type ---
if /i "%IS_NEW_PROJECT%"=="y" (goto :ExecuteNewProjectFlow) else (goto :ExecuteExistingProjectFlow)

:ExecuteNewProjectFlow
call :NewProjectFlow
if %ERRORLEVEL% equ 1 goto :AbortScript
goto :ContinueAfterFlows

:ExecuteExistingProjectFlow
call :ExistingProjectFlow
if %ERRORLEVEL% equ 1 goto :AbortScript
goto :ContinueAfterFlows

:ContinueAfterFlows
call :CheckContinue "Do you want to continue to the final step (Guidelines ^& Constraints)?"
if %ERRORLEVEL% equ 1 goto :AbortScript

call :CommonQuestions
if %ERRORLEVEL% equ 1 goto :AbortScript

call :AssemblePrompt

goto :DisplayAndSave


REM =============================================================================
REM  LOGIC SUBROUTINES (Called from Main Flow)
REM =============================================================================

:GetShell
echo What is your primary terminal/shell environment?
echo [1] PowerShell
echo [2] CMD (Windows Command Prompt / Batch)
echo [3] Bash / zsh (Linux, macOS, WSL)
:GetShellLoop
call :GetInput "Enter your choice (1-3)" SHELL_CHOICE
if %ERRORLEVEL% equ 1 exit /b 1

if "%SHELL_CHOICE%"=="1" (set "TERMINAL_CONTEXT=PowerShell. All commands and scripts must be compatible with PowerShell.") & (goto :ShellDone)
if "%SHELL_CHOICE%"=="2" (set "TERMINAL_CONTEXT=Windows CMD (Command Prompt). All commands must be compatible with CMD/Batch scripts.") & (goto :ShellDone)
if "%SHELL_CHOICE%"=="3" (set "TERMINAL_CONTEXT=Bash or zsh (Linux/WSL). All commands must be compatible with a standard Bash shell.") & (goto :ShellDone)

echo Invalid choice. Please try again.
goto :GetShellLoop
:ShellDone
echo.
exit /b 0

:GetProjectType
call :GetYesNo "Is this prompt for a NEW project idea?" IS_NEW_PROJECT
if %ERRORLEVEL% equ 1 exit /b 1
echo.
exit /b 0

:ExistingProjectFlow
echo --- Building a Prompt for an Existing Project ---
call :GetMultiLine "Provide all relevant context (e.g., tech stack, code snippets, errors)" temp_context.txt
if %ERRORLEVEL% equ 1 exit /b 1
echo.
call :GetInput "What is the specific goal of your task?" GOAL
if %ERRORLEVEL% equ 1 exit /b 1
exit /b 0

:NewProjectFlow
echo --- Scaffolding a New Project Prompt ---
echo.
call :GetInput "What is the name of your new project?" PROJECT_NAME
if %ERRORLEVEL% equ 1 exit /b 1
call :GetInput "Is it Frontend, Backend, or Full-Stack?" PROJECT_TYPE
if %ERRORLEVEL% equ 1 exit /b 1
call :GetInput "What is your desired tech stack?" TECH_STACK
if %ERRORLEVEL% equ 1 exit /b 1
call :GetInput "Describe the main goal or purpose of this project" GOAL
if %ERRORLEVEL% equ 1 exit /b 1
call :GetYesNo "Is this a hobby project?" IS_HOBBY
if %ERRORLEVEL% equ 1 exit /b 1
if /i "%IS_HOBBY%"=="y" set "HOBBY_INFO=This is a hobby project. Please suggest services with generous free tiers that DO NOT require a credit card. Good examples: Vercel, Netlify, Render, Supabase, MongoDB Atlas, Google/GitHub Auth. Bad examples: AWS free tier (requires CC), Railway, PlanetScale."
call :GetSecuritySpecs
if %ERRORLEVEL% equ 1 exit /b 1
call :GetDeliverables
if %ERRORLEVEL% equ 1 exit /b 1
exit /b 0

:GetSecuritySpecs
echo.
call :GetYesNo "Do you want to continue to Security Scoping?" CONTINUE_CHOICE
if %ERRORLEVEL% equ 1 exit /b 1
if /i "%CONTINUE_CHOICE%"=="n" exit /b 1
call :GetYesNo "Do you need user authentication for this project?" REQ_AUTH
if %ERRORLEVEL% equ 1 exit /b 1
if /i not "%REQ_AUTH%"=="y" exit /b 0
echo.
echo --- Security ^& Authentication Scoping ---
:GetAuthStrategyLoop
echo Choose an authentication strategy:
echo [1] 3rd-Party Service (Easy ^& Secure, e.g., Clerk, Firebase Auth)
echo [2] Self-Managed / In-House (More control, e.g., Passport.js, JWTs)
call :GetInput "Enter your choice (1-2)" AUTH_STRATEGY
if %ERRORLEVEL% equ 1 exit /b 1
if not "%AUTH_STRATEGY%"=="1" if not "%AUTH_STRATEGY%"=="2" (echo Invalid choice. & goto :GetAuthStrategyLoop)
call :GetYesNo "Do you need Role-Based Authorization (RBA) (e.g., 'admin', 'user')?" REQ_RBA
if %ERRORLEVEL% equ 1 exit /b 1
call :GetYesNo "Do you require Multi-Factor Authentication (MFA)?" REQ_MFA
if %ERRORLEVEL% equ 1 exit /b 1
call :GetYesNo "Do you want to include Social Logins (OAuth)?" REQ_OAUTH
if %ERRORLEVEL% equ 1 exit /b 1
if /i "%REQ_OAUTH%"=="y" (
    call :GetInput "Which OAuth providers? (e.g., Google, GitHub)" OAUTH_PROVIDERS
    if %ERRORLEVEL% equ 1 exit /b 1
)
exit /b 0

:GetDeliverables
echo.
call :GetYesNo "Do you want to continue to Deliverables Scoping?" CONTINUE_CHOICE
if %ERRORLEVEL% equ 1 exit /b 1
if /i "%CONTINUE_CHOICE%"=="n" exit /b 1
echo.
echo --- Additional Project Scoping ---
call :GetYesNo "Need a step-by-step development plan?" REQ_PLAN
if %ERRORLEVEL% equ 1 exit /b 1
call :GetYesNo "Need a cost analysis report for hosting?" REQ_COST
if %ERRORLEVEL% equ 1 exit /b 1
call :GetYesNo "Need a Software Requirements Specification (SRS) document?" REQ_SRS
if %ERRORLEVEL% equ 1 exit /b 1
call :GetYesNo "Need API documentation? (for backend/full-stack)" REQ_DOCS
if %ERRORLEVEL% equ 1 exit /b 1
call :GetYesNo "Need brand specifications?" REQ_BRAND
if %ERRORLEVEL% equ 1 exit /b 1
exit /b 0

:CheckContinue
echo.
call :GetYesNo "%~1" CONTINUE_CHOICE
if %ERRORLEVEL% equ 1 exit /b 1
if /i "%CONTINUE_CHOICE%"=="n" exit /b 1
exit /b 0

:CommonQuestions
echo.
call :GetMultiLine "What are the GUIDELINES for the AI? (What it *should* do)" temp_guidelines.txt
if %ERRORLEVEL% equ 1 exit /b 1
echo.
call :GetMultiLine "What are the CONSTRAINTS for the AI? (What it *should not* do)" temp_constraints.txt
if %ERRORLEVEL% equ 1 exit /b 1
echo.
if /i "%IS_NEW_PROJECT%"=="n" (
    call :GetYesNo "When providing code, do you need the AI to return the FULL updated file?" FULL_FILE
    if %ERRORLEVEL% equ 1 exit /b 1
    if /i "%FULL_FILE%"=="y" set "OUTPUT_INTEGRITY=CRITICAL: When providing code, you must return the ENTIRE updated file. Do not use placeholders or omit unchanged lines."
)
exit /b 0

:AssemblePrompt
(
    echo ### ROLE ^& GOAL ###
    if /i "%IS_NEW_PROJECT%"=="y" (echo You are an expert solution architect and senior developer.) else (echo You are an expert senior developer and a master debugger.)
    echo Your primary goal is to help me achieve my objective by providing clear, expert-level advice and code based on the detailed context I am providing.
    echo.
    echo ### CONTEXT ^& REQUIREMENTS ###
    echo **Primary Terminal:**
    echo %TERMINAL_CONTEXT%
    echo.
    if /i "%IS_NEW_PROJECT%"=="y" (
        echo **Project Name:** ^& echo %PROJECT_NAME% ^& echo.
        echo **Project Type:** ^& echo %PROJECT_TYPE% ^& echo.
        echo **Tech Stack:** ^& echo %TECH_STACK% ^& echo.
        if defined HOBBY_INFO ( echo **Hobby Project Info:** ^& echo %HOBBY_INFO% ^& echo. )
    ) else (
        echo **Context:** ^& if exist temp_context.txt type temp_context.txt ^& echo.
    )
    echo **Goal:** ^& echo %GOAL% ^& echo.
    if /i "%REQ_AUTH%"=="y" (
        echo **Security ^& Authentication Requirements:**
        if "%AUTH_STRATEGY%"=="1" echo - Authentication Strategy: 3rd-Party Service (e.g., Clerk, Firebase Auth, Supabase Auth). Recommend a suitable service.
        if "%AUTH_STRATEGY%"=="2" echo - Authentication Strategy: Self-Managed / In-House. Use libraries like Passport.js (backend) or Next-Auth (frontend) with JWTs, salting, and secure cookie handling.
        if /i "%REQ_RBA%"=="y" (echo - Role-Based Authorization: Yes) else (echo - Role-Based Authorization: No)
        if /i "%REQ_MFA%"=="y" (echo - Multi-Factor Authentication: Yes) else (echo - Multi-Factor Authentication: No)
        if /i "%REQ_OAUTH%"=="y" (echo - Social Logins (OAuth): Yes (Providers: %OAUTH_PROVIDERS%)) else (echo - Social Logins (OAuth): No)
        echo.
    )
    if defined REQ_PLAN (
        echo **Requested Deliverables:**
        if /i "%REQ_PLAN%"=="y" echo - A detailed, step-by-step development plan from setup to deployment.
        if /i "%REQ_COST%"=="y" echo - A cost analysis report for the suggested services, focusing on free-tier limits and future scaling costs.
        if /i "%REQ_SRS%"=="y" echo - A concise Software Requirements Specification (SRS) document outlining key features and user stories.
        if /i "%REQ_DOCS%"=="y" echo - API documentation. If the backend is an API, provide it in a format compatible with Swagger/OpenAPI.
        if /i "%REQ_BRAND%"=="y" echo - Brand specifications, including suggestions for the app name, a tagline, a simple logo concept, and a color palette.
        echo.
    )
    echo **Guidelines:** ^& if exist temp_guidelines.txt type temp_guidelines.txt ^& echo.
    echo **Constraints:** ^& if exist temp_constraints.txt type temp_constraints.txt ^& echo.
    if defined OUTPUT_INTEGRITY ( echo **Output Integrity:** ^& echo %OUTPUT_INTEGRITY% ^& echo. )
    echo ### YOUR TASK ###
    echo Based on all the context and requirements above, please perform the requested task. Structure your response for maximum clarity, addressing each deliverable in a dedicated section.
    echo Provide explanations for your architectural decisions, and ensure all commands are compatible with the specified terminal environment. ^& echo.
) > temp_prompt.txt
exit /b 0

REM =============================================================================
REM  FINAL PHASE: DISPLAY AND SAVE
REM =============================================================================
:DisplayAndSave
cls
echo --- [Your Master Prompt is Ready] --- & echo.
type temp_prompt.txt
echo.& echo --------------------------------------- & echo.
call :GetYesNo "Do you want to save this prompt to 'master_prompt.txt'?" SAVE_CHOICE
if %ERRORLEVEL% equ 1 goto :AbortScript
if /i "%SAVE_CHOICE%"=="y" ( copy temp_prompt.txt master_prompt.txt > nul & echo Successfully saved prompt to 'master_prompt.txt'. )
goto :Cleanup

REM =============================================================================
REM  EXIT HANDLERS AND UTILITY SUBROUTINES
REM =============================================================================
:AbortScript
echo.& echo Script aborted by user. & echo.
goto :Cleanup

:Cleanup
if exist temp_context.txt del temp_context.txt >nul 2>nul
if exist temp_guidelines.txt del temp_guidelines.txt >nul 2>nul
if exist temp_constraints.txt del temp_constraints.txt >nul 2>nul
if exist temp_prompt.txt del temp_prompt.txt >nul 2>nul
echo.
pause
exit /b

:ConfirmQuit
set "QUIT_CONFIRM="
set /p "QUIT_CONFIRM=Are you sure you want to quit? (Enter 'q' to quit, any other key to continue): "
if /i "%QUIT_CONFIRM%"=="q" (
    exit /b 1
) else (
    echo Resuming... & echo.
    exit /b 0
)

:GetInput
:GetInputLoop
    set "INPUT="
    set /p "INPUT=%~1: "
    if /i not "%INPUT%"=="exit" (
        set "%2=%INPUT%"
        exit /b 0
    )
    rem --- User typed 'exit', must confirm ---
    call :ConfirmQuit
    if %ERRORLEVEL% equ 1 (
        rem User confirmed quit, propagate the signal
        exit /b 1
    )
    rem --- User did not confirm, loop to re-ask the same question ---
goto :GetInputLoop

:GetYesNo
:GetYesNoLoop
    set "INPUT="
    set /p "INPUT=%~1 (y/n): "
    if /i "%INPUT%"=="y" (set "%2=y" & exit /b 0)
    if /i "%INPUT%"=="n" (set "%2=n" & exit /b 0)
    if /i "%INPUT%"=="exit" (
        call :ConfirmQuit
        if %ERRORLEVEL% equ 1 (
            exit /b 1
        )
        rem If not quitting, loop to re-ask
        goto :GetYesNoLoop
    )
    echo Invalid input. Please enter 'y' or 'n'.
goto :GetYesNoLoop

:GetMultiLine
echo.
echo %~1
echo (Type 'END' on a new line to finish, or 'EXIT' to abort)
:GetMultiLineLoop
    set "LINE="
    set /p "LINE="
    if /i "%LINE%"=="END" exit /b 0
    if /i "%LINE%"=="exit" (
        call :ConfirmQuit
        if %ERRORLEVEL% equ 1 (
            exit /b 1
        )
        echo Resuming multi-line input...
        goto :GetMultiLineLoop
    )
    echo %LINE%>> %2
goto :GetMultiLineLoop