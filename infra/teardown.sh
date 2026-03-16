#!/bin/bash
# ==============================================================================
# Teardown — remove all GCP resources created by setup.sh
#
# This will permanently delete:
#   - Cloud Run service
#   - Artifact Registry repository (and all images)
#   - Cloud Storage bucket (and all objects)
#   - GitHub Actions service account (and all keys)
#   - IAM bindings added by setup.sh
#
# APIs are NOT disabled (other services in the project may depend on them).
# ==============================================================================
set -euo pipefail

read -rp "GCP Project ID: " PROJECT_ID
read -rp "Region [europe-west1]: " REGION
REGION="${REGION:-europe-west1}"

SERVICE_NAME="interactive-website-navigator"
BUCKET_NAME="${PROJECT_ID}-${SERVICE_NAME}-client"
SA_NAME="github-actions"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo ""
echo "This will DELETE the following resources in project '${PROJECT_ID}':"
echo "  - Cloud Run service: ${SERVICE_NAME}"
echo "  - Artifact Registry repo: ${SERVICE_NAME}"
echo "  - Cloud Storage bucket: ${BUCKET_NAME}"
echo "  - Service account: ${SA_EMAIL}"
echo ""
read -rp "Are you sure? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

gcloud config set project "$PROJECT_ID"
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')

# --- 1. Delete Cloud Run service ---
echo "==> Deleting Cloud Run service..."
gcloud run services delete "$SERVICE_NAME" \
  --region="$REGION" \
  --quiet 2>/dev/null || echo "    (not found or already deleted)"

# --- 2. Delete Artifact Registry repository ---
echo "==> Deleting Artifact Registry repository..."
gcloud artifacts repositories delete "$SERVICE_NAME" \
  --location="$REGION" \
  --quiet 2>/dev/null || echo "    (not found or already deleted)"

# --- 3. Delete Cloud Storage bucket ---
echo "==> Deleting Cloud Storage bucket..."
gsutil -m rm -r "gs://${BUCKET_NAME}" 2>/dev/null || echo "    (not found or already deleted)"

# --- 4. Remove IAM bindings ---
echo "==> Removing IAM bindings..."
for ROLE in \
  roles/run.admin \
  roles/artifactregistry.writer \
  roles/storage.admin \
  roles/iam.serviceAccountUser; do
  gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$ROLE" \
    --quiet --no-user-output-enabled 2>/dev/null || true
done

gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/aiplatform.user" \
  --quiet --no-user-output-enabled 2>/dev/null || true

# --- 5. Delete service account ---
echo "==> Deleting service account..."
gcloud iam service-accounts delete "$SA_EMAIL" \
  --quiet 2>/dev/null || echo "    (not found or already deleted)"

echo ""
echo "============================================"
echo "  Teardown complete!"
echo "============================================"
echo ""
echo "Remember to also remove the GitHub repository secrets:"
echo "  GCP_PROJECT_ID, GCP_SA_KEY, GCP_CLIENT_BUCKET, GCP_AUTH_SECRET_KEY"
echo ""
