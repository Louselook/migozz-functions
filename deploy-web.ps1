# Script para build y deploy web
# Uso: .\deploy-web.ps1

# Cargar variables desde .env local
$envFile = ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^([^=]+)=(.*)$") {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Variable -Name $name -Value $value
        }
    }
}

# Variables (editalas si no usas .env)
$API_MIGOZZ = if ($API_MIGOZZ) { $API_MIGOZZ } else { "https://migos-ms-895592952324.us-central1.run.app" }
$API_FUNCTIONS = if ($API_FUNCTIONS) { $API_FUNCTIONS } else { "https://migozz-functions-895592952324.northamerica-northeast2.run.app" }
$GEMINI_API_KEY = if ($GEMINI_API_KEY) { $GEMINI_API_KEY } else { "AIzaSyAt5HYtA6LZnun_NuMToNESDl1LmnsxJ70" }
$GOOGLE_CLIENT_ID = if ($GOOGLE_CLIENT_ID) { $GOOGLE_CLIENT_ID } else { "895592952324-4iu9ob4bo0ppn2hta6oi4qvfat3892p5.apps.googleusercontent.com" }

Write-Host "🔨 Building Flutter Web..." -ForegroundColor Cyan
flutter build web `
    --dart-define=API_MIGOZZ=$API_MIGOZZ `
    --dart-define=API_FUNCTIONS=$API_FUNCTIONS `
    --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY `
    --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host "🚀 Deploying to Firebase..." -ForegroundColor Cyan
    firebase deploy --only hosting
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Deploy completed!" -ForegroundColor Green
    } else {
        Write-Host "❌ Deploy failed" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Build failed" -ForegroundColor Red
}
