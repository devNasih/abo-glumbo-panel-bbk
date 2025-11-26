# Abo Glumbo Panel (Brandbik)

A comprehensive Flutter-based admin and technician panel designed for the Abo Glumbo service platform. This application facilitates the management of bookings, warranties, user accounts, and real-time communication, serving as a central hub for service operations.

## 🚀 Features

- **Dashboard & Analytics**: Real-time overview of system activities, active bookings, and service metrics.
- **Booking Management**:
  - View and manage normal and warranty bookings.
  - Assign technicians to bookings.
  - Track booking status (Pending, In Progress, Completed, Cancelled).
- **Warranty System**:
  - Handle warranty claims and tracking.
  - Monitor warranty expiration and status changes.
  - Technician assignment for warranty repairs.
- **User Management**:
  - Manage customer and technician profiles.
  - Verification and approval workflows for technicians.
- **Real-time Communication**:
  - Integrated chat system for support and coordination.
  - Push notifications for booking updates, status changes, and announcements.
- **Localization**: Full support for **English** and **Arabic** (RTL support).
- **Geolocation**: Integrated maps for tracking service locations.

## 🛠 Tech Stack

### Frontend (Mobile/Web)

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [Flutter Bloc](https://pub.dev/packages/flutter_bloc)
- **Local Storage**: [Hive](https://pub.dev/packages/hive)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **Maps & Location**: `geolocator`, `geocoding`

### Backend (Serverless)

- **Platform**: [Firebase](https://firebase.google.com/)
- **Database**: Cloud Firestore & Realtime Database
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage
- **Server-side Logic**: Cloud Functions for Firebase (Node.js 22)

## 📋 Prerequisites

Ensure you have the following installed on your development machine:

- **Flutter SDK**: Version `^3.8.1`
- **Dart SDK**: Compatible with Flutter version
- **Node.js**: Version `22` (for Cloud Functions)
- **Firebase CLI**: For deploying functions and managing backend resources
- **CocoaPods**: For iOS dependencies (Mac only)

## ⚙️ Installation

1.  **Clone the repository:**

    ```bash
    git clone <repository-url>
    cd abo-glumbo-panel-bbk
    ```

2.  **Install Flutter dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Install Cloud Functions dependencies:**
    ```bash
    cd functions
    npm install
    cd ..
    ```

## 📱 Running the Application

To run the app on a connected device or emulator:

```bash
flutter run
```

### Build for Production

- **Android APK:**

  ```bash
  flutter build apk --release
  ```

- **Android App Bundle:**

  ```bash
  flutter build appbundle --release
  ```

- **iOS (Mac only):**
  ```bash
  flutter build ios --release
  ```

## ☁️ Cloud Functions

The project includes a suite of Cloud Functions located in the `functions` directory to handle backend logic such as notifications, booking state changes, and scheduled tasks.

**Deploy Functions:**

```bash
firebase deploy --only functions
```

**Run Locally (Emulators):**

```bash
cd functions
npm run serve
```

## 📂 Project Structure

```
abo-glumbo-panel-bbk/
├── android/            # Android native code
├── assets/             # Images, SVGs, and data assets
├── functions/          # Firebase Cloud Functions (Node.js)
├── ios/                # iOS native code
├── lib/                # Main Flutter application code
│   ├── common_widget/  # Reusable UI components
│   ├── helpers/        # Utility functions
│   ├── l10n/           # Localization files (.arb)
│   ├── models/         # Data models
│   ├── pages/          # Application screens (Home, Bookings, etc.)
│   ├── services/       # API and Backend services
│   ├── sheets/         # Bottom sheets and modals
│   ├── styles/         # App theming and styles
│   └── main.dart       # Application entry point
├── pubspec.yaml        # Flutter dependencies and configuration
└── README.md           # Project documentation
```

## 🤝 Contributing

1.  Fork the repository.
2.  Create a feature branch (`git checkout -b feature/amazing-feature`).
3.  Commit your changes (`git commit -m 'Add some amazing feature'`).
4.  Push to the branch (`git push origin feature/amazing-feature`).
5.  Open a Pull Request.
