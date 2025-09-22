<#
.SYNOPSIS
  A "File-Aware Smart Chunker" that intelligently splits a merged text file into parts, ensuring
  that no single source file is ever broken across multiple chunks. Includes smart input suggestions.

.DESCRIPTION
  Play #4 from My-Dev-Playbook. This definitive version solves AI context limits by treating each
  source file within a merged document as an atomic unit. It uses user-friendly AI presets and
  offers smart suggestions if a filename is misspelled or partially entered, ensuring a smooth
  user experience.

.NOTES
  Author: Sheikh Mahmudul Hasan Shium
  License: MIT
#>

# --- SCRIPT START ---

# Helper function for smart file searching and confirmation
Function Find-AndConfirmFile {
    param(
        [string]$Prompt
    )
    
    $userInput = Read-Host -Prompt $Prompt
    
    # Case 1: The user provided an exact, valid path.
    if (Test-Path $userInput) {
        return $userInput
    }

    # Case 2: The user provided a partial name. Let's search.
    # We add wildcards to search for any file containing the user's input.
    $matchingFiles = Get-ChildItem -Path . -Filter "*$userInput*" -File -ErrorAction SilentlyContinue
    
    if ($matchingFiles.Count -eq 1) {
        # Exactly one match was found - the ideal scenario!
        $suggestedFile = $matchingFiles[0].Name
        $confirmation = Read-Host "Did you mean '$suggestedFile'? (Y/n)"
        if ($confirmation.ToLower() -ne 'n') {
            return $suggestedFile
        } else {
            Write-Host "Action cancelled. Please try again." -ForegroundColor Yellow
            return $null
        }
    } elseif ($matchingFiles.Count -gt 1) {
        # Multiple matches found. Ask the user to be more specific.
        Write-Host "❌ ERROR: Multiple files found matching that name:" -ForegroundColor Red
        $matchingFiles.Name | ForEach-Object { Write-Host "   - $_" }
        Write-Host "Please be more specific."
        return $null
    } else {
        # No exact match and no partial matches found.
        Write-Host "❌ ERROR: File not found for '$userInput'." -ForegroundColor Red
        return $null
    }
}


Function Start-FileAwareChunker {
    # --- Phase 1: Configuration & User Input ---
    Clear-Host
    Write-Host "--- 📖 My-Dev-Playbook: The File-Aware Smart Chunker ---" -ForegroundColor Cyan

    # Use the new helper function to get the input file
    $inputFile = Find-AndConfirmFile -Prompt "`n📁 Please enter the path or a partial name of the merged file you want to split"
    if (-not $inputFile) {
        return # Exit if no valid file was found or confirmed
    }
    
    Write-Host "✅ Using file: '$inputFile'" -ForegroundColor Green

    # ... (The rest of the script remains the same) ...

    Write-Host "`n🧠 To create the best-sized chunks, please select the type of AI you are using:" -ForegroundColor Yellow
    Write-Host "[1] Standard AI (like the free versions of ChatGPT, Gemini, etc.)"
    Write-Host "[2] Advanced AI (like GPT-4, Claude 3, Gemini Advanced, etc. with a very large context window)"
    Write-Host "[3] Custom (You want to specify a character limit yourself)"
    $choice = Read-Host "Enter your choice (1, 2, or 3)"

    $maxCharsPerChunk = 0
    switch ($choice) {
        '1' { $maxCharsPerChunk = 25000 }
        '2' { $maxCharsPerChunk = 100000 }
        '3' {
            try { $maxCharsPerChunk = [int](Read-Host "Enter the maximum number of characters per chunk") }
            catch { Write-Host "❌ ERROR: Invalid number." -ForegroundColor Red; return }
        }
        default { Write-Host "❌ ERROR: Invalid choice." -ForegroundColor Red; return }
    }

    Write-Host "`nParsing input file into individual file units..."
    $mainContent = Get-Content -Path $inputFile -Raw
    $fileUnits = $mainContent -split '(?=(// Source:|--- FILE:))' | Where-Object { $_.Trim() }

    if ($fileUnits.Count -eq 0) {
        Write-Host "❌ ERROR: Could not find any recognizable file headers in '$inputFile'. Please use a file created by Play #1 or #2." -ForegroundColor Red; return
    }
    
    Write-Host "Packing $($fileUnits.Count) files into smart chunks..."
    $finalChunks = [System.Collections.Generic.List[string]]::new()
    $currentChunkBuilder = New-Object System.Text.StringBuilder

    foreach ($unit in $fileUnits) {
        if ($unit.Length -gt $maxCharsPerChunk) {
            $fileName = ($unit -split "`n")[0]
            Write-Host "⚠️ WARNING: A single file ($fileName) is larger than the chunk limit. It will be placed in its own chunk, but may still be too large for the AI." -ForegroundColor Yellow
        }
        if (($currentChunkBuilder.Length + $unit.Length) -gt $maxCharsPerChunk -and $currentChunkBuilder.Length -gt 0) {
            $finalChunks.Add($currentChunkBuilder.ToString())
            $currentChunkBuilder.Clear()
        }
        [void]$currentChunkBuilder.Append($unit)
    }

    if ($currentChunkBuilder.Length -gt 0) {
        $finalChunks.Add($currentChunkBuilder.ToString())
    }

    $outputDir = "output_chunks"
    if (Test-Path $outputDir) { Remove-Item -Path $outputDir -Recurse -Force }
    New-Item -Path $outputDir -ItemType Directory | Out-Null
    
    $totalChunks = $finalChunks.Count
    for ($i = 0; $i -lt $totalChunks; $i++) {
        $chunkNumber = $i + 1
        $stringBuilder = New-Object System.Text.StringBuilder
        $header = "//----- Part $chunkNumber of $totalChunks -----"
        [void]$stringBuilder.AppendLine($header)
        [void]$stringBuilder.AppendLine("")
        if ($chunkNumber -lt $totalChunks) {
            [void]$stringBuilder.AppendLine("// IMPORTANT: This is part $chunkNumber of $totalChunks. Do not give me a review or summary yet.")
            [void]$stringBuilder.AppendLine("// Simply acknowledge that you have received this part and are ready for the next one.")
        } else {
            [void]$stringBuilder.AppendLine("// This is the FINAL part ($chunkNumber of $totalChunks).")
            [void]$stringBuilder.AppendLine("// You now have the complete context. Please provide your full review and analysis based on ALL the parts I've sent you.")
        }
        [void]$stringBuilder.AppendLine("")
        [void]$stringBuilder.Append($finalChunks[$i])
        [void]$stringBuilder.AppendLine("")
        [void]$stringBuilder.AppendLine($header)
        $chunkFileName = "chunk_{0:D2}_of_{1:D2}.txt" -f $chunkNumber, $totalChunks
        $outputFilePath = Join-Path $outputDir $chunkFileName
        Set-Content -Path $outputFilePath -Value $stringBuilder.ToString() -Encoding UTF8
    }

    Write-Host "`n`n--- ✅ Success! ---" -ForegroundColor Green
    Write-Host "Split '$inputFile' into $totalChunks file-aware chunks."
    Write-Host "The files are located in the '$outputDir' folder."
    Write-Host "`nYour next steps:" -ForegroundColor Cyan
    Write-Host "1. Go to your AI chat."
    Write-Host "2. Copy the entire content of 'chunk_01_of_XX.txt' and paste it."
    Write-Host "3. Wait for the AI's confirmation."
    Write-Host "4. Repeat for all subsequent chunks until you paste the final one."
}

# =============================================================================
#  SCRIPT EXECUTION
# =============================================================================
Start-FileAwareChunker

Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)