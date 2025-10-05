# =============================================================================
#  My-Dev-Playbook: Play #9 - Git Guardian (Paste-and-Run Version)
# =============================================================================
# INSTRUCTIONS: Copy this entire script and paste it directly into a
# PowerShell terminal. Press Enter one last time to start the menu.
# =============================================================================

Function Start-GitGuardian {
    # --- HELPER & UI FUNCTIONS ---
    Function Test-IsGitRepo { return Test-Path ".git" -PathType Container }
    Function Test-CommandExists { param([string]$Command) return -not ([string]::IsNullOrEmpty((Get-Command $Command -ErrorAction SilentlyContinue))) }

    Function Show-Header {
        param([string]$Title)
        Clear-Host
        Write-Host ("-" * 80) -ForegroundColor DarkGray
        Write-Host "Git Guardian: $Title" -ForegroundColor Cyan
        Write-Host ("-" * 80) -ForegroundColor DarkGray
        Write-Host
    }

    Function Get-RepoStatus {
        if (-not (Test-IsGitRepo)) { return "Not a Git Repository" }
        $status = git status --porcelain
        if ($status -match '(?m)^UU') { return "CONFLICT" }
        if ($status) { return "Modified" }
        return "Clean"
    }

    # --- CORE WORKFLOWS ---
    Function Invoke-AuthAndConfig {
        Show-Header "Authenticate & Configure"
        # 1. Check Git user config
        $gitName = git config user.name
        $gitEmail = git config user.email
        if (-not $gitName -or -not $gitEmail) {
            Write-Host "Git user identity is not set." -ForegroundColor Yellow
            $name = Read-Host "Enter your full name for Git commits"
            $email = Read-Host "Enter your email for Git commits"
            git config --global user.name "$name"
            git config --global user.email "$email"
            Write-Host "[SUCCESS] Git user identity configured globally." -ForegroundColor Green
        } else {
            Write-Host "[SUCCESS] Git user identity already configured: $gitName <$gitEmail>" -ForegroundColor Green
        }

        # 2. Check for GitHub CLI
        if (-not (Test-CommandExists "gh")) {
            Write-Host "`n[ERROR] GitHub CLI ('gh') not found." -ForegroundColor Red
            Write-Host "Please install it from: https://cli.github.com/ and ensure it's in your PATH."
            return
        }
        
        # 3. Check auth status and log in if needed
        Write-Host "`nChecking GitHub authentication status..."
        gh auth status -h github.com -q
        if ($LASTEXITCODE -ne 0) {
            Write-Host "You are not logged into GitHub. Launching browser-based login..." -ForegroundColor Yellow
            gh auth login --web
        }
        gh auth status
    }

    Function Invoke-NewRepoWorkflow {
        Show-Header "Initialize & Push New Project"
        if (Test-IsGitRepo) { Write-Host "[ERROR] This folder is already a Git repository." -ForegroundColor Red; return }
        
        $repoName = Read-Host "Enter Repository Name (default: $(Split-Path -Leaf (Get-Location)))"
        if (-not $repoName) { $repoName = Split-Path -Leaf (Get-Location) }
        $description = Read-Host "Enter a short description"
        $visibility = Read-Host "Make repository Public or Private? (Public/Private)"
        if ($visibility.ToLower() -notin 'public', 'private') { $visibility = 'private' }

        if ((Read-Host "Create a .gitignore file? (Y/n)").ToLower() -ne 'n') {
            $template = Read-Host "Enter a .gitignore template (e.g., Node, Python, VisualStudio) or press Enter for a generic one"
            try { gh api "gitignore/templates/$template" | Select-Object -ExpandProperty source | Out-File .gitignore -Encoding utf8 }
            catch { "# Generic .gitignore`n/node_modules`n/dist`n.env" | Out-File .gitignore -Encoding utf8; Write-Host "Template not found, created a generic one." -ForegroundColor Yellow }
        }
        if ((Read-Host "Create a LICENSE file (MIT)? (Y/n)").ToLower() -ne 'n') {
            try { gh api licenses/mit | Select-Object -ExpandProperty body | Out-File LICENSE -Encoding utf8 } catch { Write-Host "Could not fetch MIT license." -ForegroundColor Red }
        }

        Write-Host "`nInitializing repository and pushing to GitHub..." -ForegroundColor Yellow
        git init -b main
        git add .
        git commit -m "Initial commit"
        gh repo create $repoName --$visibility --description "$description" --source=. --remote=origin --push
        if ($LASTEXITCODE -eq 0) { Write-Host "`n[SUCCESS] Repository created and pushed to GitHub." -ForegroundColor Green }
        else { Write-Host "`n[ERROR] Failed to create repository on GitHub." -ForegroundColor Red }
    }

    Function Invoke-CloneRepo {
        Show-Header "Clone a Repository"
        $repoUrl = Read-Host "Enter the full URL of the repository to clone"
        if ($repoUrl) { git clone $repoUrl }
    }

    Function Invoke-ManageLocalRepo {
        do {
            Show-Header "Manage Local Repository"
            if (-not (Test-IsGitRepo)) { Write-Host "[ERROR] Not inside a Git repository." -ForegroundColor Red; return }
            
            Write-Host "Current Path: $(Get-Location)" -ForegroundColor Gray
            Write-Host "Current Branch: $((git branch --show-current))" -ForegroundColor Yellow
            Write-Host "Status: $(Get-RepoStatus)"
            Write-Host
            Write-Host "[1] Sync with Remote (Pull Changes)"
            Write-Host "[2] Branch Manager (Create, Switch, Merge, Delete)"
            Write-Host "[3] Update Repository Details (Description, README)"
            Write-Host "[4] Commit & Push Your Local Changes"
            Write-Host "[B] Back to Main Menu"
            $choice = Read-Host "`nEnter your choice"

            switch ($choice) {
                '1' { # Sync
                    $syncChoice = Read-Host "Choose sync strategy: [1] Rebase (clean history), [2] Merge (explicit commit)"
                    if ($syncChoice -eq '1') { git pull --rebase }
                    elseif ($syncChoice -eq '2') { git pull }
                }
                '2' { # Branch Manager
                    $branches = git branch | ForEach-Object { $_.Trim() -replace '\* ', '' }
                    Write-Host "`n--- Branch Manager ---"
                    Write-Host "[c] Create new branch"
                    Write-Host "[s] Switch to another branch"
                    Write-Host "[m] Merge a branch into current"
                    Write-Host "[d] Delete a branch"
                    $branchOp = Read-Host "Choose an operation"
                    switch ($branchOp) {
                        'c' { $newName = Read-Host "Enter new branch name"; git checkout -b $newName }
                        's' { 
                            for ($i = 0; $i -lt $branches.Count; $i++) { Write-Host "[$($i+1)] $($branches[$i])" }
                            $idx = [int](Read-Host "Select branch to switch to") - 1
                            if ($idx -ge 0 -and $idx -lt $branches.Count) { git checkout $branches[$idx] }
                        }
                        'm' {
                            $otherBranches = $branches | Where-Object { $_ -ne (git branch --show-current) }
                            for ($i = 0; $i -lt $otherBranches.Count; $i++) { Write-Host "[$($i+1)] $($otherBranches[$i])" }
                            $idx = [int](Read-Host "Select branch to merge into '$((git branch --show-current))'") - 1
                            if ($idx -ge 0 -and $idx -lt $otherBranches.Count) { git merge $otherBranches[$idx] }
                        }
                        'd' {
                            for ($i = 0; $i -lt $branches.Count; $i++) { Write-Host "[$($i+1)] $($branches[$i])" }
                            $idx = [int](Read-Host "Select branch to delete") - 1
                            if ($idx -ge 0 -and $idx -lt $branches.Count) {
                                $branchToDelete = $branches[$idx]
                                git branch -d $branchToDelete
                                if ((Read-Host "Delete remote branch '$branchToDelete' as well? (y/N)").ToLower() -eq 'y') {
                                    git push origin --delete $branchToDelete
                                }
                            }
                        }
                    }
                }
                '3' { # Update Details
                    Write-Host "`n--- Update Repository Details ---"
                    if ((Read-Host "Update GitHub repository description? (y/N)").ToLower() -eq 'y') {
                        $newDesc = Read-Host "Enter the new description"
                        gh repo edit --description "$newDesc"
                    }
                    if ((Read-Host "Edit the README.md file? (y/N)").ToLower() -eq 'y') {
                        if (-not (Test-Path "README.md")) { "# $(Split-Path -Leaf (Get-Location))`n" | Out-File README.md }
                        Write-Host "Opening README.md in your default editor. Save and close the file, then press Enter here."
                        Start-Process -FilePath "README.md" -Wait
                        Read-Host
                        git add README.md
                        git commit -m "docs: update README.md"
                        Write-Host "README.md has been committed. Use option [4] to push." -ForegroundColor Green
                    }
                }
                '4' { # Commit & Push
                    $commitMessage = Read-Host "Enter commit message"
                    git add .
                    git commit -m "$commitMessage"
                    git push
                }
            }
            if ($choice -ne 'b') { Read-Host "`nOperation finished. Press Enter to return to the menu." }
        } while ($choice -ne 'b')
    }

    Function Invoke-AIDebugger {
        Show-Header "AI-Powered Git Doctor"
        $errorMessage = Read-Host "Paste the full Git error message you received"
        $userGoal = Read-Host "What were you trying to do? (e.g., 'push my changes')"
        $gitStatus = git status
        $gitLog = git log -n 5 --pretty=oneline
        
        $prompt = @"
### ROLE AND GOAL ###
You are an expert Git troubleshooter. Your goal is to analyze the provided context and error message to give a clear, step-by-step solution.

### MY GOAL ###
$userGoal

### GIT ERROR MESSAGE ###
$errorMessage

### CONTEXT: GIT STATUS ###
$gitStatus

### CONTEXT: RECENT COMMITS ###
$gitLog

### YOUR TASK ###
1.  **Explain the Error:** In simple terms, what does this error mean?
2.  **Provide the Solution:** Give me the exact `git` commands to run to fix this problem.
3.  **Explain the Fix:** Briefly explain why these commands solve the issue.
"@

        $outputFile = "prompt-for-ai.txt"
        Set-Content -Path $outputFile -Value $prompt -Encoding UTF8
        Write-Host "`n[SUCCESS] A prompt file named '$outputFile' has been created." -ForegroundColor Green
        Write-Host "Copy its content and paste it into your favorite AI chat (ChatGPT, Gemini, etc.)."
    }

    Function Invoke-NukeRepo {
        Show-Header "Nuke & Restart (Reset Repository)"
        Write-Host "*** EXTREME WARNING ***" -ForegroundColor Red
        Write-Host "This will PERMANENTLY delete the local `.git` directory."
        Write-Host "All commit history in this local repository will be lost. This cannot be undone."
        if ((Read-Host "Are you sure you want to do this? (y/n)").ToLower() -ne 'y') { return }
        if ((Read-Host "Are you ABSOLUTELY sure? (y/n)").ToLower() -ne 'y') { return }
        
        $folderName = Split-Path -Leaf (Get-Location)
        $confirmName = Read-Host "To confirm, please type the name of the current folder: '$folderName'"
        if ($confirmName -eq $folderName) {
            Write-Host "Deleting .git directory..."
            Remove-Item .git -Recurse -Force
            Write-Host "[SUCCESS] Repository reset successfully." -ForegroundColor Green
        } else {
            Write-Host "Confirmation failed. Aborting." -ForegroundColor Yellow
        }
    }

    # --- MAIN MENU & SCRIPT EXECUTION LOOP ---
    do {
        Show-Header "Main Menu"
        $repoStatus = Get-RepoStatus
        Write-Host "Current Path: $(Get-Location)" -ForegroundColor Gray
        Write-Host "Repository Status: $repoStatus`n"

        Write-Host "--- Setup ---"
        Write-Host "[1] Authenticate & Configure (First-Time Setup)"
        Write-Host
        Write-Host "--- New Project ---"
        Write-Host "[2] Initialize & Push a New Local Project to GitHub"
        Write-Host
        Write-Host "--- Existing Project ---"
        Write-Host "[3] Clone a Repository from GitHub"
        Write-Host "[4] Manage a Local Repository (Pull, Branch, Update, Push)"
        Write-Host
        Write-Host "--- Utilities ---"
        Write-Host "[5] AI-Powered Debugger ('Git Doctor')"
        Write-Host "[6] Nuke & Restart (Reset Local Repository)"
        Write-Host
        Write-Host "[Q] Quit"
        $choice = Read-Host "`nEnter your choice"

        switch ($choice) {
            '1' { Invoke-AuthAndConfig }
            '2' { Invoke-NewRepoWorkflow }
            '3' { Invoke-CloneRepo }
            '4' { Invoke-ManageLocalRepo }
            '5' { Invoke-AIDebugger }
            '6' { Invoke-NukeRepo }
        }
        if ($choice -ne 'q' -and $choice -ne '4') { Read-Host "`nOperation finished. Press Enter to return to the Main Menu." }

    } while ($choice -ne 'q')

    Write-Host "Exiting Git Guardian. Goodbye!"
}

# --- SCRIPT ENTRY POINT ---
# This line calls the main function, starting the script after it has been defined.
Start-GitGuardian