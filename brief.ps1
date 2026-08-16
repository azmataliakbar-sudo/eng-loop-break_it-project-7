param(
    [ValidateSet("normal", "sabotage")]
    [string]$Mode = "normal"
)

$progressFile = "progress.md"
$doneFile = "task-done.txt"
$srcDir = if ($Mode -eq "sabotage") { "does-not-exist" } else { "src" }

$startedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Token estimate per beat (rough, fixed for teaching).
$tokensIn = 350
$tokensOut = 120
$tokensPerBeat = $tokensIn + $tokensOut
$cadencePerDay = 1
$monthlyCost = $tokensPerBeat * $cadencePerDay * 30

$content = Get-Content $progressFile -Raw

# Read seen TODOs.
$seen = @()
if ($content -match '(?ms)## Seen TODOs\s*\n(?<block>.*?)\n## History') {
    $block = $Matches['block']
    if ($block -and $block.Trim().Length -gt 0) {
        $seen = $block.Trim() -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    }
}
$historyBeforeCount = @($seen).Count

# Find TODOs (will fail if srcDir missing).
$allTODOs = @()
$failed = $false
$failureReason = ""
if (-not (Test-Path $srcDir)) {
    $failed = $true
    $failureReason = "source directory '$srcDir' does not exist"
} else {
    $files = Get-ChildItem -Path $srcDir -Recurse -Filter "*.js" -ErrorAction SilentlyContinue
    if ($null -eq $files -or @($files).Count -eq 0) {
        $failed = $true
        $failureReason = "no .js files found under '$srcDir'"
    } else {
        foreach ($f in $files) {
            $lineNum = 0
            foreach ($line in (Get-Content $f.FullName)) {
                $lineNum++
                if ($line -match 'TODO') {
                    $allTODOs += "$($f.FullName):${lineNum}: $($line.Trim())"
                }
            }
        }
    }
}

$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

if ($failed) {
    $action = "FAILED: $failureReason"
    $historyLine = "- $now : $action : NEEDS HUMAN"
} else {
    $newTODOs = @($allTODOs | Where-Object { $seen -notcontains $_ })
    $newCount = @($newTODOs).Count
    if ($newCount -gt 0) {
        $action = "recorded $newCount new TODO(s) to the spine"
    } else {
        $action = "recorded nothing new (the spine already knew every TODO)"
    }
    $historyLine = "- $now : history-before=$historyBeforeCount : new-found=$newCount : $action"
}

# Append to history.
$oldHistory = @()
if ($content -match '(?ms)## History\s*\n(?<h>.*)') {
    $h = $Matches['h']
    if ($h) {
        $oldHistory = $h.Trim() -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    }
}
$newHistory = @($oldHistory) + @($historyLine)

# Update seen TODOs (unchanged on failure).
$updatedSeen = @($seen)
if (-not $failed) {
    $updatedSeen = @($seen) + @($allTODOs) | Where-Object { $_ -ne '' } | Sort-Object -Unique
}

$newContent = @"
# break_it progress

## Seen TODOs

$($updatedSeen -join "`r`n")

## History

$($newHistory -join "`r`n")
"@
Set-Content -Path $progressFile -Value $newContent

# Append DONE-N line.
$doneCount = 0
if (Test-Path $doneFile) {
    $doneCount = (Get-Content $doneFile | Where-Object { $_ -match '^DONE-' }).Count
}
$nextDone = $doneCount + 1
if ($failed) {
    "DONE-$nextDone at $now : FAIL" | Add-Content -Path $doneFile
} else {
    "DONE-$nextDone at $now : SUCCESS" | Add-Content -Path $doneFile
}

# SUMMARY file.
$summaryCount = (Get-ChildItem -Filter "SUMMARY*.md" -ErrorAction SilentlyContinue).Count
$nextSummary = $summaryCount + 1
$summaryFile = "SUMMARY$nextSummary.md"

$summaryLines = @(
    "Run: $nextSummary"
    "Started: $startedAt"
    "Finished: $now"
    "Mode: $Mode"
    "Result: $(if ($failed) { 'FAIL' } else { 'SUCCESS' })"
    "Tokens this beat (est): $tokensPerBeat (in $tokensIn / out $tokensOut)"
    "Cadence: $cadencePerDay per day"
    "Estimated monthly tokens: $monthlyCost"
    "Spine line:"
    "  $historyLine"
)
Set-Content -Path $summaryFile -Value $summaryLines

Write-Output "===== break_it beat ====="
Write-Output "Run: $nextSummary"
Write-Output "Mode: $Mode"
Write-Output $historyLine
Write-Output "Tokens this beat (est): $tokensPerBeat"
Write-Output "Estimated monthly tokens: $monthlyCost"
Write-Output "Wrote task-done.txt -> DONE-$nextDone"
Write-Output "Wrote $summaryFile"
Write-Output "========================="
