<#
.SYNOPSIS
  An interactive utility to generate multiple, secure, and random passkeys, formatted
  and ready for use in .env files or other configuration.

.DESCRIPTION
  Play #7 from My-Dev-Playbook. This script acts as a "Key Architect" for developers.
  It interactively prompts the user for the number of keys needed, their variable names,
  and the desired complexity (via presets or custom rules). It then generates the secrets
  and offers to safely append them to a file.

.NOTES
  Author: Sheikh Mahmudul Hasan Shium
  License: MIT
#>

# --- SCRIPT START ---

# =============================================================================
#  CORE GENERATOR FUNCTION
# =============================================================================
Function Get-RandomString {
    param(
        [int]$Length,
        [bool]$IncludeNumbers,
        [bool]$IncludeSpecialChars
    )
    
    # Define character sets
    $lowerCase = 'abcdefghijklmnopqrstuvwxyz'
    $upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $numbers = '0123456789'
    $specialChars = '!@#$%^&*()_+-=[]{};:,.<>/?'
    
    # Build the final character pool based on user choices
    $charPool = $lowerCase + $upperCase
    if ($IncludeNumbers) { $charPool += $numbers }
    if ($IncludeSpecialChars) { $charPool += $specialChars }
    
    # Convert string to a character array for Get-Random
    $charArray = $charPool.ToCharArray()
    
    # Generate the random string
    $randomString = -join (Get-Random -Count $Length -InputObject $charArray)
    
    return $randomString
}

# =============================================================================
#  INTERACTIVE WORKFLOW
# =============================================================================
Function Start-KeyArchitectWorkflow {
    Clear-Host
    Write-Host "--- 🚀 My-Dev-Playbook: The .env Key Architect ---" -ForegroundColor Cyan
    
    # --- Phase 1: Get total number of keys needed ---
    do {
        $keyCountInput = Read-Host "`nHow many secret keys do you need to generate?"
        if ($keyCountInput -match '^\d+$' -and [int]$keyCountInput -gt 0) {
            $keyCount = [int]$keyCountInput
            break
        }
        Write-Host "Please enter a valid positive number." -ForegroundColor Yellow
    } while ($true)

    $generatedKeys = [System.Collections.Generic.List[string]]::new()

    # --- Phase 2: Loop for each key ---
    for ($i = 1; $i -le $keyCount; $i++) {
        Write-Host "`n--- Generating Key $i of $keyCount ---" -ForegroundColor Green
        
        # Get variable name
        do {
            $variableName = Read-Host "Enter the variable name (e.g., 'DB_PASSWORD', press Enter to skip)"
        } while ([string]::IsNullOrWhiteSpace($variableName))

        # Get complexity configuration
        Write-Host "Choose a complexity level:"
        Write-Host "[1] Easy (12 characters, letters & numbers)"
        Write-Host "[2] Strong (24 characters, letters, numbers & special chars)"
        Write-Host "[3] Insane (48 characters, letters, numbers & special chars)"
        Write-Host "[4] Custom"
        
        $length = 0; $useNumbers = $false; $useSpecial = $false
        do {
            $choice = Read-Host "Enter your choice (1-4)"
            $validChoice = $true
            switch ($choice) {
                '1' { $length = 12; $useNumbers = $true; $useSpecial = $false }
                '2' { $length = 24; $useNumbers = $true; $useSpecial = $true }
                '3' { $length = 48; $useNumbers = $true; $useSpecial = $true }
                '4' {
                    do {
                        $customLength = Read-Host "Enter custom length (e.g., 32)"
                    } while ($customLength -notmatch '^\d+$' -or [int]$customLength -le 0)
                    $length = [int]$customLength
                    $useNumbers = (Read-Host "Include numbers? (Y/n)").ToLower() -ne 'n'
                    $useSpecial = (Read-Host "Include special characters? (Y/n)").ToLower() -ne 'n'
                }
                default {
                    Write-Host "Invalid choice. Please select 1, 2, 3, or 4." -ForegroundColor Red
                    $validChoice = $false
                }
            }
        } while (-not $validChoice)

        # Generate and store the key
        $randomKey = Get-RandomString -Length $length -IncludeNumbers $useNumbers -IncludeSpecialChars $useSpecial
        $formattedKey = "$($variableName.ToUpper())`=$randomKey"
        $generatedKeys.Add($formattedKey)
        
        Write-Host "✅ Generated:" -ForegroundColor Cyan
        Write-Host $formattedKey
    }

    # --- Phase 3: Display results and offer to save ---
    if ($generatedKeys.Count -gt 0) {
        Write-Host "`n`n--- ✅ All Keys Generated ---" -ForegroundColor Green
        $generatedKeys | ForEach-Object { Write-Host $_ }

        $saveChoice = Read-Host "`nDo you want to save/append these keys to a file? (Y/n)"
        if ($saveChoice.ToLower() -ne 'n') {
            $fileName = Read-Host "Enter the filename (press Enter to default to '.env')"
            if ([string]::IsNullOrWhiteSpace($fileName)) { $fileName = ".env" }

            try {
                # Safely APPEND to the file. Add a newline first for clean formatting.
                Add-Content -Path $fileName -Value ("`n" + ($generatedKeys -join "`n")) -Encoding UTF8
                Write-Host "Successfully appended $($generatedKeys.Count) keys to '$fileName'." -ForegroundColor Green
            } catch {
                Write-Host "❌ ERROR: Could not write to file '$fileName'. Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "`nNo keys were generated." -ForegroundColor Yellow
    }
}

# =============================================================================
#  SCRIPT EXECUTION
# =============================================================================
Start-KeyArchitectWorkflow

Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)