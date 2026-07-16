# Margin Backend Data

Static data files for Margin Score enrichment via Cloud Run backend.

## Directory Structure

```
backend-data/
├── static/
│   └── margin-context.json       # Main contextual data file
├── api/
│   └── schemas/
│       └── margin-context-schema.json  # Response schema
└── README.md                     # This file
```

## API Endpoint

**GET** `/api/margin/context`

Returns comprehensive contextual data for Margin Score calculation.

## Response Structure

```json
{
  "day_factors": {},
  "seasonal_factors": {},
  "holidays_2024": [],
  "industry_benchmarks": {},
  "timezone_factors": {},
  "company_size_factors": {},
  "communication_overload_thresholds": {},
  "energy_patterns": {},
  "sleep_impact_factors": {},
  "stress_indicators": {},
  "work_life_balance_signals": {}
}
```

## Data Categories

### Day Factors
Daily adjustments for Margin Score based on day of week.

### Seasonal Factors
Quarterly adjustments (Q4 crunch, spring momentum, etc.)

### Holidays
US Federal holidays with buffer days and capacity adjustments.

### Industry Benchmarks
Role-specific meeting load, focus time, and communication metrics.

### Timezone Factors
Penalties for working across multiple timezones.

### Company Size Factors
Adjustments based on organization size and complexity.

### Energy Patterns
Chronotype-based peak and trough hours.

### Sleep Impact Factors
Sleep duration adjustments for performance impact.

### Stress Indicators
Meeting pattern analysis (back-to-back, context switching, breaks).

### Work-Life Balance Signals
After-hours communication penalties.

## Usage in Flutter

```dart
final response = await http.get('$baseUrl/api/margin/context');
final context = MarginContext.fromJson(jsonDecode(response.body));

// Apply factors
final dayFactor = context.dayFactors[currentDay].adjustment;
final enrichedScore = baseScore + dayFactor;
```

## Updates

- **Holidays**: Update `holidays_2025` when year-end approaches
- **Benchmarks**: Refresh industry data quarterly from research
- **Factors**: Adjust based on user feedback and research

## Cloud Run Deployment

These files are served directly by Cloud Run static file serving or embedded in the FastAPI/Express backend.
