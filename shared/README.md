# Shared: Common Models and Logic

This package contains data models and business logic shared between the [frontend](../frontend) and [backend](../backend).

## Overview

The `shared` package ensures consistency across the entire stack. By defining models and validation here, we guarantee that the client and server always agree on the data structure and business rules.

### Key Components

- **`TodoItem`**: The core data model, utilizing `json_serializable` for automated JSON conversion.
- **`TodoItemValidation`**: An extension on `TodoItem` that provides validation logic (e.g., character limits) used by both the frontend UI and the backend API.

## Code Generation

This package uses `json_serializable` and `build_runner` to generate boilerplate code for JSON handling.

To update the generated files after making changes to models:

```bash
# In the shared directory
dart run build_runner build --delete-conflicting-outputs
```

Or, using the workspace-wide [Melos](../) command:

```bash
melos run generate
```

## Integration

Both the `frontend` and `backend` packages depend on this package. Due to the [Melos](../) workspace setup, they link to the local version of this package automatically.
