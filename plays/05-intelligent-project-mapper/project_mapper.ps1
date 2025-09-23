<#
.SYNOPSIS
  An intelligent, location-independent utility that creates visually appealing and insightful maps
  of a project's directory structure. Includes granular filtering, safety checks, and a
  concise, automatic execution log appended to every saved map.

.DESCRIPTION
  Play #5 from My-Dev-Playbook. This script uses a reliable recursive algorithm to map any project
  folder. It allows the user to precisely control what is included by confirming ignore lists and
  filtering by file extensions. It also includes a safe-overwrite prompt. Every saved output
  file contains both the generated project map and a comprehensive execution log for full
  transparency and diagnostics.

.NOTES
  Author: Sheikh Mahmudul Hasan Shium
  License: MIT
#>

# --- SCRIPT START ---

# =============================================================================
#  LOGGING & GLOBAL STATE
# =============================================================================
$global:logEntries = [System.Collections.Generic.List[string]]::new()

Function Add-LogEntry {
    param([string]$Message, [string]$Category = 'INFO')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $global:logEntries.Add("[$timestamp] [$($Category.ToUpper())] $Message")
}

# --- Initial Configuration ---
$baseIgnoreDirs = @("node_modules", ".git", "dist", "build", "out", "coverage", ".vscode", ".idea", "bin", "obj", ".next", ".svelte-kit", ".nuxt")
$intelligentIgnoreFiles = @("package-lock.json", "yarn.lock", "pnpm-lock.yaml", ".DS_Store", "*.log")
$summaryKeywords = @{ "module" = "modules"; "controller" = "controllers"; "service" = "services"; "guard" = "guards"; "decorator" = "decorators"; "enum" = "enums"; "strategy" = "strategies"; "component" = "components"; "pipe" = "pipes" }

