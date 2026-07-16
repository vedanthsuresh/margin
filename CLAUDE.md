# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project: Margin

Margin is a proactive psychological bodyguard that intercepts demanding digital requests at their point of origin. It calculates a user's real-time emotional and mental capacity (their **Margin Score**) based on daily metrics like sleep, calendar density, and energy levels.

When a user receives a stressful request, they share it directly to the app. Margin analyzes the text and the user's current capacity to dynamically generate context-aware, boundary-setting responses.

## Development Commands

**Dependencies:**
```bash
flutter pub get              # Install dependencies
flutter pub upgrade          # Upgrade dependencies to latest versions
flutter pub outdated         # Check for outdated dependencies
```

**Running & Hot Reload:**
```bash
flutter run                  # Run on connected device/emulator (platform auto-detected)
flutter run -d chrome        # Run on Chrome (web)
flutter run -d macos         # Run on macOS
```
- Press `r` in the terminal for hot reload (preserves app state)
- Press `R` for hot restart (resets app state)
- Press `q` to quit

**Build:**
```bash
flutter build apk            # Android APK
flutter build ios            # iOS (requires macOS + Xcode)
flutter build macos          # macOS app
flutter build web            # Web app
```

**Testing:**
```bash
flutter test                 # Run all tests
flutter test test/name_test.dart  # Run specific test file
```

**Code Quality:**
```bash
flutter analyze              # Static analysis (configured in analysis_options.yaml)
flutter format .             # Format all Dart files
```

## Core Features

### 1. Capacity Dashboard (The Weather Report)
Top half of the app showing user's current bandwidth at a glance.

**Components:**
- **Margin Score**: Dynamic 0-100% score, **enriched with cloud contextual data**
- **Input Sliders**: Smooth slider widgets for self-reporting:
  - Sleep (hours/quality)
  - **Meeting Load** (calendar density) — *Auto-calculated from Google Calendar when connected, falls back to manual slider*
  - Current Energy level
- **Visual State**: Color palette shifts from greens (High Capacity) to reds/oranges (Depleted Capacity) as score changes
- **Contextual Insights**: Small text showing why score is adjusted (e.g., "↓ Monday factor", "↑ Holiday buffer")

**Margin Score Enrichment:**
Score calculation combines local inputs with cloud-provided context:
- **Base Score**: Calculated from user inputs (sleep, meetings, energy)
- **Day-of-Week Adjustment**: Monday/Friday penalties, Wednesday bonus
- **Seasonal Factors**: Q4 stress penalty, summer buffer
- **Holiday Buffer**: Automatic capacity boost around holidays
- **Industry Benchmarks**: Contextual comparison ("Your load is 20% above average")

### 2. Boundary Sandbox
Core workspace where the intervention happens.

**Components:**
- Clean text area for pasting demanding text/email
- Relationship tags (segmented control): Boss, Peer, Friend, Family
- These dictate AI tone and formality level

### 3. Four-Button Engine & Dynamic Outputs
Four static action buttons with outputs that change based on Margin Score:

| Action Button | High Capacity (>60%) | Depleted Capacity (<30%) |
|----------------|----------------------|--------------------------|
| Polite Decline | Warm decline, door open for future | Firm, closed-loop decline |
| Soft Compromise | Offers partial labor ("I can write first half") | Passive resources only ("I can send a template") |
| Reschedule | Suggests time later in week | Refuses to suggest time if week is packed |
| Accept Request | Enthusiastic, polite acceptance | **Triggers Friction Lock protocol** |

### 4. Friction Lock (Positive Friction Protocol)
When capacity drops below 30%, the Accept Request button visually locks and triggers behavioral intervention:

**Four Friction Mechanisms:**
1. **Cognitive Speedbump**: Modal interrupts - "Your capacity is at 20%. Accepting this puts you at risk of burnout. Swipe to override."
2. **Cooling-Off Timer**: Grays out send button for 15-minute cooldown period (circuit breaker)
3. **Consequence Forecast**: Shows trade-off alert - "Accepting this requires 2 hours. To keep your Margin Score stable, you will need to cancel [Event] or drop your sleep average."
4. **"Defend the Yes"**: Mandatory text box - "Your bandwidth is at 15%. Why is this an absolute priority?"
5. **Forced Conditional Yes**: Replaces "Yes" with "Yes, But..." - generates boundaries into the draft

