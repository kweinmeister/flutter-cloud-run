# Full-Stack Dart on Cloud Run

A full-stack application demonstrating a unified Dart architecture with a Flutter Web frontend and a Shelf backend, deployed to Google Cloud Run.

## Architecture

The project uses a monorepo structure, enabling code sharing between client and server via a `shared` package.

- **Frontend**: Flutter Web application.
- **Backend**: Dart server using `shelf` and `shelf_router`, deployed as a container.
- **Shared**: Common data models and validation logic used by both ends to ensure type safety.
- **Database**: Google Cloud Firestore.

## Prerequisites

- Dart SDK 3.10+

- Flutter SDK 3.10+
- Docker (for deployment)
- Google Cloud CLI (`gcloud`)

## Local Development

1. **Initialize Workspace**
    Fetch dependencies for all packages in the workspace.

    ```bash
    dart pub get
    ```

2. **Generate Code**
    Run `build_runner` for JSON serialization across packages.

    ```bash
    dart run tool/exec.dart "dart run build_runner build --delete-conflicting-outputs"
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

   ### Option 1: OS-Only Runtime (Recommended)

    **Why use this?** This method uploads locally-compiled binaries directly to a minimal Ubuntu runtime, offering faster and leaner deployments.

    **Prerequisite:**
    One-time setup to grant the Cloud Run Service Agent permission to access uploaded source artifacts.

    ```bash
    # Get Project ID and Number
    PROJECT_ID=$(gcloud config get-value project)
    PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

    # Grant Storage Object Viewer permission
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member=serviceAccount:service-${PROJECT_NUMBER}@serverless-robot-prod.iam.gserviceaccount.com \
      --role=roles/storage.objectViewer \
      --condition=None
    ```

    **Deploy:**
    Run the helper script from the **root** of the repository:

    ```bash
    ./tool/deploy.sh
    ```

   ### Option 2: Container Deployment (Dockerfile)

    **Why use this?** This method builds the container in a reproducible "clean room" environment on Cloud Build, offering full control over the runtime.

    > [!IMPORTANT]
    > You must run this command from the **root** of the repository (where the `Dockerfile` and `pubspec.yaml` are located) so the build context includes the entire workspace.

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
