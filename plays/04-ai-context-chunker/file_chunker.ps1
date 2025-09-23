<#
.SYNOPSIS
  An intelligent utility that splits a large, merged context file into smaller, file-aware chunks
  to overcome AI context window limitations, without ever breaking a single source file in half.

.DESCRIPTION
  Play #4 from My-Dev-Playbook. This script takes a merged file (created by Play #1 or #2)
  and divides it into multiple parts. Its core feature is "file-awareness": it reads the
  file boundaries within the input and ensures that no single file's content is ever split
  across two different output chunks. This preserves code integrity and provides clean,
  complete context to the AI.

.NOTES
  Author: Sheikh Mahmudul Hasan Shium
  License: MIT
#>

# --- SCRIPT START ---

# =============================================================================
#  UI & HELPER FUNCTIONS
# =============================================================================
Function Get-MergedFile {
    Clear-Host
    Write-Host "--- 🚀 My-Dev-Playbook: The File-Aware Smart Chunker ---" -ForegroundColor Cyan
    do {
        $partialName = Read-Host "`n📁 Enter the full or partial name of the merged file to chunk (e.g., 'merged' or 'context.txt')"
        if ([string]::IsNullOrWhiteSpace($partialName)) { Write-Host "No filename entered. Please try again." -ForegroundColor Yellow; continue }

        # Find matching files in the current directory
        $matches = Get-ChildItem -Path . -Filter "*$partialName*" -File | Where-Object { $_.Name -like "*.txt" -or $_.Name -like "*.md" }
        
        if ($matches.Count -eq 0) { Write-Host "❌ No matching .txt or .md files found. Please check the name and try again." -ForegroundColor Red; continue }
        if ($matches.Count -eq 1) {
            $confirm = Read-Host "Found one match: '$($matches[0].Name)'. Use this file? (Y/n)"
            if ($confirm.ToLower() -ne 'n') { return $matches[0] }
        } else {
            Write-Host "Multiple matches found. Please select one:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $matches.Count; $i++) { Write-Host "[$($i+1)] $($matches[$i].Name)" }
            $choice = Read-Host "Enter the number of the file you want to use"
            if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $matches.Count) {
                return $matches[[int]$choice - 1]
            } else {
                Write-Host "Invalid selection." -ForegroundColor Red
            }
        }
    } while ($true)
}

