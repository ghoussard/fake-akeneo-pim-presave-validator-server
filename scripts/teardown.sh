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

echo "Deleting Cloud Run service..."
gcloud run services delete "${SERVICE_NAME}" \
    --project="${PROJECT_ID}" \
    --region="${REGION}" \
    --quiet

echo "Deleting container image..."
gcloud artifacts docker images delete "${IMAGE}" \
    --project="${PROJECT_ID}" \
    --quiet \
    --delete-tags

echo "Teardown complete."