### 5. Point of Origin Interceptor (OS Integration)
Routes requests directly from native messaging apps.

**Mobile (Share Sheet):**
- User highlights text in iMessage/WhatsApp/Slack
- Taps native "Share" button → selects Margin icon
- Triggers lightweight Flutter bottom-sheet overlay (not full app)
- Instantly displays Capacity Score + four response buttons

**Desktop/Web:**
- Browser extension or OS-level clipboard listener
- Highlight text in Slack/Teams → right-click → "Send to Margin"

### 6. Google Calendar Integration
Connects to Google Calendar natively via Flutter packages to enable intelligent scheduling and conflict avoidance.

**Capabilities:**
- **Auto-calculate Meeting Load**: Replaces manual slider with real calendar density analysis
- **Smart "Reschedule" suggestions**: Identifies actual free slots instead of guessing
- **Consequence Forecast with real events**: References actual upcoming commitments ([Event Name], [Date/Time])
- **"Week is packed" detection**: Accurately detects when upcoming week has no bandwidth
- **Conflict prevention**: Ensures suggested times don't overlap with existing commitments

**Privacy & Fallback:**
- Native OAuth via `google_sign_in` with explicit user consent
- Calendar data fetched directly from Google Calendar API via `googleapis` package
- Calendar data used locally for calculation only (not transmitted to backend)
- If user declines calendar access, app falls back to manual Meeting Load slider
- Clear privacy controls in settings to disconnect/revoke calendar access

### 7. Margin Score Calculation Architecture

**Hybrid Approach:** Local inputs + Cloud contextual enrichment

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                                      │
│                                                                          │
│  ┌──────────────┐         ┌──────────────┐         ┌──────────────┐    │
│  │ User Inputs  │         │ Google       │         │   Margin     │    │
│  │              │         │ Calendar     │         │   Score      │    │
│  │ • Sleep      │         │ Events       │         │  Engine      │    │
│  │ • Energy     │         │ Meeting Load │         │              │    │
│  │ • Manual     │─────────│              │         │              │    │
│  │   Load       │         │              │         │              │    │
│  └──────────────┘         └──────────────┘         │      │       │    │
│                                                      │      │       │    │
│                                                      │      │       │    │
│                           ┌──────────────────────────┘      │       │    │
│                           │                                 │       │    │
│                           │         GET /api/margin/context │       │    │
│                           │                                 │       │    │
│                           ▼                                 ▼       │    │
│                      ┌─────────────┐              ┌─────────────┐    │
│                      │   Cloud     │              │   Final     │    │
│                      │  Context    │─────────────│   Margin    │    │
│                      │   Data      │              │   Score     │    │
│                      └─────────────┘              └─────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      CLOUD RUN BACKEND                                    │
│                                                                          │
│  GET /api/margin/context                                                  │
│                                                                          │
│  Response: {                                                              │
│    "day_factors": { ... },           // Mon/Wed/Fri adjustments          │
│    "seasonal_factors": { ... },      // Q4/summer adjustments           │
│    "holidays": [ ... ],              // Upcoming holidays                │
│    "industry_benchmarks": { ... },   // Role-based comparisons           │
│    "timezone_factors": { ... }      // Multi-timezone penalties         │
│  }                                                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

**Calculation Formula:**
```dart
final baseScore = calculateBaseScore(sleep, energy, meetingLoad);
final dayFactor = context.dayFactors[today] ?? 0;
final seasonalFactor = context.seasonalFactors[currentQuarter] ?? 0;
final holidayFactor = context.isNearHoliday ? 5 : 0;
final industryDelta = userMeetingLoad - context.industryBenchmark[userRole];

final enrichedScore = baseScore + dayFactor + seasonalFactor + holidayFactor - industryDelta;
```

## Technical Architecture

