#!/usr/bin/env bash

VARIANT=${1:-php}
VERSION=${2:-8.3}

DATE=$(date +%Y%m%d)

if [[ ${VARIANT} == "php" ]]; then
	docker build -t joeniland/laravel-ci:"${VERSION}"-"${DATE}" --build-arg PHP_VERSION="${VERSION}" php
elif [[ ${VARIANT} == "docker" ]]; then
	docker build -t joeniland/laravel-ci:"${VERSION}"-docker-"${DATE}" docker
else
	echo "Invalid variant"
fi
