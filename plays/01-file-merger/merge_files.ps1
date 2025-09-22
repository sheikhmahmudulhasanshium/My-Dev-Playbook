<#
.SYNOPSIS
  A utility to find and merge all files with a specific extension from a directory and its subdirectories into a single output file.

.DESCRIPTION
  This PowerShell script, part of the My-Dev-Playbook collection, recursively searches
  the current directory for all files matching a filter (e.g., "*.ts"). It then concatenates
  their content into one file, prepending each with a comment header indicating its
  original relative path.

.NOTES
  Author: Sheikh Mahmudul Hasan Shium
  License: MIT
#>

# --- Configuration ---
$outputFile = "merged.txt"
$fileFilter = "*.ts"
# --- End of Configuration ---

# Get the full path of the current directory to calculate relative paths
$basePath = (Get-Location).Path

Write-Host "Starting the File Merger Play..."
Write-Host "Searching for '$fileFilter' files to merge into '$outputFile'."

# Find all files, then for each one, create a block of text
# containing the header and the file's content.
$combinedContent = Get-ChildItem -Path . -Filter $fileFilter -Recurse | ForEach-Object {
    
    # Calculate the relative path from the base path and format it for the comment
    $relativePath = $_.FullName.Substring($basePath.Length + 1).Replace('\', '/')
    $header = "// Source: $relativePath"

    # Get the raw content of the file (preserves all comments and formatting)
    $content = Get-Content -Path $_.FullName -Raw

    # Output the header, a newline, the content, and another newline for separation
    "$header`n$content`n"
}

# Write all the combined blocks to the specified output file using UTF-8 encoding
Set-Content -Path $outputFile -Value $combinedContent -Encoding UTF8

Write-Host "Success! Play complete. All files have been merged into '$outputFile'." -ForegroundColor Green