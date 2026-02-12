function New-AntigravityProject {
    param (
        [string]$Path = "."
    )
    
    $Target = Resolve-Path $Path
    $AgentPath = Join-Path $Target ".agent"
    $GlobalAgentPath = "C:\Users\Samira\.agent"
    
    if (Test-Path $AgentPath) {
        Write-Warning "An .agent folder already exists in $Target. Skipping link creation."
        return
    }
    
    try {
        New-Item -ItemType Junction -Path $AgentPath -Target $GlobalAgentPath -ErrorAction Stop | Out-Null
        Write-Host "Successfully linked global .agent to $Target (using Junction)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create link: $_"
    }
}

Export-ModuleMember -Function New-AntigravityProject