### Frontend: Flutter
- Single codebase for mobile (iOS/Android) and web
- UI Framework: Material 3 or Cupertino for rapid component rendering
- **State Management**: Riverpod or Bloc (critical for Friction Lock dynamic state)
- **Animations**: flutter_animate package for color shifting dashboard and locked button shake animation

### Key Flutter Packages
```yaml
dependencies:
  receive_sharing_intent: ^X.X.X  # iOS Share Sheet & Android Intent integration
  home_widget: ^X.X.X              # Lock-screen/home-screen widgets
  flutter_animate: ^X.X.X           # UI animations
  riverpod: ^X.X.X                 # or bloc for state management
  googleapis: ^X.X.X               # Google Calendar API access
  google_sign_in: ^X.X.X           # OAuth for Google account
```

**Deep Linking**: Configure deep links so share intent routes directly to Boundary Sandbox screen with text field pre-populated, bypassing splash screen.

### Backend: Cloud Run
Hosting on Google Cloud Run for low-latency demo with scale-to-zero.

**API Layer:**
- FastAPI (Python) or Express (Node.js) service via Docker
- **`GET /api/margin/context`** — Returns comprehensive contextual data for Margin Score enrichment
- **`POST /api/generate-response`** — Generates AI-powered boundary responses
  - Receives: Margin Score, pasted text, relationship tag
  - Returns: Structured JSON with response options

**AI & Orchestration: Vertex AI & ADK**
- Agent Development Kit (ADK) for deterministic routing logic
- **Evaluator Node**: Ingests Margin Score; if <30% and user requested "Acceptance", bypasses standard generation
- **Generation Node**: Routes to Vertex AI (Gemini 1.5 Flash for speed) with strict system instructions
- **Structured Output**: Returns strict JSON payload with three text responses for reliable Flutter parsing

### Google Calendar Integration (Native Flutter)
**Approach:** Direct API calls from Flutter using Google's official packages

**Implementation Pattern:**
```dart
// 1. OAuth with google_sign_in
final GoogleSignInAccount? account = await googleSignIn.signIn();

// 2. Get authenticated HTTP client
final auth = await account!.authentication;
final httpClient = GoogleHttpClient(auth.accessToken ?? '');

// 3. Call Calendar API directly
final calendar = CalendarApi(httpClient);
final events = await calendar.events.list(
  'primary',
  timeMin: DateTime.now().toIso8601String(),
  timeMax: DateTime.now().add(Duration(days: 14)).toIso8601String(),
);
```

**Key Operations:**
- **Fetch events** — Get upcoming events for next 7-14 days for Meeting Load calculation
- **Find free slots** — Query availability for "Reschedule" suggestions
- **Conflict check** — Validate proposed times against existing commitments

**OAuth & Security:**
- `google_sign_in` package handles native OAuth flow
- Access token stored securely via `flutter_secure_storage` (mobile) or web storage (web)
- Token refresh handled automatically by `google_sign_in`
- Calendar data never transmitted to backend — processed entirely client-side
- User can revoke access via Google Account settings or app settings

**Fallback:** If user declines calendar connection, app uses manual Meeting Load slider

## Project Structure

- `lib/main.dart` - App entry point
- `lib/features/dashboard/` - Capacity Dashboard (Margin Score, sliders, visual state)
- `lib/features/sandbox/` - Boundary Sandbox (text input, relationship tags)
- `lib/features/response/` - Four-button engine and response generation
- `lib/features/friction/` - Friction Lock protocols and modals
- `lib/services/sharing/` - receive_sharing_intent integration
- `lib/services/calendar/` - Google Calendar integration (OAuth, CalendarApi client)
- `lib/services/margin/` - Margin Score calculation engine with cloud context enrichment
- `lib/services/api/` - Cloud Run backend communication
- `backend-data/` - Static data files for Cloud Run backend
  - `static/margin-context.json` - Comprehensive contextual data
  - `api/schemas/margin-context-schema.json` - API response schema
  - `README.md` - Backend data documentation
- `test/` - Widget and unit tests
- `android/`, `ios/` - Platform-specific native code and Share Sheet configuration

## Linting

