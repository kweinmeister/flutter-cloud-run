# ------------------------------------------------------------------------------
# Stage 1: Build Flutter Web (Frontend)
# ------------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-builder

WORKDIR /app

# Copy dependency files only to cache layers
COPY frontend/pubspec.yaml frontend/pubspec.lock frontend/
COPY shared/ /app/shared/

WORKDIR /app/frontend
# Remove local lockfile (generated on Mac) to use pure Linux resolution
RUN rm -f pubspec.lock
RUN flutter pub get

# Copy source code
COPY frontend/ .

# Build for web
RUN flutter build web --wasm

# ------------------------------------------------------------------------------
# Stage 2: Build Dart Backend (Server)
# ------------------------------------------------------------------------------
FROM dart:stable AS backend-builder

WORKDIR /app

# Copy dependency files only to cache layers
COPY backend/pubspec.yaml backend/pubspec.lock backend/
COPY shared/ /app/shared/

WORKDIR /app/backend
RUN rm -f pubspec.lock
RUN dart pub get

# Copy source code
COPY backend/ .

# Build server to executable (AOT)
RUN dart compile exe bin/server.dart -o bin/server

# ------------------------------------------------------------------------------
# Stage 3: Final Production Image
# ------------------------------------------------------------------------------
FROM gcr.io/distroless/cc-debian13

WORKDIR /app

# Copy the compiled server
COPY --from=backend-builder --chown=nonroot:nonroot /app/backend/bin/server /app/server

# Copy the Flutter Web assets
# We place them in a specific folder that the server will serve (e.g., /public)
COPY --from=flutter-builder --chown=nonroot:nonroot /app/frontend/build/web /app/public

# Environment variables
ENV PORT=8080

# Start server as non-root user
USER nonroot
CMD ["/app/server"]
