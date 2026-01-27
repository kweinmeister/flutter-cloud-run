# Frontend: Flutter Web App

This directory contains the Flutter Web frontend for the To-Do application.

## Overview

The frontend is a pure Flutter Web application that consumes the API provided by the [backend](../backend). It shares data models and validation logic with the backend via the `shared` package.

### Key Components

- **`lib/main.dart`**: The entry point and main application widget.
- **`TodoTile`**: A reusable widget for rendering individual todo items, demonstrating UI composition.

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
- Dependencies installed: `flutter pub get` (via root workspace).

### Running Locally

To run the frontend in Chrome:

```bash
flutter run -d chrome
```

By default, the app is configured to connect to `http://localhost:8080`. Ensure the [backend](../backend) is running on this port.

### Building for Production

To build the web assets (HTML, JS, Wasm) for deployment:

```bash
flutter build web --wasm
```

The compiled assets will be in `build/web`, which are then served by the backend in the production container.
