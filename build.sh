#!/usr/bin/env bash

VARIANT=${1:-php}
VERSION=${2:-8.3}
PLATFORM=${3:-multiarch}
PUSH=${4:-false}
ECR_REPO=${5:-}

DEFAULT_REPO=joeniland

DATE=$(date +%Y%m%d)

log() {
    echo "==> $*"
}

# Docker credentials live in a credential helper (e.g. osxkeychain), not in
# config.json, so `docker info`'s Username field can't be relied on.
docker_hub_logged_in() {
    local config="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
    [[ -f ${config} ]] || return 1

    local creds_store
    creds_store=$(sed -n 's/.*"credsStore":[[:space:]]*"\([^"]*\)".*/\1/p' "${config}")

    if [[ -n ${creds_store} ]]; then
        echo "https://index.docker.io/v1/" | "docker-credential-${creds_store}" get 2>/dev/null | grep -q '"Secret"'
        return $?
    fi

    grep -q '"https://index.docker.io/v1/"' "${config}"
}

# Preflight: verify Docker Hub and ECR auth before doing any build work
preflight() {
    if [[ ${PUSH} != "true" ]]; then
        return
    fi

    log "Preflight: checking Docker Hub authentication (docker.io/${DEFAULT_REPO})"
    if ! docker_hub_logged_in; then
        echo "ERROR: not logged in to Docker Hub. Run: docker login"
        exit 1
    fi
    log "Preflight: Docker Hub OK"

    if [[ ${ECR_REPO} != "" ]]; then
        log "Preflight: checking AWS credentials for ECR push"
        if ! aws sts get-caller-identity &>/dev/null; then
            echo "ERROR: no valid AWS credentials. Run under aws-vault exec <profile> -- ..."
            exit 1
        fi
        CALLER_ARN=$(aws sts get-caller-identity --query Arn --output text)
        log "Preflight: AWS OK (${CALLER_ARN})"
    fi
}

preflight

# "both" builds php first, then docker on top of it, so the dind image
# never bakes in a stale base.
if [[ ${VARIANT} == "both" ]]; then
    "$0" php "${VERSION}" "${PLATFORM}" "${PUSH}" "${ECR_REPO}" || exit $?
    exec "$0" docker "${VERSION}" "${PLATFORM}" "${PUSH}" "${ECR_REPO}"
fi

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
        log "Creating multiarch builder..."
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
    log "Logging in to ECR..."
    ./ecr-login.sh || { echo "ERROR: ECR login failed"; exit 1; }
fi

# Build command with all tags
BUILD_CMD="docker buildx build --platform=${PLATFORMS}"

# Add default repo tags
BUILD_CMD="${BUILD_CMD} -t ${DEFAULT_REPO}/laravel-ci:${IMAGE_TAG}"
BUILD_CMD="${BUILD_CMD} -t ${DEFAULT_REPO}/laravel-ci:${LATEST_TAG}"

TAGS=("${DEFAULT_REPO}/laravel-ci:${IMAGE_TAG}" "${DEFAULT_REPO}/laravel-ci:${LATEST_TAG}")

# Add ECR tags if specified
if [[ ${ECR_REPO} != "" ]]; then
    BUILD_CMD="${BUILD_CMD} -t ${ECR_REPO}/laravel-ci:${IMAGE_TAG}"
    BUILD_CMD="${BUILD_CMD} -t ${ECR_REPO}/laravel-ci:${LATEST_TAG}"
    TAGS+=("${ECR_REPO}/laravel-ci:${IMAGE_TAG}" "${ECR_REPO}/laravel-ci:${LATEST_TAG}")
fi

# Add push or load flag
if [[ ${PUSH} == "true" ]]; then
    BUILD_CMD="${BUILD_CMD} --push"
elif [[ ${PLATFORM} != "multiarch" ]]; then
    # Only add --load for single platform builds
    BUILD_CMD="${BUILD_CMD} --load"
fi

log "Building ${VARIANT} variant (PHP ${VERSION}, platform: ${PLATFORMS}, push: ${PUSH})"
for tag in "${TAGS[@]}"; do
    log "  tag: ${tag}"
done

# Execute the build with all tags
${BUILD_CMD} \
    --build-arg ${BUILD_ARG_NAME}="${VERSION}" \
    ${VARIANT}
BUILD_STATUS=$?

if [[ ${BUILD_STATUS} -ne 0 ]]; then
    echo "ERROR: build failed (exit ${BUILD_STATUS})"
    exit ${BUILD_STATUS}
fi

if [[ ${PUSH} == "true" ]]; then
    log "Pushed:"
else
    log "Built (not pushed):"
fi
for tag in "${TAGS[@]}"; do
    echo "  ${tag}"
done

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
    echo "  variant:  php, docker, or both (default: php)"
    echo "  version:  PHP version (default: 8.3)"
    echo "  platform: multiarch, linux/amd64, or linux/arm64 (default: multiarch)"
    echo "  push:     true or false (default: false)"
    echo "  ecr_repo: ECR repository URL (optional)"
fi
