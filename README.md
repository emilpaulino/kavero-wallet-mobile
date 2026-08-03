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

### Accounts

* View list of financial accounts
* Create and edit accounts
* Account details screen with date-grouped transactions and quick edit button

### Transactions

* View movements list grouped by date with timestamps
* Filter transactions by type, account, and date period
* Real-time search by description or category
* Create income transactions with live preview card
* Create expense transactions with live preview card
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
* Glassmorphism UI (blur headers and bottom navigation bar)
* Fluid page transitions and micro-animated bottom navigation bar

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
