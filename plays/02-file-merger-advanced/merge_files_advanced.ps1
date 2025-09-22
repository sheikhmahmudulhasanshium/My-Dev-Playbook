<#
.SYNOPSIS
  A secure, advanced, and location-independent utility to analyze a project and merge selected files.
  It asks for the project path, making it runnable from anywhere.

.DESCRIPTION
  Play #2 from My-Dev-Playbook. This script can be run from any location. It will ask for the path
  to your project folder, then perform a detailed analysis and guide you through an interactive
  merge process. It sanitizes .env files and provides robust ignore capabilities, ensuring a
  secure and user-friendly experience.

.NOTES
  Author: Sheikh Mahmudul Hasan Shium
  License: MIT
#>

# --- SCRIPT START ---

# =============================================================================
#  UI HELPERS
# =============================================================================
Function Show-SpinnerWhile {
    param([scriptblock]$ScriptBlock, [string]$Message = "Working", $ArgumentList)
    $spinner = @('|', '/', '-', '\'); $i = 0; $job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
    while ($job.State -eq 'Running') { Write-Host -NoNewline "`r$($spinner[$i++ % $spinner.Length]) $Message..."; Start-Sleep -Milliseconds 100 }
    Write-Host "`r" + (" " * ($Message.Length + 5)) + "`r"; $result = Receive-Job -Job $job; Remove-Job -Job $job; return $result
}

# --- Initial Configuration ---
[string[]]$defaultTextExtensions = @(".txt", ".md", ".json", ".xml", ".yml", ".yaml", ".html", ".css", ".js", ".jsx", ".ts", ".tsx", ".py", ".cpp", ".c", ".h", ".cs", ".java", ".php", ".rb", ".go", ".rs", ".ps1", ".sh", ".bat", ".sql", ".gitignore", "Dockerfile", ".dockerignore")
[string[]]$defaultIgnoreDirs = @("node_modules", ".git", "dist", "build", "out", "coverage", ".vscode", ".idea", "bin", "obj")
[string[]]$defaultIgnoreFiles = @("package-lock.json", "yarn.lock", "pnpm-lock.yaml")

# =============================================================================
#  PHASE 0: GET AND VALIDATE PROJECT PATH
# =============================================================================
Function Get-ProjectRoot {
    Clear-Host
    Write-Host "--- 🚀 My-Dev-Playbook: Secure Advanced File Merger ---" -ForegroundColor Cyan
    do {
        $projectPath = Read-Host "`n📁 Please enter the full path to your project folder"
        if ([string]::IsNullOrWhiteSpace($projectPath)) { Write-Host "No path entered. Exiting script." -ForegroundColor Yellow; return $null }
        $pathExists = Test-Path $projectPath
        $isContainer = $false
        if ($pathExists) { $isContainer = Test-Path $projectPath -PathType Container }
        if (-not $pathExists) { Write-Host "❌ ERROR: Path not found. Please check for typos and try again." -ForegroundColor Red }
        elseif (-not $isContainer) { Write-Host "❌ ERROR: The path provided is a file, not a folder. Please enter a folder path." -ForegroundColor Red }
    } while (-not $pathExists -or -not $isContainer)
    Write-Host "✅ Using project path: $projectPath" -ForegroundColor Green
    return $projectPath
}

# =============================================================================
#  ANALYSIS & CONFIGURATION (Phases 1 & 2)
# =============================================================================
Function Get-ProjectAnalysis {
    param([string]$basePath)
    
    $analysisCode = {
        param($path)
        # *** THE DEFINITIVE FIX: Force the background job to change its location ***
        Set-Location -Path $path
        
        # Now we can safely use relative paths like '.' because we are in the right directory.
        $allFileObjects = Get-ChildItem -Path . -Recurse -File -ErrorAction SilentlyContinue
        if (-not $allFileObjects) { return $null }

        $extensionGroups = $allFileObjects | Group-Object -Property Extension | Sort-Object -Property Count -Descending
        $heavyDirs = Get-ChildItem -Path . -Directory -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            [pscustomobject]@{ Name = $_.FullName.Substring($path.Length + 1); SizeMB = [math]::Round($size / 1MB, 2) }
        } | Sort-Object -Property SizeMB -Descending | Select-Object -First 5
        return [pscustomobject]@{ AllFilePaths = $allFileObjects.FullName; ExtensionGroups = $extensionGroups; HeavyDirs = $heavyDirs }
    }
    
    $analysisResult = Show-SpinnerWhile -ScriptBlock $analysisCode -ArgumentList $basePath -Message "Analyzing project structure"
    if (-not $analysisResult) { Write-Host "No files found in directory '$basePath'." -ForegroundColor Red; return $null }
    
    Write-Host "`n--- 📊 Project Analysis Complete ---" -ForegroundColor Green
    Write-Host "Total files found: $($analysisResult.AllFilePaths.Count)"
    Write-Host "`n📁 Top 5 Heaviest Folders:" -ForegroundColor Yellow
    if ($analysisResult.HeavyDirs) { $analysisResult.HeavyDirs | Format-Table -AutoSize | Out-Host }
    Write-Host "`n📄 File Types Summary (Top 10):" -ForegroundColor Yellow
    $analysisResult.ExtensionGroups | Select-Object -First 10 | ForEach-Object { $ext = if ($_.Name) { $_.Name } else { "[No Extension]" }; Write-Host ("   - {0,-15} : {1} files" -f $ext, $_.Count) } | Out-Host
    return $analysisResult.AllFilePaths
}

