#!/usr/bin/env bash

VARIANT=${1:-php}
VERSION=${2:-8.3}
PLATFORM=${3:-linux/amd64}
PUSH=${4:-false}
MANIFEST=${5:-false}
ECR_REPO=${6:-}

DEFAULT_REPO=joeniland

DATE=$(date +%Y%m%d)

PLATFORM_MAP=(
    "linux/amd64" "amd64"
    "linux/arm64" "arm64"
)

DOCKER_PLATFORM=$(echo "${PLATFORM_MAP[@]}" | tr ' ' '\n' | grep -A1 "${PLATFORM}" | tail -n1)

if [[ ${VARIANT} == "php" ]]; then
    IMAGE_TAG="${VERSION}-${DOCKER_PLATFORM}-${DATE}"
    LATEST_TAG="${VERSION}-latest"
    docker buildx build --platform="${PLATFORM}" \
        -t ${DEFAULT_REPO}/laravel-ci:"${IMAGE_TAG}" \
        -t ${DEFAULT_REPO}/laravel-ci:${LATEST_TAG} --build-arg PHP_BASE_VERSION="${VERSION}" php
elif [[ ${VARIANT} == "docker" ]]; then
    IMAGE_TAG="${VERSION}-docker-${DOCKER_PLATFORM}-${DATE}"
    LATEST_TAG="${VERSION}-docker-latest"
    docker buildx build --platform="${PLATFORM}" --load \
        -t ${DEFAULT_REPO}/laravel-ci:"${IMAGE_TAG}" \
        -t ${DEFAULT_REPO}/laravel-ci:${LATEST_TAG} --build-arg PHP_VERSION="${VERSION}" docker 
else
    echo "Invalid variant"
    exit 1
fi

 if [[ ${ECR_REPO} != "" ]]; then
    docker tag ${DEFAULT_REPO}/laravel-ci:${IMAGE_TAG} ${ECR_REPO}/laravel-ci:${IMAGE_TAG}
fi

if [[ ${PUSH} == "true" ]]; then
    docker push ${DEFAULT_REPO}/laravel-ci:"${IMAGE_TAG}"
    docker push ${DEFAULT_REPO}/laravel-ci:${LATEST_TAG}
    if [[ ${ECR_REPO} != "" ]]; then
        ./ecr-login.sh || { echo "ECR login failed"; exit 1; }
        docker push ${ECR_REPO}/laravel-ci:${IMAGE_TAG}
        docker push ${ECR_REPO}/laravel-ci:${LATEST_TAG}
    fi
fi


# Generate manifest command
if [[ ${MANIFEST} == "true" ]]; then
    MANIFEST_CMD="docker manifest create ${DEFAULT_REPO}/laravel-ci:${VERSION}-${DATE}"
    if [[ ${VARIANT} == "docker" ]]; then
        MANIFEST_CMD="docker manifest create ${DEFAULT_REPO}/laravel-ci:${VERSION}-docker-${DATE}"
    fi

    # Add all platform images to the manifest command
    for i in $(seq 0 2 $((${#PLATFORM_MAP[@]} - 1))); do
        DOCKER_PLATFORM=${PLATFORM_MAP[i + 1]}
        if [[ ${VARIANT} == "php" ]]; then
            IMAGE_TAG="${VERSION}-${DOCKER_PLATFORM}-${DATE}"
        else
            IMAGE_TAG="${VERSION}-docker-${DOCKER_PLATFORM}-${DATE}"
        fi
        MANIFEST_CMD="${MANIFEST_CMD} ${DEFAULT_REPO}/laravel-ci:${IMAGE_TAG}"
    done

    echo "Run these commands to push the manifest:"
    echo "${MANIFEST_CMD}"
    echo "docker manifest push ${DEFAULT_REPO}/laravel-ci:${VERSION}-${DATE}"

    if [[ ${ECR_REPO} != ""  ]]; then
        if [[ ${VARIANT} == "php" ]]; then
            MANIFEST_CMD="docker manifest create ${ECR_REPO}/laravel-ci:${VERSION}-${DATE}"
        else
            MANIFEST_CMD="docker manifest create ${ECR_REPO}/laravel-ci:${VERSION}-docker-${DATE}"
        fi
    fi
fi
