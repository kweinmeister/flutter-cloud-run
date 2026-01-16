# Full-Stack Dart on Cloud Run

A full-stack application demonstrating a unified Dart architecture with a Flutter Web frontend and a Shelf backend, deployed to Google Cloud Run.

## Architecture

The project uses a monorepo structure, enabling code sharing between client and server via a `shared` package.

- **Frontend**: Flutter Web application.
- **Backend**: Dart server using `shelf` and `shelf_router`, deployed as a container.
- **Shared**: Common data models and validation logic used by both ends to ensure type safety.
- **Database**: Google Cloud Firestore.

## Prerequisites

- Dart SDK 3.0+
- Flutter SDK 3.10+
- Docker (for deployment)
- Google Cloud CLI (`gcloud`)

## Local Development

1. **Initialize Workspace**
    Use [Melos](https://melos.invertase.dev/) to link packages and install dependencies.

    ```bash
    dart run melos bootstrap
    ```

2. **Generate Code**
    Run `build_runner` for JSON serialization across packages.

    ```bash
    dart run melos run generate
    ```

3. **Run Backend**
    Starts the API server on `localhost:8080`.

    ```bash
    cd backend
    dart run bin/server.dart
    ```

    *Note: The local server automatically allows CORS for `localhost` origins.*

4. **Run Frontend**
    Launches the Flutter Web app in Chrome.

    ```bash
    cd frontend
    flutter run -d chrome
    ```

## Deployment

### Configuration

Environment variables control the server behavior.

| Variable | Description | Default |
| :--- | :--- | :--- |
| `PORT` | API server port. | `8080` |
| `GOOGLE_CLOUD_PROJECT` | GCP Project ID. Required for Firestore access. | Auto-detected on Cloud Run (optional). Required for local dev. |
| `ALLOWED_ORIGIN` | Allowed CORS origin. | `*` (if unset/non-local) |

### Cloud Run

Deploy the service using the standard `gcloud` workflow.

1. **Build and Deploy**
    Substitutes local environment variables and allows unauthenticated access for demonstration.

    ```bash
    export REGION=us-central1

    gcloud run deploy todo-app \
      --source . \
      --region $REGION \
      --labels dev-tutorial=flutter-cloud-run \
      --allow-unauthenticated
    ```

2. **Restrict CORS (Recommended)**
    For production, restrict API access to the specific service URL.

    ```bash
    SERVICE_URL=$(gcloud run services describe todo-app --region $REGION --format 'value(status.url)')

    gcloud run services update todo-app \
      --region $REGION \
      --update-env-vars ALLOWED_ORIGIN=$SERVICE_URL
    ```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[Apache 2.0](LICENSE)
