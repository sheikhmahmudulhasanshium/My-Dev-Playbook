<#
.SYNOPSIS
  An advanced, interactive utility to analyze a project directory and merge selected text-based files into a single, comprehensive text or markdown file.

.DESCRIPTION
  Play #2 from My-Dev-Playbook. This script goes beyond simple merging by first providing a detailed analysis
  of the project's file structure. It then guides the user through an interactive process to exclude
  unwanted directories (like node_modules), honor .gitignore rules, and select specific file types
  to include. The final output is a clean, well-structured text document perfect for project archiving,
  documentation, or providing context to AI models.

.NOTES
  Author: Sheikh Mahmudul Hasan Shium
  License: MIT
#>

# --- SCRIPT START ---

# --- Initial Configuration ---
# A broad list of common text-based file extensions. The user will be able to edit this.
[string[]]$defaultTextExtensions = @(
    ".txt", ".md", ".json", ".xml", ".yml", ".yaml", ".html", ".css", ".js", ".jsx",
    ".ts", ".tsx", ".py", ".cpp", ".c", ".h", ".cs", ".java", ".php", ".rb", ".go",
    ".rs", ".ps1", ".sh", ".bat", ".sql", ".gitignore", ".env", "Dockerfile", ".dockerignore"
)

# A list of common directories to suggest ignoring.
[string[]]$defaultIgnoreDirs = @(
    "node_modules", ".git", "dist", "build", "out", "coverage", ".vscode", ".idea"
)
# --- End of Configuration ---


# =============================================================================
#  PHASE 1: PROJECT ANALYSIS
# =============================================================================
Function Get-ProjectAnalysis {
    Clear-Host
    Write-Host "--- 🚀 My-Dev-Playbook: Advanced File Merger ---" -ForegroundColor Cyan
    Write-Host "Analyzing project structure... Please wait."

    $basePath = (Get-Location).Path
    $allFiles = Get-ChildItem -Path $basePath -Recurse -File -ErrorAction SilentlyContinue

    if (-not $allFiles) {
        Write-Host "No files found in this directory." -ForegroundColor Red
        return $null
    }

    # Group files by extension for a summary
    $extensionGroups = $allFiles | Group-Object -Property Extension | Sort-Object -Property Count -Descending

    # Identify heavy folders
    $heavyDirs = Get-ChildItem -Path $basePath -Directory -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        [pscustomobject]@{
            Name = $_.FullName.Substring($basePath.Length + 1)
            SizeMB = [math]::Round($size / 1MB, 2)
        }
    } | Sort-Object -Property SizeMB -Descending | Select-Object -First 5

    # --- Display the Analysis ---
    Write-Host "`n--- 📊 Project Analysis Complete ---" -ForegroundColor Green
    Write-Host "Total files found: $($allFiles.Count)"
    
    Write-Host "`n📁 Top 5 Heaviest Folders:" -ForegroundColor Yellow
    $heavyDirs | Format-Table -AutoSize
    
    Write-Host "`n📄 File Types Summary (Top 10):" -ForegroundColor Yellow
    $extensionGroups | Select-Object -First 10 | ForEach-Object {
        $ext = if ($_.Name) { $_.Name } else { "[No Extension]" }
        Write-Host ("   - {0,-15} : {1} files" -f $ext, $_.Count)
    }

    return $allFiles
}


