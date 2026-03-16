# ==============================================================================
# Teardown — remove all GCP resources created by setup.ps1 (Windows)
#
# This will permanently delete:
#   - Cloud Run service
#   - Artifact Registry repository (and all images)
#   - Cloud Storage bucket (and all objects)
#   - GitHub Actions service account (and all keys)
#   - IAM bindings added by setup.ps1
#
# APIs are NOT disabled (other services in the project may depend on them).
# ==============================================================================
$ErrorActionPreference = "Stop"

$PROJECT_ID = Read-Host "GCP Project ID"
$REGION = Read-Host "Region [europe-west1]"
if ([string]::IsNullOrWhiteSpace($REGION)) { $REGION = "europe-west1" }

$SERVICE_NAME = "interactive-website-navigator"
$BUCKET_NAME = "${PROJECT_ID}-${SERVICE_NAME}-client"
$SA_NAME = "github-actions"
$SA_EMAIL = "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

Write-Host ""
Write-Host "This will DELETE the following resources in project '${PROJECT_ID}':"
Write-Host "  - Cloud Run service: ${SERVICE_NAME}"
Write-Host "  - Artifact Registry repo: ${SERVICE_NAME}"
Write-Host "  - Cloud Storage bucket: ${BUCKET_NAME}"
Write-Host "  - Service account: ${SA_EMAIL}"
Write-Host ""
$CONFIRM = Read-Host "Are you sure? (yes/no)"
if ($CONFIRM -ne "yes") {
  Write-Host "Aborted."
  exit 0
}

gcloud config set project $PROJECT_ID
$PROJECT_NUMBER = (gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# --- 1. Delete Cloud Run service ---
Write-Host "==> Deleting Cloud Run service..."
gcloud run services delete $SERVICE_NAME `
  --region=$REGION `
  --quiet 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "    (not found or already deleted)" }

# --- 2. Delete Artifact Registry repository ---
Write-Host "==> Deleting Artifact Registry repository..."
gcloud artifacts repositories delete $SERVICE_NAME `
  --location=$REGION `
  --quiet 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "    (not found or already deleted)" }

# --- 3. Delete Cloud Storage bucket ---
Write-Host "==> Deleting Cloud Storage bucket..."
gsutil -m rm -r "gs://${BUCKET_NAME}" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "    (not found or already deleted)" }

# --- 4. Remove IAM bindings ---
Write-Host "==> Removing IAM bindings..."
$roles = @(
  "roles/run.admin",
  "roles/artifactregistry.writer",
  "roles/storage.admin",
  "roles/iam.serviceAccountUser"
)
foreach ($role in $roles) {
  gcloud projects remove-iam-policy-binding $PROJECT_ID `
    --member="serviceAccount:${SA_EMAIL}" `
    --role=$role `
    --quiet --no-user-output-enabled 2>$null
}

gcloud projects remove-iam-policy-binding $PROJECT_ID `
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" `
  --role="roles/aiplatform.user" `
  --quiet --no-user-output-enabled 2>$null

# --- 5. Delete service account ---
Write-Host "==> Deleting service account..."
gcloud iam service-accounts delete $SA_EMAIL `
  --quiet 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "    (not found or already deleted)" }

Write-Host ""
Write-Host "============================================"
Write-Host "  Teardown complete!"
Write-Host "============================================"
Write-Host ""
Write-Host "Remember to also remove the GitHub repository secrets:"
Write-Host "  GCP_PROJECT_ID, GCP_SA_KEY, GCP_CLIENT_BUCKET, GCP_AUTH_SECRET_KEY"
Write-Host ""
