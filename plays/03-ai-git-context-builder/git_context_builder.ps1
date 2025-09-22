<#
.SYNOPSIS
  An AI-powered Git Context Builder that creates a comprehensive, AI-ready prompt file
  to get a human-like summary of your uncommitted changes.

.DESCRIPTION
  Play #3 from My-Dev-Playbook. This script solves the problem of understanding complex changes
  by preparing a perfect "context package" for a Large Language Model (LLM). It combines the
  directory structure, the code differences (diff), and your stated goal into a single text file.
  You can then paste this into any AI chat to get a high-quality explanation of your work.

.NOTES
  Author: Sheikh Mahmudul Hasan Shium
  License: MIT
  Prerequisite: This script must be run inside a Git repository. No API keys or sign-in required.
#>

# --- SCRIPT START ---

Function Create-GitContextForAI {
    # --- Phase 1: Pre-flight Check ---
    Clear-Host
    Write-Host "--- 📖 My-Dev-Playbook: AI-Powered Git Context Builder ---" -ForegroundColor Cyan

    if (-not (Test-Path ".git")) { Write-Host "`n❌ ERROR: This is not a Git repository." -ForegroundColor Red; return }
    $gitDiff = git diff HEAD
    if (-not $gitDiff) { Write-Host "`n✅ No uncommitted changes found. Your working directory is clean!" -ForegroundColor Green; return }

    # --- Phase 2: Gather Human Context ---
    Write-Host "`nTo give the AI the best context, please describe your goal for these changes." -ForegroundColor Yellow
    $userGoal = Read-Host "For example: 'Refactoring the login component' or 'Fixing a bug in the API endpoint'"
    if (-not $userGoal) { $userGoal = "No specific goal provided by the developer." }

    Write-Host "`n👍 Got it. Now gathering technical context..."

    # --- Phase 3: Gather Technical Context ---
    $projectTree = tree /F | Where-Object { $_ -notmatch 'node_modules' }
    $codeDiff = git diff HEAD --unified=10

    # --- Phase 4: Build the AI Prompt ---
    $outputFileName = "prompt-for-ai.txt"
    $stringBuilder = New-Object System.Text.StringBuilder

    # This is the "Prompt Engineering" section
    [void]$stringBuilder.AppendLine("### ROLE AND GOAL ###")
    [void]$stringBuilder.AppendLine("You are an expert senior software developer and a code reviewer. Your goal is to provide a clear, human-readable summary of the code changes I'm providing. You must act as a teacher, explaining the work to help me understand it better.")
    [void]$stringBuilder.AppendLine("")
    [void]$stringBuilder.AppendLine("### MY HIGH-LEVEL GOAL FOR THESE CHANGES ###")
    [void]$stringBuilder.AppendLine($userGoal)
    [void]$stringBuilder.AppendLine("")
    [void]$stringBuilder.AppendLine("--------------------------------------------------")
    [void]$stringBuilder.AppendLine("")
    [void]$stringBuilder.AppendLine("### CONTEXT: PROJECT DIRECTORY STRUCTURE ###")
    [void]$stringBuilder.AppendLine("```")
    [void]$stringBuilder.AppendLine($projectTree -join "`n")
    [void]$stringBuilder.AppendLine("```")
    [void]$stringBuilder.AppendLine("")
    [void]$stringBuilder.AppendLine("### CONTEXT: DETAILED CODE CHANGES (GIT DIFF) ###")
    [void]$stringBuilder.AppendLine("```diff")
    [void]$stringBuilder.AppendLine($codeDiff)
    [void]$stringBuilder.AppendLine("```")
    [void]$stringBuilder.AppendLine("")
    [void]$stringBuilder.AppendLine("--------------------------------------------------")
    [void]$stringBuilder.AppendLine("")
    [void]$stringBuilder.AppendLine("### YOUR TASK ###")
    [void]$stringBuilder.AppendLine("Based on all the context above, please provide a summary of my work. Structure your answer with the following sections:")
    [void]$stringBuilder.AppendLine("1.  **High-Level Summary:** In one paragraph, what did I primarily accomplish with these changes?")
    [void]$stringBuilder.AppendLine("2.  **Detailed Breakdown (The 'What' and 'How'):** Go through the key files I changed and explain what the changes do from a technical perspective.")
    [void]$stringBuilder.AppendLine("3.  **Inferred Intent (The 'Why'):** Based on the code and my stated goal, explain the likely reasons behind the key changes. What problem was I trying to solve?")
    [void]$stringBuilder.AppendLine("4.  **Constructive Feedback:** Are there any potential issues, bugs, or better ways to implement these changes? Suggest improvements if you see any.")
    # --- NEW INSTRUCTION ADDED HERE ---
    [void]$stringBuilder.AppendLine("5.  **CRITICAL INSTRUCTION:** Do not change any relative path imports (e.g., `import './styles.css'` or `from '../utils'`). These paths are essential for the project's structure and must be preserved. Only suggest changes to them if it is the primary focus of my stated goal.")
    [void]$stringBuilder.AppendLine("")
    [void]$stringBuilder.AppendLine("Please be clear, concise, and constructive.")

    Set-Content -Path $outputFileName -Value $stringBuilder.ToString() -Encoding UTF8

    # --- Phase 5: User Handoff ---
    Write-Host "`n`n--- ✅ Success! Your AI context package is ready! ---" -ForegroundColor Green
    Write-Host "A file named '$outputFileName' has been created in this directory."
    Write-Host "`nYour next steps are simple:" -ForegroundColor Cyan
    Write-Host "1. Open the file '$outputFileName'."
    Write-Host "2. Select ALL the text (Ctrl+A) and copy it (Ctrl+C)."
    Write-Host "3. Paste it into your favorite AI chat (ChatGPT, Gemini, Claude, etc.) and get your summary!"
}

# =============================================================================
#  SCRIPT EXECUTION
# =============================================================================
Create-GitContextForAI

Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)