# =============================================================================
#  CORE LOGIC
# =============================================================================
Function Start-ChunkingProcess {
    param($inputFile)

    # --- Phase 1: Configuration ---
    Write-Host "`n--- 🧠 Select AI Preset ---" -ForegroundColor Cyan
    Write-Host "Choose a preset based on your AI model's context window."
    Write-Host "[1] Standard (e.g., GPT-3.5, Claude Sonnet) - Smaller chunks (~14KB)"
    Write-Host "[2] Advanced (e.g., GPT-4, Claude Opus) - Larger chunks (~90KB)"
    $presets = @{ "1" = 14000; "2" = 90000 }
    do { $choice = Read-Host "Enter your choice (1 or 2)"; if ($presets.ContainsKey($choice)) { break } } while ($true)
    $maxChunkSize = $presets[$choice]
    
    # --- Phase 2: File Parsing ---
    Write-Host "`nParsing merged file..." -ForegroundColor Yellow
    $rawContent = Get-Content -Path $inputFile.FullName -Raw
    $separatorPattern = "(?m)^(-{80}`r?`n--- FILE: .*? ---`r?`n-{80})"
    $fileBlocks = [regex]::Split($rawContent, $separatorPattern)
    $separators = [regex]::Matches($rawContent, $separatorPattern)

    # Reconstruct file units (separator + content)
    $fileUnits = [System.Collections.Generic.List[PSCustomObject]]::new()
    # Skip the first split result if it's empty (which happens if the file starts with the separator)
    $startIndex = if ([string]::IsNullOrWhiteSpace($fileBlocks[0])) { 1 } else { 0 }
    
    # Handle files that don't match the separator pattern (e.g., from a simple copy-paste)
    if ($separators.Count -eq 0 -and $fileBlocks.Length -eq 1) {
        Write-Host "No standard file separators found. Treating the entire file as one unit." -ForegroundColor Yellow
        $fileUnits.Add([PSCustomObject]@{ Content = $rawContent; Size = $rawContent.Length })
    } else {
        for ($i = $startIndex; $i -lt $fileBlocks.Length; $i++) {
            $contentIndex = $i - $startIndex
            if ($contentIndex -lt $separators.Count) {
                $fullContent = $separators[$contentIndex].Value + "`n" + $fileBlocks[$i]
                $fileUnits.Add([PSCustomObject]@{ Content = $fullContent; Size = $fullContent.Length })
            }
        }
    }

    Write-Host "Identified $($fileUnits.Count) individual file units."

    # --- Phase 3: Smart Chunking ---
    Write-Host "Packing files into chunks..." -ForegroundColor Yellow
    $chunks = [System.Collections.Generic.List[string]]::new()
    $stringBuilder = New-Object System.Text.StringBuilder

    foreach ($unit in $fileUnits) {
        # Oversized File Check
        if ($unit.Size -gt $maxChunkSize) {
            Write-Host "⚠️ WARNING: A file unit is larger than the chunk size and will be isolated." -ForegroundColor Red
            if ($stringBuilder.Length -gt 0) { $chunks.Add($stringBuilder.ToString()); $stringBuilder.Clear() } # Finalize previous chunk
            $chunks.Add($unit.Content) # Add oversized file as its own chunk
            continue
        }

        # Pack into current chunk if it fits
        if (($stringBuilder.Length + $unit.Size) -gt $maxChunkSize) {
            $chunks.Add($stringBuilder.ToString()); $stringBuilder.Clear() # Finalize chunk
        }
        [void]$stringBuilder.Append($unit.Content)
    }

    if ($stringBuilder.Length -gt 0) { $chunks.Add($stringBuilder.ToString()) } # Add the last chunk

    # --- Phase 4: Output Generation ---
    if ($chunks.Count -eq 0) { Write-Host "`nNo content to chunk. Exiting." -ForegroundColor Yellow; return }

    Write-Host "`nPacking complete. Generated $($chunks.Count) chunks."
    $outputDir = "output_chunks"
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

    $totalChunks = $chunks.Count
    for ($i = 0; $i -lt $totalChunks; $i++) {
        $chunkNum = $i + 1
        $outputFileName = Join-Path $outputDir "output_part_$($chunkNum)_of_$totalChunks.txt"
        $finalContent = New-Object System.Text.StringBuilder

        # Add AI State Management Prompts
        if ($totalChunks -gt 1) {
            if ($chunkNum -lt $totalChunks) {
                [void]$finalContent.AppendLine("### PART $chunkNum OF $totalChunks ###")
                [void]$finalContent.AppendLine("### THIS IS A MULTI-PART SUBMISSION. DO NOT START YOUR FULL ANALYSIS YET. ###")
                [void]$finalContent.AppendLine("### WAIT FOR THE MESSAGE 'ALL PARTS SENT' BEFORE YOU BEGIN. ###`n")
            } else {
                [void]$finalContent.AppendLine("### FINAL PART ($chunkNum OF $totalChunks) ###")
                [void]$finalContent.AppendLine("### ALL PARTS SENT. YOU NOW HAVE THE COMPLETE CONTEXT. ###")
                [void]$finalContent.AppendLine("### PLEASE BEGIN YOUR FULL AND COMPREHENSIVE ANALYSIS NOW. ###`n")
            }
        }
        
        [void]$finalContent.Append($chunks[$i])
        Set-Content -Path $outputFileName -Value $finalContent.ToString() -Encoding UTF8
        Write-Progress -Activity "Saving Chunks" -Status "Writing $outputFileName" -PercentComplete (($chunkNum / $totalChunks) * 100)
    }
    Write-Progress -Activity "Saving Chunks" -Completed

    Write-Host "`n`n--- ✅ Success! ---" -ForegroundColor Green
    Write-Host "Your file has been split into $totalChunks parts inside the '$outputDir' folder."
    Write-Host "`nYour next steps:" -ForegroundColor Cyan
    Write-Host "1. Open the '$outputDir' folder."
    Write-Host "2. Copy and paste the content of each file, in order, into your AI chat."
    Write-Host "3. The prompts are already included to manage the AI's state."
}

# =============================================================================
#  SCRIPT EXECUTION
# =============================================================================
$mergedFile = Get-MergedFile
if ($mergedFile) {
    Start-ChunkingProcess -inputFile $mergedFile
}

Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)