#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "${SCRIPT_DIR}/../.env" ]; then
    source "${SCRIPT_DIR}/../.env"
fi

for var in PROJECT_ID REGION REPOSITORY; do
    if [ -z "${!var:-}" ]; then
        echo "Error: ${var} is not set" >&2
        exit 1
    fi
done

SERVICE_NAME="fake-presave-validator"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${SERVICE_NAME}:latest"

echo "Configuring Docker authentication..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev"

echo "Building Docker image..."
docker build -t "${IMAGE}" "${SCRIPT_DIR}/.."

echo "Pushing Docker image..."
docker push "${IMAGE}"

echo "Deploying to Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
    --image="${IMAGE}" \
    --project="${PROJECT_ID}" \
    --region="${REGION}" \
    --platform=managed \
    --min-instances=1 \
    --allow-unauthenticated \
    --port=8080

echo "Deployment complete."
