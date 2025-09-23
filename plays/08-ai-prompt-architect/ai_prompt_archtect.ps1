<#
.SYNOPSIS
  An interactive "prompt engineer" that guides a user through a series of questions
  to construct a detailed, expert-level prompt for a Large Language Model (LLM).

.DESCRIPTION
  Play #8 from My-Dev-Playbook. This script helps users craft superior AI prompts by
  asking for specific context, including detailed security and architectural requirements.
  Features robust input validation and explicit continuation steps.

.NOTES
  Author: Sheikh Mahmudul Hasan Shium
  License: MIT
#>

# --- SCRIPT START ---

# =============================================================================
#  HELPER FUNCTIONS FOR USER INPUT
# =============================================================================
Function Get-Input {
    param([string]$Prompt)
    $input = Read-Host -Prompt $Prompt
    if ($input.ToLower() -eq 'exit') { throw "USER_ABORT" }
    return $input
}

Function Get-YesNoInput {
    param([string]$Prompt)
    do {
        $input = (Get-Input -Prompt "$Prompt (y/n)").ToLower()
        if ($input -in 'y', 'n') {
            return $input -eq 'y'
        }
        Write-Host "Invalid input. Please enter 'y' or 'n'." -ForegroundColor Yellow
    } while ($true)
}

Function Get-MandatoryInput {
    param([string]$Prompt)
    do {
        $input = Get-Input -Prompt $Prompt
        if (-not [string]::IsNullOrWhiteSpace($input)) { return $input }
        Write-Host "This field cannot be empty. Please try again." -ForegroundColor Yellow
    } while ($true)
}

Function Get-MultiLineInput {
    param([string]$Prompt)
    Write-Host $Prompt -ForegroundColor Cyan
    Write-Host "(Enter a blank line when you are finished. Type 'exit' to abort.)"
    $lines = New-Object System.Collections.Generic.List[string]
    while ($true) {
        $line = Read-Host
        if ($line.ToLower() -eq 'exit') { throw "USER_ABORT" }
        if ([string]::IsNullOrWhiteSpace($line)) { break }
        $lines.Add($line)
    }
    return $lines
}

