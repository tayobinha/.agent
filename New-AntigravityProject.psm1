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
    
    New-Item -ItemType SymbolicLink -Path $AgentPath -Target $GlobalAgentPath | Out-Null
    Write-Host "Successfully linked global .agent to $Target" -ForegroundColor Green
}

Export-ModuleMember -Function New-AntigravityProject
