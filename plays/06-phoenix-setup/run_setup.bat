@echo off
powershell -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'powershell' -ArgumentList '-ExecutionPolicy Bypass -File ""%~dp0phoenix_setup.ps1""' -Verb RunAs"