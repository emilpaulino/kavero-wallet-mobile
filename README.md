# Kavero Wallet Mobile

Kavero Wallet Mobile is the mobile application of the Kavero Wallet ecosystem, built with Flutter.

It allows users to view financial information and register income and expense transactions through a modern and intuitive interface.

## Related Repository

This project consumes the Kavero Wallet API.

Backend:

* https://github.com/emilpaulino/kavero-wallet-api

The API is responsible for authentication, account management, category management, and transaction processing.

## Technologies

* Flutter
* Dart
* HTTP
* Flutter Secure Storage
* Material Design

## Current Features

### Authentication

* JWT-based login
* Secure token storage
* Biometric authentication (Face ID / Fingerprint)
* Device passcode/PIN fallback

### Home

* Financial overview
* User summary information

### Transactions

* Create income transactions
* Create expense transactions
* Account selection
* Category selection

### Profile

* View user profile
* Edit profile information
* Upload and update profile picture
* Enable/disable biometric authentication

### User Interface

* Light mode
* Dark mode
* Responsive design

## Architecture

```text
lib
├── core
│   ├── constants
│   ├── theme
│   └── storage_service.dart
│
├── features
│   ├── auth
│   ├── accounts
│   ├── categories
│   ├── home
│   └── transactions
│
└── main.dart
```

## Configuration

### API Configuration

The API base URL is configured in:

```text
lib/core/constants/api_constants.dart
```

Example:

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8080';
}
```

### Install Dependencies

```bash
flutter pub get
```

### Run the Application

```bash
flutter run
```

## Project Status

The project is currently under development.

## Author

Emil Paulino
