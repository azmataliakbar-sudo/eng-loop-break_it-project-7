# break_it

Project 7 from the Loop Engineering crash course.

## Run

```powershell
.\brief.ps1
.\brief.ps1 -Mode sabotage
```

## What it does

- Measures one beat (estimated tokens, cadence, monthly cost).
- Normal mode scans `src` for TODOs.
- Sabotage mode points at a missing directory and fails loudly.
- Writes `NEEDS HUMAN` into `progress.md` on failure.
