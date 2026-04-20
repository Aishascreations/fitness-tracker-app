# Fitness Tracker App — Flutter

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=for-the-badge)

> A cross-platform mobile application built with Flutter for health and activity monitoring — runs on both Android and iOS from a single codebase.

---

## Overview

Staying on top of your fitness goals requires consistent tracking. This app provides users with an intuitive interface to monitor their daily health and activity data. Built with **Flutter and Dart**, it delivers a smooth, native-like experience on both Android and iOS platforms.

---

##  Features

- **Activity Monitoring** — Track daily physical activity and movement
- **Health Dashboard** — View health stats in a clean, visual interface
- **Progress Tracking** — Monitor fitness progress over time
- **Cross-Platform** — Works seamlessly on both Android and iOS
-  **Fast & Responsive** — Smooth UI built with Flutter widgets

---

##  Tech Stack

| Technology | Purpose |
|-----------|---------|
| **Flutter** | Cross-platform UI framework |
| **Dart** | Programming language |
| **Firebase** | Backend & data storage |

---

## Project Structure

```
fitness_tracker/
│
├── lib/
│   ├── main.dart           # App entry point
│   ├── screens/            # UI screens
│   ├── widgets/            # Reusable components
│   └── models/             # Data models
│
├── android/                # Android configuration
├── ios/                    # iOS configuration
├── pubspec.yaml            # Dependencies
└── README.md               # Project documentation
```

---

## How to Run

### Prerequisites
- Flutter SDK installed → [flutter.dev](https://flutter.dev/docs/get-started/install)
- Android Studio or VS Code
- A connected device or emulator

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/Aishascreations/fitness-tracker-app.git
cd fitness-tracker-app

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

---

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: latest
  firebase_auth: latest
  cloud_firestore: latest
```

---

##  Future Improvements

- [ ] Add step counter using device sensors
- [ ] Integrate calorie tracking with food database API
- [ ] Add workout plans and exercise library
- [ ] Implement data visualization charts
- [ ] Add social features to share progress

---

## Author

**Aishat Onakoya**
- 📧 [onakoyaaishat5@gmail.com](mailto:onakoyaaishat5@gmail.com)
- 💼 [LinkedIn](https://www.linkedin.com/in/aishat-onakoya-233627272/)
- 🐙 [GitHub](https://github.com/Aishascreations)

---

⭐ *If you found this project useful, consider giving it a star!*