Uses `flutter_lints` package. Configured in `analysis_options.yaml`. Add custom rule overrides there as needed.

---

## Hackathon Judging Rubric

Reference this rubric when prioritizing features and preparing the pitch. Each category is scored 1-5.

### 1. Problem Identification & Understanding
**Score:** Clearly identified a meaningful FinTech or WellTech problem; explained who experiences it, why it matters, and what causes or contributes to it.
- **5 (OUTSTANDING):** All key aspects with strong reasoning/context
- **4 (STRONG):** Most key aspects explained
- **3 (DEVELOPING):** Some aspects with limited detail
- **2 (LIMITED):** Weakly defined, missing important context
- **1 (INCOMPLETE):** Unclear, vague, or not meaningfully explained

### 2. Innovation & Creativity
**Score:** Solution is original, creative, and clearly different or significantly improved compared to existing approaches.
- **5 (OUTSTANDING):** Original, creative, significantly improved
- **4 (STRONG):** Creative with unique elements adding value
- **3 (DEVELOPING):** Some creative aspects, partly similar to existing
- **2 (LIMITED):** Mostly similar to existing approaches
- **1 (INCOMPLETE):** No clear innovation or creativity

### 3. Solution Effectiveness
**Score:** Solution directly and effectively addresses the problem; clear connection between problem, solution, and intended outcome.
- **5 (OUTSTANDING):** Direct, effective, clear connection to outcome
- **4 (STRONG):** Addresses problem well, clear outcome connection
- **3 (DEVELOPING):** Addresses problem, partially clear connection
- **2 (LIMITED):** Weak connection, impact unclear
- **1 (INCOMPLETE):** Does not address problem or connection missing

### 4. Research & User Understanding
**Score:** Demonstrated strong research, evidence, and understanding of users and their needs.
- **5 (OUTSTANDING):** Strong research and user understanding
- **4 (STRONG):** Good research and understanding of needs
- **3 (DEVELOPING):** Some research but needs more depth
- **2 (LIMITED):** Minimal research, shallow understanding
- **1 (INCOMPLETE):** No research or user understanding evident

### 5. Feasibility & Implementation
**Score:** Solution is realistic and well thought out; team clearly explained technology, resources, steps, partnerships, and limitations.
- **5 (OUTSTANDING):** Realistic, well-thought-out, clear explanation
- **4 (STRONG):** Feasible with minor gaps
- **3 (DEVELOPING):** Feasibility unclear or partially explained
- **2 (LIMITED):** Significant challenges or missing details
- **1 (INCOMPLETE):** Not feasible or no implementation plan

### 6. Impact & Future Potential
**Score:** High potential to create meaningful financial, health, wellness, accessibility, or community benefits; clear path for growth or scalability.
- **5 (OUTSTANDING):** High potential, clear growth/scalability path
- **4 (STRONG):** Good potential, reasonable scalability
- **3 (DEVELOPING):** Some potential, limited growth clarity
- **2 (LIMITED):** Low impact or unclear benefits
- **1 (INCOMPLETE):** No clear impact or future potential

### 7. Prototype, Design or Solution Demonstration
**Score:** Prototype, mockup, business model, or demonstration is clear, functional, and effectively communicates how the solution works; user-friendly.
- **5 (OUTSTANDING):** Clear, functional, user-friendly demonstration
- **4 (STRONG):** Clear, communicates solution well, minor gaps
- **3 (DEVELOPING):** Somewhat clear, lacks important details/refinement
- **2 (LIMITED):** Difficult to understand or incomplete
- **1 (INCOMPLETE):** No clear demonstration

### 8. Pitch, Teamwork & Q&A
**Score:** Presentation is exceptionally organized, engaging, and convincing; team members contribute equally and answer questions with confidence and deep understanding.
- **5 (OUTSTANDING):** Exceptional, engaging, confident Q&A
- **4 (STRONG):** Well-organized, good understanding in answers
- **3 (DEVELOPING):** Understandable, needs organization/engagement
- **2 (LIMITED):** Lacks organization, struggles with questions
- **1 (INCOMPLETE):** Disorganized, unable to answer questions
