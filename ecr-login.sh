#!/usr/bin/env bash

AWS_REGION=${3:-ap-southeast-2}
ECR_PUBLIC=${2:-true}

# Check if we are in an AWS CLI session
if ! aws sts get-caller-identity &> /dev/null; then
    echo "You must be logged in to AWS CLI to push to ECR."
    exit 1
fi

echo "Logging in to ECR..."

if [[ $ECR_PUBLIC == "true" ]]; then
    REPO="public.ecr.aws"
    aws ecr-public get-login-password --region us-east-1 \
    | docker login --username AWS --password-stdin "$REPO"
else
    REPO="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    aws ecr get-login-password --region "$AWS_REGION" \
    | docker login --username AWS --password-stdin "$REPO"
fi

exit 0