@echo off
:: ============================================================================
:: SYNOPSIS:
:: A utility to find and merge all files with a specific extension from a
:: directory and its subdirectories into a single output file.
::
:: DESCRIPTION:
:: This Windows Batch script, part of the My-Dev-Playbook collection,
:: recursively searches the current directory for all files matching a filter
:: (e.g., "*.ts"). It then concatenates them into one file, prepending each
:: with a comment header indicating its original relative path.
::
:: NOTES:
:: Author: Sheikh Mahmudul Hasan Shium
:: License: MIT
:: ============================================================================
setlocal

:: --- Configuration ---
set "outputFile=merged.txt"
set "fileFilter=*.ts"
:: --- End of Configuration ---

echo Starting the File Merger Play...
echo Searching for %fileFilter% files to merge into %outputFile%...

:: Create an empty output file to start fresh, overwriting any previous version.
type nul > %outputFile%

:: Recursively loop through the current directory (.) and all subdirectories
:: to find files matching the filter.
for /r . %%F in (%fileFilter%) do (
    
    :: Use a subroutine to correctly get the relative path inside the loop
    call :GetRelativePath "%%F"
    
    :: Write the header comment to the output file
    echo // Source: !relativePath! >> %outputFile%
    
    :: Append the ENTIRE, UNCHANGED content of the file.
    :: 'type' is a literal command and does not skip any lines or comments.
    type "%%F" >> %outputFile%
    
    :: Add a blank line for better separation between files in the bundle
    echo. >> %outputFile%
)

echo.
echo Success! Play complete. Merged content has been saved to %outputFile%.
goto :eof

:: Subroutine to calculate the relative path
:GetRelativePath
set "fullPath=%~1"
setlocal enabledelayedexpansion
set "relativePath=!fullPath:%CD%\=!"
endlocal & set "relativePath=%relativePath%"
goto :eof