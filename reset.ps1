Set-Content -Path "progress.md" -Value "# break_it progress`r`n`r`n## Seen TODOs`r`n`r`n## History`r`n"
if (Test-Path "task-done.txt") { Remove-Item "task-done.txt" }
Get-ChildItem -Filter "SUMMARY*.md" -ErrorAction SilentlyContinue | Remove-Item
Write-Output "Reset break_it. Run .\brief.ps1 (normal) or .\brief.ps1 -Mode sabotage"
