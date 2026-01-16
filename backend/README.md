# Backend: Dart Shelf Server

This directory contains the server-side code for the To-Do application, built with [Shelf](https://pub.dev/packages/shelf).

## Overview

The backend acts as a trusted intermediary between the [frontend](../frontend) and Google Cloud services. It serves two main purposes:

1. **API**: REST endpoints for managing Todos, with validation shared from the `shared` package.
2. **Static Serving**: Hosts the compiled Flutter Web assets for production.

## Getting Started

### Prerequisites

- Dart SDK installed.
- Dependencies installed: `dart pub get` (or via `melos bootstrap`).

### Running Locally

To start the server:

```bash
dart run bin/server.dart
```

The server listens on port `8080` by default.

### Environment Variables

| Variable | Description |
| :--- | :--- |
| `PORT` | Port to listen on (default: 8080). |
| `ALLOWED_ORIGIN` | Allowed origin for CORS headers (e.g., `http://localhost:8080`). Default accommodates typical local dev. |
| `GOOGLE_CLOUD_PROJECT` | Google Cloud Project ID for Firestore access. Auto-detected in Cloud Run. |

### API Endpoints

- `GET /api/v1/todos`: List all todos.
- `POST /api/v1/todos`: Create a new todo.
- `PATCH /api/v1/todos/<id>`: Update a todo.
- `DELETE /api/v1/todos/<id>`: Delete a todo.
