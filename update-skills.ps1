$UpstreamUrl = "https://github.com/sickn33/antigravity-awesome-skills.git"
$TempPath = "C:\Users\$env:USERNAME\AppData\Local\Temp\awesome_skills_update"
$GlobalAgentPath = "C:\Users\$env:USERNAME\.agent"
$SkillsPath = Join-Path $GlobalAgentPath "skills"
$ArchFile = Join-Path $GlobalAgentPath "ARCHITECTURE.md"

Write-Host "Checking for Awesome Skills updates..." -ForegroundColor Cyan

# 1. Get Upstream Content
if (Test-Path $TempPath) {
    if (Test-Path (Join-Path $TempPath ".git")) {
        Write-Host "Updating existing temporary cache..." -ForegroundColor Yellow
        git -C $TempPath pull
    } else {
        Write-Host "Temp path exists but not a git repo. Recreation..." -ForegroundColor Yellow
        Remove-Item $TempPath -Recurse -Force
        git clone --depth 1 $UpstreamUrl $TempPath
    }
}
else {
    Write-Host "Cloning upstream repository..." -ForegroundColor Yellow
    git clone --depth 1 $UpstreamUrl $TempPath
}

# 2. Sync Skills
Write-Host "Merging skills into global folder..." -ForegroundColor Cyan
$SourceSkills = Join-Path $TempPath "skills"
if (Test-Path $SourceSkills) {
    $Folders = Get-ChildItem -Path $SourceSkills -Directory
    Write-Host "Found $($Folders.Count) skills to merge." -ForegroundColor Green

    foreach ($folder in $Folders) {
        $destPath = Join-Path $SkillsPath $folder.Name
        if (!(Test-Path $destPath)) {
            New-Item -ItemType Directory -Path $destPath -Force | Out-Null
        }
        # Copia o conteúdo da skill para o destino
        Copy-Item -Path "$($folder.FullName)\*" -Destination $destPath -Recurse -Force
    }
}

# 3. Update Statistics
Write-Host "Updating ARCHITECTURE.md stats..." -ForegroundColor Cyan
$Count = (Get-ChildItem -Path $SkillsPath -Directory).Count
Write-Host "New total skill count: $Count" -ForegroundColor Green

if (Test-Path $ArchFile) {
    # Lê com encoding UTF8 para não quebrar emojis existentes
    $Content = Get-Content -Path $ArchFile -Encoding UTF8
    
    # Atualiza a tabela de estatísticas (| **Total Skills** | 840 |)
    $Content = $Content -replace "\| \*\*Total Skills\*\* \| \d+ \|", "| **Total Skills** | $Count |"

    # Atualiza o resumo no topo (- **840 Skills**)
    $Content = $Content -replace "- \*\*\d+ Skills\*\*", "- **$Count Skills**"

    # Grava com encoding UTF8
    Set-Content -Path $ArchFile -Value $Content -Encoding UTF8
    Write-Host "Sync complete! Total skills in ARCHITECTURE.md: $Count" -ForegroundColor Green
} else {
    Write-Host "Warning: ARCHITECTURE.md not found at $ArchFile" -ForegroundColor Red
}

Write-Host "Reminder: Don't forget to commit and push changes in your global .agent folder." -ForegroundColor Yellow