# =============================================================================
#  CORE WORKFLOW LOGIC
# =============================================================================
Function Start-PromptArchitect {
    Clear-Host
    Write-Host "--- 🚀 My-Dev-Playbook: The AI Prompt Architect (PowerShell Version) ---" -ForegroundColor Cyan
    Write-Host "You can type 'exit' at any prompt to abort the script."
    
    $promptData = [ordered]@{ }

    # --- Phase 1: Get Terminal Environment ---
    Write-Host "`nWhat is your primary terminal/shell environment?"
    Write-Host "[1] PowerShell"
    Write-Host "[2] CMD (Windows Command Prompt / Batch)"
    Write-Host "[3] Bash / zsh (Linux, macOS, WSL)"
    do {
        $shellChoice = Get-Input "Enter your choice (1-3)"
        switch ($shellChoice) {
            '1' { $promptData['Primary Terminal'] = "PowerShell. All commands and scripts must be compatible with PowerShell."; break }
            '2' { $promptData['Primary Terminal'] = "Windows CMD (Command Prompt). All commands must be compatible with CMD/Batch scripts."; break }
            '3' { $promptData['Primary Terminal'] = "Bash or zsh (Linux/WSL). All commands must be compatible with a standard Bash shell."; break }
            default { Write-Host "Invalid choice." -ForegroundColor Red; $shellChoice = $null }
        }
    } while (-not $shellChoice)

    # --- Phase 2: Determine Project Type (New vs. Existing) ---
    $isNewProject = Get-YesNoInput "`nIs this prompt for a NEW project idea?"

    # --- Phase 3: Gather Context Based on Project Type ---
    if ($isNewProject) {
        Write-Host "`n--- Scaffolding a New Project Prompt ---" -ForegroundColor Green
        $promptData['Project Name'] = Get-MandatoryInput "What is the name of your new project?"
        $promptData['Project Type'] = Get-MandatoryInput "Is it Frontend, Backend, or Full-Stack?"
        $promptData['Tech Stack'] = Get-MandatoryInput "What is your desired tech stack?"
        $promptData['Goal'] = Get-MandatoryInput "Describe the main goal or purpose of this project"
        if (Get-YesNoInput "Is this a hobby project?") {
            $promptData['Hobby Project Info'] = "This is a hobby project. Please suggest services with generous free tiers that DO NOT require a credit card to sign up. Good examples: Vercel, Netlify, Render (for services), Supabase, MongoDB Atlas (for databases), Google/GitHub (for Auth). Bad examples: AWS free tier (requires CC), Railway, PlanetScale."
        }
        
        if (-not (Get-YesNoInput "`nDo you want to continue to Security Scoping?")) { throw "USER_ABORT" }
        
        if (Get-YesNoInput "`nDo you need user authentication for this project?") {
            Write-Host "`n--- Security & Authentication Scoping ---" -ForegroundColor Green
            $authSpecs = [System.Collections.Generic.List[string]]::new()
            Write-Host "Choose an authentication strategy:"
            Write-Host "[1] 3rd-Party Service (Easy & Secure, e.g., Clerk, Firebase Auth, Supabase Auth)"
            Write-Host "[2] Self-Managed / In-House (More control, e.g., Passport.js, Next-Auth with JWTs)"
            do {
                $authStrategyChoice = Get-Input "Enter your choice (1-2)"
                if ($authStrategyChoice -eq '1') { $authSpecs.Add("- Authentication Strategy: 3rd-Party Service (e.g., Clerk, Firebase Auth, Supabase Auth). Recommend a suitable service."); break }
                if ($authStrategyChoice -eq '2') { $authSpecs.Add("- Authentication Strategy: Self-Managed / In-House. Use libraries like Passport.js (backend) or Next-Auth (frontend) with JWTs, salting, and secure cookie handling."); break }
            } while ($true)
            if (Get-YesNoInput "Do you need Role-Based Authorization (RBA) (e.g., 'admin', 'user')?") { $authSpecs.Add("- Role-Based Authorization: Yes") } else { $authSpecs.Add("- Role-Based Authorization: No") }
            if (Get-YesNoInput "Do you require Multi-Factor Authentication (MFA)?") { $authSpecs.Add("- Multi-Factor Authentication: Yes") } else { $authSpecs.Add("- Multi-Factor Authentication: No") }
            if (Get-YesNoInput "Do you want to include Social Logins (OAuth)?") {
                $oauthProviders = Get-Input "Which OAuth providers? (e.g., Google, GitHub, Facebook)"
                $authSpecs.Add("- Social Logins (OAuth): Yes (Providers: $oauthProviders)")
            } else { $authSpecs.Add("- Social Logins (OAuth): No") }
            $promptData['Security & Authentication Requirements'] = $authSpecs -join "`n"
        }
        
        if (-not (Get-YesNoInput "`nDo you want to continue to Deliverables Scoping?")) { throw "USER_ABORT" }
        
        Write-Host "`n--- Additional Project Scoping ---" -ForegroundColor Green
        $deliverables = [System.Collections.Generic.List[string]]::new()
        if (Get-YesNoInput "Need a step-by-step development plan?") { $deliverables.Add("- A detailed, step-by-step development plan from setup to deployment.") }
        if (Get-YesNoInput "Need a cost analysis report for hosting?") { $deliverables.Add("- A cost analysis report for the suggested services, focusing on free-tier limits and future scaling costs.") }
        if (Get-YesNoInput "Need a Software Requirements Specification (SRS) document?") { $deliverables.Add("- A concise Software Requirements Specification (SRS) document outlining key features and user stories.") }
        if (Get-YesNoInput "Need API documentation? (for backend/full-stack)") { $deliverables.Add("- API documentation. If the backend is an API, provide it in a format compatible with Swagger/OpenAPI.") }
        if (Get-YesNoInput "Need brand specifications?") { $deliverables.Add("- Brand specifications, including suggestions for the app name, a tagline, a simple logo concept, and a color palette.") }

        if ($deliverables.Count -gt 0) { $promptData['Requested Deliverables'] = $deliverables -join "`n" }

    } else { # Existing Project
        Write-Host "`n--- Building a Prompt for an Existing Project ---" -ForegroundColor Green
        $promptData['Context'] = (Get-MultiLineInput "Provide all relevant context (e.g., tech stack, code snippets, error logs)") -join "`n"
        $promptData['Goal'] = Get-MandatoryInput "What is the specific goal of your task? (e.g., 'Refactor this component')"
    }
    
    if (-not (Get-YesNoInput "`nDo you want to continue to the final step (Guidelines & Constraints)?")) { throw "USER_ABORT" }

    # --- Phase 4: Gather Universal Details ---
    $promptData['Guidelines'] = (Get-MultiLineInput "`nWhat are the GUIDELINES for the AI? (What it *should* do, e.g., 'Use TypeScript')") -join "`n"
    $promptData['Constraints'] = (Get-MultiLineInput "`nWhat are the CONSTRAINTS for the AI? (What it *should not* do, e.g., 'Do not install new modules')") -join "`n"
    
    if (-not $isNewProject) {
        if (Get-YesNoInput "`nWhen providing code, do you need the AI to return the FULL updated file?") {
            $promptData['Output Integrity'] = "CRITICAL: When providing code, you must return the ENTIRE updated file. Do not use placeholders like `...` or omit unchanged lines. Return a complete, copy-paste ready file."
        }
    }

    # --- Phase 5: Assemble and Display ---
    $stringBuilder = New-Object System.Text.StringBuilder
    $stringBuilder.AppendLine("### ROLE & GOAL ###")
    $role = if($isNewProject){"You are an expert solution architect and senior developer."} else {"You are an expert senior developer and a master debugger."}
    $stringBuilder.AppendLine("$role Your primary goal is to help me achieve my objective by providing clear, expert-level advice and code based on the detailed context I am providing.")
    $stringBuilder.AppendLine()
    $stringBuilder.AppendLine("### CONTEXT & REQUIREMENTS ###")
    foreach ($key in $promptData.Keys) {
        if (-not [string]::IsNullOrWhiteSpace($promptData[$key])) {
            $stringBuilder.AppendLine("**$($key):**")
            $stringBuilder.AppendLine($promptData[$key])
            $stringBuilder.AppendLine()
        }
    }
    $stringBuilder.AppendLine("### YOUR TASK ###")
    $stringBuilder.AppendLine("Based on all the context and requirements above, please perform the requested task. Structure your response for maximum clarity, addressing each deliverable in a dedicated section.")
    $stringBuilder.AppendLine("Provide explanations for your architectural decisions, and ensure all commands are compatible with the specified terminal environment.")
    $stringBuilder.AppendLine()
    $finalPrompt = $stringBuilder.ToString()
    
    Clear-Host
    Write-Host "--- ✅ Your Master Prompt is Ready ---" -ForegroundColor Green
    Write-Host $finalPrompt
    $outputFileName = "master_prompt.txt"
    if (Get-YesNoInput "`nDo you want to save this prompt to '$outputFileName'?") {
        try { Set-Content -Path $outputFileName -Value $finalPrompt -Encoding UTF8; Write-Host "Successfully saved prompt to '$outputFileName'." -ForegroundColor Green }
        catch { Write-Host "❌ ERROR: Could not write to file. Error: $($_.Exception.Message)" -ForegroundColor Red }
    }
}

# --- SCRIPT EXECUTION ---
try { Start-PromptArchitect }
catch { if ($_.Exception.Message -eq 'USER_ABORT') { Write-Host "`nScript aborted by user." -ForegroundColor Yellow } else { Write-Host "`nAn unexpected error occurred: $($_.Exception.Message)" -ForegroundColor Red } }
Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)