# =============================================================================
#  HELPER FUNCTIONS
# =============================================================================
Function Get-ProjectRoot {
    Clear-Host
    Write-Host "--- 🚀 My-Dev-Playbook: Intelligent Project Mapper ---" -ForegroundColor Cyan
    Add-LogEntry -Message "Script started. Awaiting user input for project path." -Category 'START'
    do {
        $rawInput = Read-Host "`n📁 Please enter or paste the full path to your project folder"
        if ([string]::IsNullOrWhiteSpace($rawInput)) {
            $confirmExit = Read-Host "No path entered. Do you want to exit? (y/N)"
            Add-LogEntry -Message "User provided no input for path." -Category 'INPUT'
            Add-LogEntry -Message "User chose to exit: $($confirmExit.ToLower() -eq 'y')." -Category 'DECISION'
            if ($confirmExit.ToLower() -eq 'y') { return $null }; continue
        }
        Add-LogEntry -Message "User raw input for path: `"$rawInput`"" -Category 'INPUT'
        $sanitizedPath = $rawInput -replace '^.*:\s*', ''; $sanitizedPath = $sanitizedPath.Trim().Trim('"')
        Add-LogEntry -Message "Sanitized path: '$sanitizedPath'" -Category 'PROCESS'

        if (Test-Path -LiteralPath $sanitizedPath -PathType Container) {
            $projectPath = $sanitizedPath; Add-LogEntry -Message "Path validation successful: '$projectPath' is a valid directory." -Category 'SUCCESS'; break
        }
        else {
            $errorMessage = "The path '$sanitizedPath' is not a valid folder. Please try again."; Add-LogEntry -Message "Path validation failed: $errorMessage" -Category 'ERROR'; Write-Host "❌ ERROR: $errorMessage" -ForegroundColor Red
        }
    } while ($true)
    Write-Host "✅ Using project path: $projectPath" -ForegroundColor Green
    return $projectPath
}

Function Get-UserConfiguration {
    param([string]$basePath, [System.Collections.ArrayList]$ignoreDirs, [System.Collections.ArrayList]$ignoreFiles)
    Write-Host "`n--- ⚙️ Configure Intelligent Map Filters ---" -ForegroundColor Cyan; Add-LogEntry -Message "Starting user configuration for filters."
    Write-Host "`nThese DIRECTORIES will be ignored:" -ForegroundColor Yellow; $ignoreDirs | ForEach-Object { Write-Host "   - $_" }
    $confirmDirs = Read-Host "Confirm ignore list for directories? (Y/n)"; Add-LogEntry -Message "User input for directory ignore list confirmation: '$confirmDirs'" -Category 'INPUT'
    if ($confirmDirs.ToLower() -eq 'n') { $ignoreDirs.Clear(); Add-LogEntry -Message "User chose to clear the directory ignore list." -Category 'DECISION' }

    Write-Host "`nThese specific FILES will be ignored:" -ForegroundColor Yellow; $ignoreFiles | ForEach-Object { Write-Host "   - $_" }
    $confirmFiles = Read-Host "Confirm ignore list for files? (Y/n)"; Add-LogEntry -Message "User input for file ignore list confirmation: '$confirmFiles'" -Category 'INPUT'
    if ($confirmFiles.ToLower() -eq 'n') { $ignoreFiles.Clear(); Add-LogEntry -Message "User chose to clear the file ignore list." -Category 'DECISION' }

    $includeExtensions = Read-Host "`nTo show only specific file types, enter a list (e.g., '.ts,.tsx'). Press Enter to show ALL files"
    Add-LogEntry -Message "User input for included extensions: '$includeExtensions'" -Category 'INPUT'
    if ([string]::IsNullOrWhiteSpace($includeExtensions)) { $includeExtensions = "*" }

    $finalConfig = [pscustomobject]@{ IgnoreDirs = $ignoreDirs; IgnoreFiles = $ignoreFiles; IncludeExtensions = $includeExtensions.Split(',').Trim() }
    Add-LogEntry -Message "Final filter configuration created: $($finalConfig | Out-String | ForEach-Object { $_.Trim() })" -Category 'CONFIG'
    return $finalConfig
}

Function Get-FolderSummary {
    param([string]$folderPath, $config)
    try {
        $files = Get-ChildItem -Path $folderPath -File -ErrorAction Stop
        if (-not $files) { return "" }
        if ($config.IncludeExtensions[0] -ne '*') { $files = $files | Where-Object { $config.IncludeExtensions -contains $_.Extension } }
        $keywordCounts = @{}; foreach ($file in $files) { foreach ($keyword in $summaryKeywords.Keys) { if ($file.Name -like "*.$keyword.*" -or $file.Name -like "*-$keyword.*") { $description = $summaryKeywords[$keyword]; $keywordCounts[$description] = $keywordCounts[$description] + 1 } } }
        if ($keywordCounts.Count -eq 0) { return "" }
        $summary = $keywordCounts.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { "$($_.Value) $($_.Name)" }
        return " ($($summary -join ', '))"
    } catch {
        Add-LogEntry -Message "An exception occurred in Get-FolderSummary for path '$folderPath': $($_.Exception.Message)" -Category 'EXCEPTION'
        return " (Error reading contents)"
    }
}

Function Build-ProjectTree {
    param($directory, $prefix, $maxDepth, $currentDepth, $config, [System.Collections.Generic.List[string]]$outputCollector)
    if ($currentDepth -ge $maxDepth) { return } # No need to log this, it's normal behavior not an error.
    
    # The detailed traversal logs below were essential for debugging but are too noisy for normal use.
    # They can be un-commented if deep debugging is needed again in the future.
    # Add-LogEntry -Message "Entering directory: $($directory.FullName)" -Category 'TRAVERSAL'

    try {
        $items = Get-ChildItem -Path $directory.FullName -ErrorAction Stop
    } catch {
        Add-LogEntry -Message "Could not read items in directory '$($directory.FullName)'. It might be a permissions issue. Error: $($_.Exception.Message)" -Category 'EXCEPTION'
        $outputCollector.Add("$prefix└── ⚠️ Error reading this directory")
        return
    }

    $filteredItems = @()
    foreach ($item in $items) {
        $isSkipped = $false
        if ($config.IgnoreDirs -contains $item.Name) { $isSkipped = $true }
        elseif ($config.IsIntelligent -and ($item -is [System.IO.FileInfo])) {
            foreach ($pattern in $config.IgnoreFiles) { if ($item.Name -like $pattern) { $isSkipped = $true; break } }
        }
        elseif (($item -is [System.IO.FileInfo]) -and ($config.IncludeExtensions[0] -ne '*') -and ($config.IncludeExtensions -notcontains $item.Extension)) {
            $isSkipped = $true
        }
        if (-not $isSkipped) { $filteredItems += $item }
    }

    $itemCount = $filteredItems.Count
    for ($i = 0; $i -lt $itemCount; $i++) {
        $item = $filteredItems[$i]; $isLast = ($i -eq $itemCount - 1); $marker = if ($isLast) { "└── " } else { "├── " }
        if ($item -is [System.IO.DirectoryInfo]) {
            $summary = if ($config.IsIntelligent) { Get-FolderSummary -folderPath $item.FullName -config $config } else { "" }
            $outputCollector.Add("$prefix$marker📁 $($item.Name)$summary")
            $newPrefix = if ($isLast) { $prefix + "    " } else { $prefix + "│   " }
            Build-ProjectTree -directory $item -prefix $newPrefix -maxDepth $maxDepth -currentDepth ($currentDepth + 1) -config $config -outputCollector $outputCollector
        } else {
            $outputCollector.Add("$prefix$marker📄 $($item.Name)")
        }
    }
}

# =============================================================================
#  MAIN SCRIPT LOGIC
# =============================================================================
$projectPath = Get-ProjectRoot
if ($projectPath) {
    Write-Host "`n--- 🗺️  Select Map Intensity ---" -ForegroundColor Cyan
    Write-Host "[1] Overview (Quick summary)"
    Write-Host "[2] Intelligent Tree (Custom filters)"
    Write-Host "[3] Complete Project Tree (Hides major noise)"
    $intensity = Read-Host "Enter your choice (1, 2, 3)"
    Add-LogEntry -Message "User selected map intensity: '$intensity'" -Category 'INPUT'

    $config = [pscustomobject]@{ IgnoreDirs = [System.Collections.ArrayList]$baseIgnoreDirs; IgnoreFiles = [System.Collections.ArrayList]$intelligentIgnoreFiles; IncludeExtensions = @('*'); IsIntelligent = $false }
    if ($intensity -eq '2') {
        $config.IsIntelligent = $true
        $userConfig = Get-UserConfiguration -basePath $projectPath -ignoreDirs $config.IgnoreDirs -ignoreFiles $config.IgnoreFiles
        $config.IgnoreDirs = $userConfig.IgnoreDirs; $config.IgnoreFiles = $userConfig.IgnoreFiles; $config.IncludeExtensions = $userConfig.IncludeExtensions
    }
    
    $maxDepth = 99
    if ($intensity -ne '1') {
        $depthInput = Read-Host "Enter max display depth (e.g., 3, or press Enter for no limit)"
        Add-LogEntry -Message "User input for max depth: '$depthInput'" -Category 'INPUT'
        if ($depthInput -match '^\d+$') { $maxDepth = [int]$depthInput }
    }
    Add-LogEntry -Message "Max depth for tree traversal set to: $maxDepth" -Category 'CONFIG'

    $outputLines = [System.Collections.Generic.List[string]]::new()
    $outputLines.Add("Project Map for: $projectPath`n")
    
    Write-Host "`nGenerating project map... (Press Ctrl+C to cancel if it takes too long)" -ForegroundColor Yellow
    Add-LogEntry -Message "Starting project map generation..." -Category 'PROCESS'
    
    if ($intensity -eq '1') {
        $outputLines.Add("📊 Summary:")
        try {
            $items = Get-ChildItem -Path $projectPath -Recurse -Exclude $config.IgnoreDirs -ErrorAction Stop
            $dirCount = ($items | Where-Object { $_.PSIsContainer }).Count; $fileCount = ($items | Where-Object { -not $_.PSIsContainer }).Count
            $outputLines.Add("   - Total Directories: $dirCount"); $outputLines.Add("   - Total Files: $fileCount")
            Add-LogEntry -Message "Generated 'Overview' summary. Dirs: $dirCount, Files: $fileCount." -Category 'OUTPUT'
        } catch {
            $errorMessage = "Failed to get item summary. Error: $($_.Exception.Message)"
            $outputLines.Add("   - Error: $errorMessage"); Add-LogEntry -Message $errorMessage -Category 'EXCEPTION'
        }
    }
    elseif ($intensity -in '2', '3') {
        if ($intensity -eq '2') { $outputLines.Add("🌳 Intelligent Tree (hiding noise):") } else { $outputLines.Add("🌳 Complete Project Tree (hiding major noise folders):") }
        $outputLines.Add("$(Split-Path $projectPath -Leaf)/")
        Build-ProjectTree -directory (Get-Item $projectPath) -prefix "" -maxDepth $maxDepth -currentDepth 0 -config $config -outputCollector $outputLines
        Add-LogEntry -Message "Generated 'Tree' output successfully." -Category 'OUTPUT'
    }
    else {
        Add-LogEntry -Message "User entered an invalid choice for intensity: '$intensity'" -Category 'ERROR'; Write-Host "❌ Invalid choice." -ForegroundColor Red
    }
    
    if ($outputLines.Count -gt 2) {
        $mapOutput = $outputLines -join "`n"
        Clear-Host; Write-Host "--- 🗺️ Project Map Generated ---" -ForegroundColor Green; Write-Host $mapOutput
        
        $fileName = Read-Host "`n`n--- 💾 Save As --`nEnter a filename to save this map (e.g., 'project_map.md'), or press Enter to skip"
        Add-LogEntry -Message "User input for save filename: '$fileName'" -Category 'INPUT'
        
        if (-not [string]::IsNullOrWhiteSpace($fileName)) {
            if (-not $fileName.EndsWith('.md') -and -not $fileName.EndsWith('.txt')) { $fileName += ".txt" }
            $outputFilePath = Join-Path $projectPath $fileName
            $canWrite = $true
            if (Test-Path $outputFilePath) {
                $overwrite = Read-Host "File '$outputFilePath' already exists. Overwrite? (y/N)"; Add-LogEntry -Message "File exists. User asked to overwrite. Input: '$overwrite'." -Category 'INPUT'
                if ($overwrite.ToLower() -ne 'y') {
                    $canWrite = $false; Add-LogEntry -Message "User chose NOT to overwrite. Save operation cancelled." -Category 'DECISION'; Write-Host "Save cancelled." -ForegroundColor Yellow
                }
            }
            if ($canWrite) {
                Add-LogEntry -Message "Preparing final output for saving to '$outputFilePath'." -Category 'PROCESS'
                $logOutput = $global:logEntries -join "`n"
                $finalOutput = "$mapOutput`n`n`n--- SCRIPT EXECUTION LOG ---`n$logOutput"
                try {
                    # --- FINAL FIX: Explicitly set the encoding to UTF-8 to preserve tree characters ---
                    Set-Content -Path $outputFilePath -Value $finalOutput -Encoding Utf8 -ErrorAction Stop
                    Add-LogEntry -Message "Successfully saved map and log to '$outputFilePath'." -Category 'SUCCESS'; Write-Host "✅ Map and execution log saved to '$outputFilePath'" -ForegroundColor Green
                } catch {
                    $errorMessage = "Failed to save file. Error: $($_.Exception.Message)"; Add-LogEntry -Message $errorMessage -Category 'EXCEPTION'; Write-Host "❌ ERROR: $errorMessage" -ForegroundColor Red
                }
            }
        } else {
            Add-LogEntry -Message "User chose not to save the file." -Category 'DECISION'
        }
    }
}

Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)