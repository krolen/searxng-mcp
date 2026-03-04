#!/bin/bash

set -e  # Exit on error

# Configuration
REGISTRY="192.168.0.100:5000"
IMAGE_NAME="searxng-mcp"
VERSION_FILE="VERSION"

# Read current version
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
else
    CURRENT_VERSION="0.1.26"
fi

echo "Current version: $CURRENT_VERSION"

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Increment patch version
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"

# Update VERSION file
echo "$NEW_VERSION" > VERSION
echo "New version: $NEW_VERSION"

# Build the Docker image
echo "Building Docker image..."
docker build -t "${IMAGE_NAME}:latest" .

# Tag with new version
docker tag "${IMAGE_NAME}:latest" "${REGISTRY}/${IMAGE_NAME}:${NEW_VERSION}"

# Check if registry credentials are provided
if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]; then
    echo "Warning: DOCKER_USERNAME or DOCKER_PASSWORD not set. Skipping login."
else
    # Log in to private registry
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin "$REGISTRY"
fi

# Push to private registry
echo "Pushing to registry..."
docker push "${REGISTRY}/${IMAGE_NAME}:${NEW_VERSION}"

echo "Successfully built and deployed version: $NEW_VERSION"