# Margin Developer Tools

This directory contains developer utility scripts for testing Margin Score calculations.

## calculate_margin.dart

Terminal script for developers to test Margin Score calculation without running the full Flutter app.

### Usage

```bash
# Run from project root
dart tool/calculate_margin.dart

# Or make executable and run directly
chmod +x tool/calculate_margin.dart
./tool/calculate_margin.dart
```

### Features

- Interactive input for sleep, energy, and meeting load
- Loads real context data from `backend-data/static/margin-context.json`
- Calculates and displays Margin Score with capacity level
- Shows contextual factors (day of week, season, holidays)
- Continuous testing loop - calculate multiple scores in one session

### Example Session

```
============================================================
  Margin Score Calculator - Developer Tool
============================================================
  Loading context data...
  ✓ Context loaded


  Enter your values (or "q" to quit):

  😴 Sleep hours (0-12): 8
  ⚡ Energy level (1-10): 7
  📅 Meeting load hours (0-16): 4

────────────────────────────────────────────────────────────
  RESULTS
────────────────────────────────────────────────────────────
  📊 Margin Score: 56% - Moderate Capacity

  Input Factors:
    😴 Sleep: 8.0h (Optimal)
    ⚡ Energy: 7.0/10
    📅 Meetings: 4.0h

  Contextual Factors:
    📆 Day: Thursday (0.0)
    🌍 Season: Q3 (0.0)
────────────────────────────────────────────────────────────


  Calculate another score? (y/n): n
  👋 Goodbye!
```

### Input Ranges

- **Sleep hours**: 0-12 hours
- **Energy level**: 1-10 scale
- **Meeting load**: 0-16 hours

### Exit

Type `q` at any prompt to quit, or `n` when asked to calculate another score.
