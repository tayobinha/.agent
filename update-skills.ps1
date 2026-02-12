<#
.SYNOPSIS
    Updates Antigravity Agent skills from the awesome-skills repository.
.DESCRIPTION
    1. Synchronizes the external library from sickn33/antigravity-awesome-skills.
    2. Merges new/updated skills into the global .agent/skills folder.
    3. Updates ARCHITECTURE.md statistics.
#>

$UpstreamUrl = "https://github.com/sickn33/antigravity-awesome-skills.git"
$TempPath = "C:\Users\$env:USERNAME\AppData\Local\Temp\awesome_skills_update"
$GlobalAgentPath = "C:\Users\$env:USERNAME\.agent"
$SkillsPath = Join-Path $GlobalAgentPath "skills"
$ArchFile = Join-Path $GlobalAgentPath "ARCHITECTURE.md"

Write-Host "🔍 Checking for Awesome Skills updates..." -ForegroundColor Cyan

# 1. Get Upstream Content
if (Test-Path $TempPath) {
    Write-Host "🔄 Updating existing temporary cache..." -ForegroundColor Yellow
    git -C $TempPath pull
}
else {
    Write-Host "☁️  Cloning upstream repository..." -ForegroundColor Yellow
    git clone --depth 1 $UpstreamUrl $TempPath
}

# 2. Sync Skills
Write-Host "🚀 Merging skills into global folder..." -ForegroundColor Cyan
$SourceSkills = Join-Path $TempPath "skills"
$Folders = Get-ChildItem -Path $SourceSkills -Directory

$addedCount = 0
foreach ($folder in $folders) {
    $destFolder = Join-Path $SkillsPath $folder.Name
    # Copy new or update existing (from awesome-skills only)
    Copy-Item -Path $folder.FullName -Destination $SkillsPath -Recurse -Force
    $addedCount++
}

# 3. Update Statistics
Write-Host "📊 Updating ARCHITECTURE.md stats..." -ForegroundColor Cyan
$Count = (Get-ChildItem -Path $SkillsPath -Directory).Count
$Content = Get-Content -Path $ArchFile

# Update count in stats table (| **Total Skills** | 840 |)
$Content = $Content -replace "\| \*\*Total Skills\*\* \| \d+ \|", "| **Total Skills** | $Count |"

# Update count in overview (- **840 Skills**)
$Content = $Content -replace "- \*\*\d+ Skills\*\*", "- **$Count Skills**"

Set-Content -Path $ArchFile -Value $Content

Write-Host "✅ Sync complete! Total skills: $Count" -ForegroundColor Green
Write-Host "📢 Don't forget to commit and push changes in your global .agent folder." -ForegroundColor Yellow
