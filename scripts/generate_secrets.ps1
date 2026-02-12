# RMM SaaS - Secrets Generator
Write-Host "Generating secrets..." -ForegroundColor Cyan

# Create directory
New-Item -ItemType Directory -Force -Path ".secrets" | Out-Null

# JWT Secret
$jwt = -join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object { [char]$_ })
$jwt | Out-File ".secrets/jwt_secret" -NoNewline -Encoding ASCII

# Client Token
$token = [Convert]::ToBase64String([byte[]](1..24 | ForEach-Object { Get-Random -Maximum 256 }))
$token | Out-File ".secrets/client_token" -NoNewline -Encoding ASCII

# DB Password
$dbpw = [Convert]::ToBase64String([byte[]](1..32 | ForEach-Object { Get-Random -Maximum 256 }))
$dbpw | Out-File ".secrets/db_password" -NoNewline -Encoding ASCII

Write-Host "Done! Secrets created in .secrets/" -ForegroundColor Green
