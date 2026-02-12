<#
.SYNOPSIS
    Bootstraps the Antigravity Agent configuration from GitHub.
.DESCRIPTION
    1. Checks if C:\Users\$env:USERNAME\.agent exists.
    2. If not, clones from GitHub.
    3. If yes, pulls latest changes.
    4. Links the global .agent to the current directory.
#>
param(
    [string]$RepoUrl = "https://github.com/tayobinha/.agent.git"
)

$GlobalPath = "C:\Users\$env:USERNAME\.agent"
$CurrentPath = Get-Location

Write-Host "🚀 Starting Antigravity Agent Bootstrap..." -ForegroundColor Cyan

# 1. Ensure Global Repo Exists
if (-not (Test-Path $GlobalPath)) {
    Write-Host "☁️  Cloning from GitHub..." -ForegroundColor Yellow
    git clone $RepoUrl $GlobalPath
}
else {
    Write-Host "🔄 Updating from GitHub..." -ForegroundColor Yellow
    git -C $GlobalPath pull
}

# 2. Link to Current Project
$ProjectAgentPath = Join-Path $CurrentPath ".agent"

if (Test-Path $ProjectAgentPath) {
    Write-Warning "⚠️  .agent folder already exists in this project."
}
else {
    try {
        New-Item -ItemType Junction -Path $ProjectAgentPath -Target $GlobalPath -ErrorAction Stop | Out-Null
        Write-Host "✅ Linked global .agent to current project!" -ForegroundColor Green
    }
    catch {
        Write-Error "❌ Failed to create link: $_"
    }
}

Write-Host "🎉 Setup Complete! You are now using the latest agent configuration." -ForegroundColor Cyan
