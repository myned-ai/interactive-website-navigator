# ==============================================================================
# One-time GCP setup — run before the first GitHub Actions deploy (Windows)
#
# Prerequisites:
#   - Google Cloud SDK installed (gcloud, gsutil)
#   - Authenticated with a project owner account
#
# What it creates:
#   1. Enables required APIs
#   2. Creates Artifact Registry repo for Docker images
#   3. Creates Cloud Storage bucket for the static client site
#   4. Creates a service account for GitHub Actions with minimal permissions
#   5. Grants Cloud Run service account access to Vertex AI (Gemini)
# ==============================================================================
$ErrorActionPreference = "Stop"

$PROJECT_ID = Read-Host "GCP Project ID"
$REGION = Read-Host "Region [europe-west1]"
if ([string]::IsNullOrWhiteSpace($REGION)) { $REGION = "europe-west1" }

$SERVICE_NAME = "interactive-website-navigator"
$BUCKET_NAME = "${PROJECT_ID}-${SERVICE_NAME}-client"
$SA_NAME = "github-actions"
$SA_EMAIL = "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

Write-Host "==> Setting project: $PROJECT_ID"
gcloud config set project $PROJECT_ID

# --- 1. Enable APIs ---
Write-Host "==> Enabling APIs..."
gcloud services enable `
  cloudbuild.googleapis.com `
  run.googleapis.com `
  artifactregistry.googleapis.com `
  aiplatform.googleapis.com `
  storage.googleapis.com

# --- 2. Artifact Registry ---
Write-Host "==> Creating Artifact Registry repository..."
gcloud artifacts repositories create $SERVICE_NAME `
  --repository-format=docker `
  --location=$REGION `
  --description="Docker images for $SERVICE_NAME" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "    (already exists)" }

# --- 3. Cloud Storage bucket for client ---
Write-Host "==> Creating Cloud Storage bucket..."
gsutil mb -p $PROJECT_ID -l $REGION "gs://${BUCKET_NAME}" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "    (already exists)" }

gsutil web set -m index.html -e index.html "gs://${BUCKET_NAME}"
gsutil iam ch allUsers:objectViewer "gs://${BUCKET_NAME}"

# --- 4. Service account for GitHub Actions ---
Write-Host "==> Creating GitHub Actions service account..."
gcloud iam service-accounts create $SA_NAME `
  --display-name="GitHub Actions CI/CD" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "    (already exists)" }

Write-Host "==> Granting IAM roles to $SA_EMAIL..."
$roles = @(
  "roles/run.admin",
  "roles/artifactregistry.writer",
  "roles/storage.admin",
  "roles/iam.serviceAccountUser"
)
foreach ($role in $roles) {
  gcloud projects add-iam-policy-binding $PROJECT_ID `
    --member="serviceAccount:${SA_EMAIL}" `
    --role=$role `
    --quiet --no-user-output-enabled
}

# --- 5. Vertex AI access for Cloud Run ---
Write-Host "==> Granting Vertex AI access to default compute service account..."
$PROJECT_NUMBER = (gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
gcloud projects add-iam-policy-binding $PROJECT_ID `
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" `
  --role="roles/aiplatform.user" `
  --quiet

# --- 6. Generate AUTH_SECRET_KEY ---
Write-Host "==> Generating AUTH_SECRET_KEY..."
$AUTH_SECRET_KEY = -join ((1..32) | ForEach-Object { "{0:x2}" -f (Get-Random -Maximum 256) })

# --- 7. Generate SA key for GitHub ---
Write-Host "==> Generating service account key..."
$KEY_FILE = "$env:TEMP\${SA_NAME}-key.json"
gcloud iam service-accounts keys create $KEY_FILE `
  --iam-account=$SA_EMAIL

$CLIENT_ORIGIN = "https://storage.googleapis.com/${BUCKET_NAME}"

Write-Host ""
Write-Host "============================================"
Write-Host "  Setup complete!"
Write-Host "============================================"
Write-Host ""
Write-Host "Add these GitHub repository secrets:"
Write-Host ""
Write-Host "  GCP_PROJECT_ID       = $PROJECT_ID"
Write-Host "  GCP_SA_KEY           = $(Get-Content $KEY_FILE -Raw)"
Write-Host "  GCP_CLIENT_BUCKET    = $BUCKET_NAME"
Write-Host "  GCP_AUTH_SECRET_KEY  = $AUTH_SECRET_KEY"
Write-Host ""
Write-Host "Then delete the key file:"
Write-Host "  Remove-Item $KEY_FILE"
Write-Host ""
Write-Host "Client site will be available at:"
Write-Host "  ${CLIENT_ORIGIN}/index.html"
Write-Host ""
