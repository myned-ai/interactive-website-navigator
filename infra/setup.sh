#!/bin/bash
# ==============================================================================
# One-time GCP setup — run before the first GitHub Actions deploy
#
# Prerequisites:
#   - gcloud CLI authenticated with a project owner account
#   - GitHub repo connected to GCP (for Workload Identity or SA key)
#
# What it creates:
#   1. Enables required APIs
#   2. Creates Artifact Registry repo for Docker images
#   3. Creates Cloud Storage bucket for the static client site
#   4. Creates a service account for GitHub Actions with minimal permissions
#   5. Grants Cloud Run service account access to Vertex AI (Gemini)
# ==============================================================================
set -euo pipefail

read -rp "GCP Project ID: " PROJECT_ID
read -rp "Region [europe-west1]: " REGION
REGION="${REGION:-europe-west1}"
SERVICE_NAME="interactive-website-navigator"
BUCKET_NAME="${PROJECT_ID}-${SERVICE_NAME}-client"
SA_NAME="github-actions"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "==> Setting project: ${PROJECT_ID}"
gcloud config set project "$PROJECT_ID"

# --- 1. Enable APIs ---
echo "==> Enabling APIs..."
gcloud services enable \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  aiplatform.googleapis.com \
  storage.googleapis.com

# --- 2. Artifact Registry ---
echo "==> Creating Artifact Registry repository..."
gcloud artifacts repositories create "$SERVICE_NAME" \
  --repository-format=docker \
  --location="$REGION" \
  --description="Docker images for ${SERVICE_NAME}" \
  2>/dev/null || echo "    (already exists)"

# --- 3. Cloud Storage bucket for client ---
echo "==> Creating Cloud Storage bucket..."
gsutil mb -p "$PROJECT_ID" -l "$REGION" "gs://${BUCKET_NAME}" \
  2>/dev/null || echo "    (already exists)"

# Enable static website hosting
gsutil web set -m index.html -e index.html "gs://${BUCKET_NAME}"

# Make bucket publicly readable
gsutil iam ch allUsers:objectViewer "gs://${BUCKET_NAME}"

# --- 4. Service account for GitHub Actions ---
echo "==> Creating GitHub Actions service account..."
gcloud iam service-accounts create "$SA_NAME" \
  --display-name="GitHub Actions CI/CD" \
  2>/dev/null || echo "    (already exists)"

# Grant required roles
echo "==> Granting IAM roles to ${SA_EMAIL}..."
for ROLE in \
  roles/run.admin \
  roles/artifactregistry.writer \
  roles/storage.admin \
  roles/iam.serviceAccountUser; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$ROLE" \
    --quiet --no-user-output-enabled
done

# --- 5. Vertex AI access for Cloud Run ---
echo "==> Granting Vertex AI access to default compute service account..."
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/aiplatform.user" \
  --quiet

# --- 6. Generate AUTH_SECRET_KEY ---
echo "==> Generating AUTH_SECRET_KEY..."
AUTH_SECRET_KEY=$(openssl rand -hex 32)

# --- 7. Generate SA key for GitHub ---
echo "==> Generating service account key..."
KEY_FILE="/tmp/${SA_NAME}-key.json"
gcloud iam service-accounts keys create "$KEY_FILE" \
  --iam-account="$SA_EMAIL"

CLIENT_ORIGIN="https://storage.googleapis.com/${BUCKET_NAME}"

echo ""
echo "============================================"
echo "  Setup complete!"
echo "============================================"
echo ""
echo "Add these GitHub repository secrets:"
echo ""
echo "  GCP_PROJECT_ID       = ${PROJECT_ID}"
echo "  GCP_SA_KEY           = $(cat "$KEY_FILE")"
echo "  GCP_CLIENT_BUCKET    = ${BUCKET_NAME}"
echo "  GCP_AUTH_SECRET_KEY  = ${AUTH_SECRET_KEY}"
echo ""
echo "Then delete the key file:"
echo "  rm ${KEY_FILE}"
echo ""
echo "Client site will be available at:"
echo "  ${CLIENT_ORIGIN}/index.html"
echo ""