Function Get-UserConfiguration {
    param([string]$basePath, [System.Collections.ArrayList]$ignoreDirs, [System.Collections.ArrayList]$ignoreFiles, [string[]]$includeExtensions)
    
    Write-Host "`n--- 🔧 Interactive Configuration ---" -ForegroundColor Green
    Write-Host "`nThese DIRECTORIES will be ignored:" -ForegroundColor Yellow; $ignoreDirs | ForEach-Object { Write-Host "   - $_" }
    if ((Read-Host "Do you want to ignore these directories? (Y/n)").ToLower() -eq 'n') { $ignoreDirs.Clear() }
    if ($addMore = Read-Host "Add more directories to ignore? (comma-separated, press Enter to skip)") { $addMore.Split(',').Trim() | ForEach-Object { [void]$ignoreDirs.Add($_) } }
    
    Write-Host "`nThese specific FILES will be ignored:" -ForegroundColor Yellow; $ignoreFiles | ForEach-Object { Write-Host "   - $_" }
    if ((Read-Host "Do you want to ignore these files? (Y/n)").ToLower() -eq 'n') { $ignoreFiles.Clear() }
    if ($addMoreFiles = Read-Host "Add more files to ignore? (comma-separated, press Enter to skip)") { $addMoreFiles.Split(',').Trim() | ForEach-Object { [void]$ignoreFiles.Add($_) } }

    $gitignorePath = Join-Path $basePath ".gitignore"
    if (Test-Path $gitignorePath) {
        if ((Read-Host "`nFound a .gitignore file in '$basePath'. Use its rules? (Y/n)").ToLower() -ne 'n') {
            Write-Host "Applying .gitignore rules..."
            Get-Content $gitignorePath | Where-Object { $_.Trim() -and $_ -notmatch '^\s*#' } | ForEach-Object {
                $item = $_.Trim(); if ($item.EndsWith('/')) { [void]$ignoreDirs.Add($item.TrimEnd('/')) } else { [void]$ignoreFiles.Add($item) }
            }
        }
    }

    Write-Host "`nThese file extensions will be INCLUDED:" -ForegroundColor Yellow; Write-Host ($includeExtensions -join ', ')
    if ($newExt = Read-Host "To change, enter a new list. Otherwise, press Enter") { $includeExtensions = $newExt.Split(',').Trim() }
    
    return [pscustomobject]@{ IgnoreDirs = $ignoreDirs; IgnoreFiles = $ignoreFiles; IncludeExtensions = $includeExtensions }
}