# =============================================================================
#  PHASE 2: INTERACTIVE CONFIGURATION
# =============================================================================
Function Get-UserConfiguration {
    param(
        [System.Collections.ArrayList]$ignoreList,
        [string[]]$includeExtensions
    )
    
    Write-Host "`n--- 🔧 Interactive Configuration ---" -ForegroundColor Green

    # --- Step 1: Confirm Folders to Ignore ---
    Write-Host "`nI suggest ignoring these common folders to keep the output clean:" -ForegroundColor Yellow
    $ignoreList | ForEach-Object { Write-Host "   - $_" }
    $confirmation = Read-Host "Do you want to ignore these folders? (Y/n)"
    if ($confirmation.ToLower() -eq 'n') {
        $ignoreList.Clear()
        Write-Host "Okay, no default folders will be ignored."
    }
    
    $addMore = Read-Host "Do you want to add more folders to the ignore list? (e.g., 'public, temp') (Press Enter to skip)"
    if ($addMore) {
        $addMore.Split(',').Trim() | ForEach-Object { [void]$ignoreList.Add($_) }
    }
    Write-Host "Current ignore list: $($ignoreList -join ', ')"

    # --- Step 2: Use .gitignore? ---
    $gitignorePath = Join-Path (Get-Location).Path ".gitignore"
    if (Test-Path $gitignorePath) {
        $useGitignore = Read-Host "`nFound a .gitignore file. Do you want to use its rules to exclude files? (Y/n)"
        if ($useGitignore.ToLower() -ne 'n') {
            Write-Host "Applying .gitignore rules..."
            Get-Content $gitignorePath | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object {
                $item = $_.TrimEnd('/')
                if ($item) { [void]$ignoreList.Add($item) }
            }
        }
    }

    # --- Step 3: Confirm File Extensions to Include ---
    Write-Host "`nThese file extensions will be INCLUDED in the merge:" -ForegroundColor Yellow
    Write-Host ($includeExtensions -join ', ')
    $editExtensions = Read-Host "Do you want to edit this list? (y/N)"
    if ($editExtensions.ToLower() -eq 'y') {
        $newExtensions = Read-Host "Please enter the comma-separated list of extensions to include (e.g., '.js, .ts, .css')"
        $includeExtensions = $newExtensions.Split(',').Trim()
    }
    
    return [pscustomobject]@{
        IgnorePatterns = $ignoreList
        IncludeExtensions = $includeExtensions
    }
}


# =============================================================================
#  PHASE 3 & 4: MERGE AND OUTPUT
# =============================================================================
Function Start-MergeAndSave {
    param(
        $allFiles,
        $config
    )

    Write-Host "`n--- 🧩 Starting Merge Process ---" -ForegroundColor Green
    $basePath = (Get-Location).Path
    $stringBuilder = New-Object System.Text.StringBuilder

    # Filter the files based on user configuration
    $filesToMerge = $allFiles | Where-Object {
        $relativePath = $_.FullName.Substring($basePath.Length + 1)
        $include = $true

        # Check against ignore patterns
        foreach ($pattern in $config.IgnorePatterns) {
            if ($relativePath -like "$pattern*" -or $_.DirectoryName -like "*$pattern*") {
                $include = $false
                break
            }
        }

        # Check against included extensions
        if ($include) {
            $include = $config.IncludeExtensions -contains $_.Extension
        }

        $include
    }

    if (-not $filesToMerge) {
        Write-Host "No files match your criteria. Nothing to merge." -ForegroundColor Red
        return
    }

    Write-Host "Found $($filesToMerge.Count) files to merge."

    # Process and append each file
    foreach ($file in $filesToMerge) {
        $relativePath = $file.FullName.Substring($basePath.Length + 1).Replace('\', '/')
        [void]$stringBuilder.AppendLine("`n" + ("-"*80))
        [void]$stringBuilder.AppendLine("--- FILE: $relativePath ---")
        [void]$stringBuilder.AppendLine(("-")*80 + "`n")
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
            [void]$stringBuilder.AppendLine($content)
        } catch {
            [void]$stringBuilder.AppendLine("### ERROR: Could not read file. It might be binary or locked. ###")
        }
    }

    # --- Get Output Filename ---
    $outputFileName = Read-Host "`n--- 💾 Save As --`nEnter the output filename (e.g., 'project_context.md')"
    if (-not $outputFileName) { $outputFileName = "merged_output.md" }
    if (-not $outputFileName.EndsWith('.md') -and -not $outputFileName.EndsWith('.txt')) {
        $outputFileName += ".md"
    }

    # Save the file
    Set-Content -Path $outputFileName -Value $stringBuilder.ToString() -Encoding UTF8

    Write-Host "`n`n--- ✅ Success! ---" -ForegroundColor Green
    Write-Host "Merged $($filesToMerge.Count) files into '$outputFileName'."
    Write-Host "`n💡 Tip: The output is a Markdown (.md) file. You can easily convert it to PDF or DOCX using tools like:" -ForegroundColor Cyan
    Write-Host "   - VS Code with a 'Markdown PDF' extension."
    Write-Host "   - The command-line tool 'pandoc'."
    Write-Host "   - Opening the .md file in Microsoft Word."
}

# =============================================================================
#  SCRIPT EXECUTION
# =============================================================================
$allFiles = Get-ProjectAnalysis
if ($allFiles) {
    # Convert array to ArrayList to allow adding/removing items
    $ignoreList = [System.Collections.ArrayList]$defaultIgnoreDirs
    
    $userConfig = Get-UserConfiguration -ignoreList $ignoreList -includeExtensions $defaultTextExtensions
    Start-MergeAndSave -allFiles $allFiles -config $userConfig
}

Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)