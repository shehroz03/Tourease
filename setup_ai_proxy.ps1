<#
PowerShell helper to set up the AI proxy virtualenv and install dependencies.
Usage (PowerShell):
  ./setup_ai_proxy.ps1

This script will:
 - create a .venv folder if missing
 - activate the venv and install requirements from requirements_ai.txt
 - print next steps to set GOOGLE_API_KEY and run ai_proxy.py
#>

$ErrorActionPreference = 'Stop'

Write-Host "Setting up AI proxy..." -ForegroundColor Cyan

# Check Python
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "Python not found in PATH. Please install Python 3.8+ and re-run." -ForegroundColor Red
    exit 1
}

# Create venv if missing
if (-not (Test-Path .venv)) {
    Write-Host "Creating virtual environment (.venv)..." -ForegroundColor Yellow
    python -m venv .venv
} else {
    Write-Host ".venv already exists" -ForegroundColor Green
}

# Activate and install
Write-Host "Activating venv and installing requirements..." -ForegroundColor Yellow
& .\.venv\Scripts\Activate.ps1
pip install --upgrade pip
if (Test-Path requirements_ai.txt) {
    pip install -r requirements_ai.txt
} else {
    Write-Host "requirements_ai.txt not found. Creating a minimal requirements file..." -ForegroundColor Yellow
    @("Flask","Flask-Cors","requests","python-dotenv") | Out-File -FilePath requirements_ai.txt -Encoding utf8
    pip install -r requirements_ai.txt
}

Write-Host "Setup complete." -ForegroundColor Green
Write-Host "Next steps (PowerShell):" -ForegroundColor Cyan
Write-Host "  $env:GOOGLE_API_KEY = 'YOUR_API_KEY'" -ForegroundColor Yellow
Write-Host "  .\.venv\Scripts\python.exe ai_proxy.py" -ForegroundColor Yellow
Write-Host "You can run 'python ai_proxy.py' to start the proxy (make sure .venv is activated)." -ForegroundColor Cyan

# Create a marker file to signal completion (used by the VS Code auto-reload extension)
try {
    Set-Content -Path .\.ai_proxy_setup_done -Value (Get-Date).ToString() -Force
    Write-Host "Created marker file .ai_proxy_setup_done" -ForegroundColor Green
} catch {
    Write-Host "Could not create marker file: $_" -ForegroundColor Yellow
}

# Try to auto-install the bundled VS Code extension if 'code' CLI is available
$codeCli = Get-Command code -ErrorAction SilentlyContinue
if ($codeCli) {
    Write-Host "Attempting to install the bundled VS Code extension 'tourease-auto-reload'..." -ForegroundColor Cyan
    $extPath = Join-Path $PWD '.vscode\extensions\tourease-auto-reload'
    try {
        & code --install-extension $extPath --force
        Write-Host "Extension installed (or updated)." -ForegroundColor Green
    } catch {
        Write-Host "Failed to auto-install extension. You can install it manually: code --install-extension $extPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "VS Code CLI 'code' not found in PATH — skipping extension install." -ForegroundColor Yellow
}
