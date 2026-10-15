# DoIt ⚡

**"Snap it. Do it. Done."**

DoIt is an AI-powered, Android-first Flutter application that automatically detects new screenshots, uses Google Gemini Vision AI to classify whether the screenshot contains a task, reminder, deadline, or event, and automatically creates structured to-do items with zero user effort.

---

## 🌟 Key Features

- **Automated Screenshot Detection**: Real-time foreground gallery listener (`PhotoManager`) + low-priority background foreground service + WorkManager boot fallback.
- **Gemini Vision AI**: Direct vision classification via Google Gemini API (`gemini-1.5-flash`), resolving relative dates and confidence scores.
- **Needs Review Mode**: Low-confidence detections (< 0.75) are presented as interactive review cards asking "Is this a task?".
- **Drift Local Database**: Reactive SQLite persistence for tasks and processed screenshot tracking.
- **Smart Reminders**: Scheduled notifications (30 mins before & at due time) with action buttons (`Done`, `Snooze 10m`).
- **Motivating UI/UX**: Custom Material 3 design system with Plus Jakarta Sans typography, energetic gradient hero card (`#FF6B35` to `#FFC857`), animated circular progress ring, Roman Urdu & English motivational lines, and confetti celebratory animations.

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/       # Strings, motivational lines, system prompts
│   ├── router/          # GoRouter configuration
│   ├── theme/           # Design system tokens & ThemeData
│   └── utils/           # Safe JSON parser, date utilities
├── data/
│   ├── local/           # Drift SQLite database & table definitions
│   ├── network/         # Dio HTTP client for Gemini API
│   └── repositories/    # Task & Screenshot repository
├── domain/
│   ├── models/          # Task & AI result domain models
│   └── usecases/        # Process screenshot usecase pipeline
├── features/
│   ├── home/            # Home screen, hero card, task list, filter chips
│   ├── onboarding/      # 3-page onboarding flow with permissions
│   ├── settings/        # Auto-detect, reminders, theme & data settings
│   └── task_detail/     # Modal bottom sheet for creating/editing tasks
├── providers/           # Riverpod state management & settings state
└── services/            # OCR, AI, Notifications & Background Watcher
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.5.0`
- Android Studio / VS Code with Dart & Flutter plugins
- Android Device or Emulator running Android 8.0+ (API 26+)

### Installation & Execution

1. Clone the repository and navigate to the root directory:
   ```bash
   cd doit
   ```

2. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```

3. Configure your Gemini API key in `env.json` (or paste it in the app's Settings screen):
   ```json
   {
     "GEMINI_API_KEY": "your_gemini_api_key_here"
   }
   ```

4. Run the app with `--dart-define-from-file=env.json`:
   ```bash
   flutter run --dart-define-from-file=env.json
   ```

---

## 🧪 Testing

Run unit tests for the AI JSON parser and relative date resolution:
```bash
flutter test
```

---

## 🔒 Security & Privacy

- API keys are read securely from `flutter_secure_storage` or environment definitions.
- Screenshot content is never logged or stored on external servers.
- API keys are never hardcoded or exposed in logs.
