#!/usr/bin/env bash

VARIANT=${1:-php}
VERSION=${2:-8.3}
PLATFORM=${3:-multiarch}
PUSH=${4:-false}
ECR_REPO=${5:-}

DEFAULT_REPO=joeniland

DATE=$(date +%Y%m%d)

# Platform handling
if [[ ${PLATFORM} == "multiarch" ]]; then
    PLATFORMS="linux/amd64,linux/arm64"
    PLATFORM_SUFFIX=""
else
    PLATFORMS="${PLATFORM}"
    # Extract platform suffix for image tag
    PLATFORM_SUFFIX="-$(echo ${PLATFORM} | sed 's/linux\///')"
fi

# Ensure we have the right builder for multiarch builds
if [[ ${PLATFORM} == "multiarch" ]]; then
    BUILDER_NAME="multiarch"
    
    # Check if builder exists, if not create it
    if ! docker buildx ls | grep -q "^${BUILDER_NAME}"; then
        echo "Creating multiarch builder..."
        docker buildx create --name ${BUILDER_NAME} --driver docker-container --bootstrap
    fi
    
    # Use the multiarch builder
    docker buildx use ${BUILDER_NAME}
fi

if [[ ${VARIANT} == "php" ]]; then
    IMAGE_TAG="${VERSION}${PLATFORM_SUFFIX}-${DATE}"
    LATEST_TAG="${VERSION}-latest"
    BUILD_ARG_NAME="PHP_BASE_VERSION"
    
elif [[ ${VARIANT} == "docker" ]]; then
    IMAGE_TAG="${VERSION}-docker${PLATFORM_SUFFIX}-${DATE}"
    LATEST_TAG="${VERSION}-docker-latest"
    BUILD_ARG_NAME="PHP_VERSION"
    
else
    echo "Invalid variant"
    exit 1
fi

# Handle ECR login if needed
if [[ ${ECR_REPO} != "" && ${PUSH} == "true" ]]; then
    ./ecr-login.sh || { echo "ECR login failed"; exit 1; }
fi

# Build command with all tags
BUILD_CMD="docker buildx build --platform=${PLATFORMS}"

# Add default repo tags
BUILD_CMD="${BUILD_CMD} -t ${DEFAULT_REPO}/laravel-ci:${IMAGE_TAG}"
BUILD_CMD="${BUILD_CMD} -t ${DEFAULT_REPO}/laravel-ci:${LATEST_TAG}"

# Add ECR tags if specified
if [[ ${ECR_REPO} != "" ]]; then
    BUILD_CMD="${BUILD_CMD} -t ${ECR_REPO}/laravel-ci:${IMAGE_TAG}"
    BUILD_CMD="${BUILD_CMD} -t ${ECR_REPO}/laravel-ci:${LATEST_TAG}"
fi

# Add push or load flag
if [[ ${PUSH} == "true" ]]; then
    BUILD_CMD="${BUILD_CMD} --push"
elif [[ ${PLATFORM} != "multiarch" ]]; then
    # Only add --load for single platform builds
    BUILD_CMD="${BUILD_CMD} --load"
fi

# Execute the build with all tags
${BUILD_CMD} \
    --build-arg ${BUILD_ARG_NAME}="${VERSION}" \
    ${VARIANT}

# Show usage examples
if [[ $# -eq 0 ]]; then
    echo ""
    echo "Usage: $0 <variant> <version> <platform> <push> <ecr_repo>"
    echo ""
    echo "Examples:"
    echo "  $0 php 8.3 multiarch true"
    echo "  $0 php 8.3 linux/amd64 false"
    echo "  $0 docker 8.2 linux/arm64 true"
    echo "  $0 php 8.3 multiarch true public.ecr.aws/my-repo"
    echo ""
    echo "Parameters:"
    echo "  variant:  php or docker (default: php)"
    echo "  version:  PHP version (default: 8.3)"
    echo "  platform: multiarch, linux/amd64, or linux/arm64 (default: multiarch)"
    echo "  push:     true or false (default: false)"
    echo "  ecr_repo: ECR repository URL (optional)"
fi