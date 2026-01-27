# Backend: Dart Shelf Server

This directory contains the server-side code for the To-Do application, built with [Shelf](https://pub.dev/packages/shelf).

## Overview

The backend acts as a trusted intermediary between the [frontend](../frontend) and Google Cloud services. It serves two main purposes:

1. **API**: REST endpoints for managing Todos, with validation shared from the `shared` package.
2. **Static Serving**: Hosts the compiled Flutter Web assets for production.

## Getting Started

### Prerequisites

- Dart SDK 3.10+ installed.

- Dependencies installed: `dart pub get` (via root workspace).

### Running Locally

To start the server:

```bash
dart run bin/server.dart
```

The server listens on port `8080` by default.

### Environment Variables

| Variable | Description | Default |
| :--- | :--- | :--- |
| `PORT` | Port to listen on. | `8080` |
| `ALLOWED_ORIGIN` | Allowed origin for CORS headers. | `*` (or reflecting `localhost` in dev) |
| `GOOGLE_CLOUD_PROJECT` | Google Cloud Project ID for Firestore access. | Auto-detected on Cloud Run (optional). Required for local dev. |

### API Endpoints

- `GET /api/todos`: List all todos.
- `POST /api/todos`: Create a new todo.
- `PATCH /api/todos/<id>`: Update a todo.
- `DELETE /api/todos/<id>`: Delete a todo.
