# ------------------------------------------------------------------------------
# Stage 1: Workspace Builder (Resolves Dependencies)
# ------------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS workspace-builder
WORKDIR /app

# Copy root workspace definition
COPY pubspec.yaml pubspec.lock ./

# Copy member pubspecs to allow `pub get` to verify workspace structure
COPY backend/pubspec.yaml backend/
COPY frontend/pubspec.yaml frontend/
COPY shared/pubspec.yaml shared/

# Install dependencies for the entire workspace
RUN flutter pub get

# ------------------------------------------------------------------------------
# Stage 2: Build Flutter Web (Frontend)
# ------------------------------------------------------------------------------
FROM workspace-builder AS frontend-builder

# Copy source code
COPY frontend/ frontend/
COPY shared/ shared/

WORKDIR /app/frontend
RUN flutter build web --wasm

# ------------------------------------------------------------------------------
# Stage 3: Build Dart Backend (Server)
# ------------------------------------------------------------------------------
FROM workspace-builder AS backend-builder

# Copy source code
COPY backend/ backend/
COPY shared/ shared/

WORKDIR /app/backend
RUN dart compile exe bin/server.dart -o bin/server

# ------------------------------------------------------------------------------
# Stage 4: Final Production Image
# ------------------------------------------------------------------------------
FROM gcr.io/distroless/cc-debian13

WORKDIR /app

# Copy the compiled server
COPY --from=backend-builder --chown=nonroot:nonroot /app/backend/bin/server /app/server

# Copy the Flutter Web assets
COPY --from=frontend-builder --chown=nonroot:nonroot /app/frontend/build/web /app/public

# Environment variables
ENV PORT=8080

# Start server as non-root user
USER nonroot
CMD ["/app/server"]