# =============================================================================
#  MERGE AND OUTPUT (Phase 3 & 4)
# =============================================================================
Function Test-IsIgnored {
    param($relativePath, $fileName, $config)
    $normalizedPath = $relativePath.Replace('\', '/'); $pathParts = $normalizedPath.Split('/')
    if ($config.IgnoreFiles -contains $fileName) { return $true }
    foreach ($pattern in $config.IgnoreFiles) { if ($fileName -like $pattern) { return $true } }
    foreach ($part in $pathParts) { if ($config.IgnoreDirs -contains $part) { return $true } }
    return $false
}

Function Start-MergeAndSave {
    param([string]$basePath, [string[]]$allFilePaths, $config)

    Write-Host "`n--- 🧩 Starting Merge Process ---" -ForegroundColor Green
    $stringBuilder = New-Object System.Text.StringBuilder

    $filesToMerge = $allFilePaths | ForEach-Object { Get-Item $_ -ErrorAction SilentlyContinue } | Where-Object {
        $_ -and (-not (Test-IsIgnored -relativePath ($_.FullName.Substring($basePath.Length + 1)) -fileName $_.Name -config $config)) -and ($config.IncludeExtensions -contains $_.Extension)
    }

    if (-not $filesToMerge) { Write-Host "No files match your criteria. Nothing to merge." -ForegroundColor Red; return }
    
    Write-Host "Found $($filesToMerge.Count) files to merge."
    
    $i = 0
    foreach ($file in $filesToMerge) {
        $i++; Write-Progress -Activity "Merging Files" -Status "Processing: $($file.Name)" -PercentComplete (($i / $filesToMerge.Count) * 100)
        $relativePath = $file.FullName.Substring($basePath.Length + 1).Replace('\', '/')
        [void]$stringBuilder.AppendLine("`n" + ("-"*80)); [void]$stringBuilder.AppendLine("--- FILE: $relativePath ---"); [void]$stringBuilder.AppendLine(("-")*80 + "`n")

        if ($file.Name -like ".env*") {
            [void]$stringBuilder.AppendLine("# Content of $($file.Name) has been sanitized for security.")
            Get-Content -Path $file.FullName | ForEach-Object {
                if ($_ -match '^([^#=]+)=(.*)') {
                    $key = $matches[1].Trim(); $value = $matches[2].Trim(); $quote = ""
                    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) { $quote = $value[0]; $value = $value.Substring(1, $value.Length - 2) }
                    $placeholder = "$quote[$($value.Length)-character value]$quote"
                    [void]$stringBuilder.AppendLine("$key=$placeholder")
                } else { [void]$stringBuilder.AppendLine($_) }
            }
        } else {
            try { [void]$stringBuilder.AppendLine((Get-Content -Path $file.FullName -Raw)) }
            catch { [void]$stringBuilder.AppendLine("### ERROR: Could not read file. ###") }
        }
    }
    Write-Progress -Activity "Merging Files" -Completed

    $outputFileName = Read-Host "`n`n--- 💾 Save As --`nEnter the output filename (e.g., 'project_context.md')"
    if (-not $outputFileName) { $outputFileName = "merged_output.md" }
    $outputFilePath = Join-Path $basePath $outputFileName

    Set-Content -Path $outputFilePath -Value $stringBuilder.ToString() -Encoding UTF8
    Write-Host "`n`n--- ✅ Success! ---" -ForegroundColor Green
    Write-Host "Merged $($filesToMerge.Count) files into '$outputFilePath'."
}

# =============================================================================
#  SCRIPT EXECUTION
# =============================================================================
$projectPath = Get-ProjectRoot
if ($projectPath) {
    $allFilePaths = Get-ProjectAnalysis -basePath $projectPath
    if ($allFilePaths) {
        $ignoreDirsList = [System.Collections.ArrayList]$defaultIgnoreDirs
        $ignoreFilesList = [System.Collections.ArrayList]$defaultIgnoreFiles
        $userConfig = Get-UserConfiguration -basePath $projectPath -ignoreDirs $ignoreDirsList -ignoreFiles $ignoreFilesList -includeExtensions $defaultTextExtensions
        Start-MergeAndSave -basePath $projectPath -allFilePaths $allFilePaths -config $userConfig
    }
}

Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)