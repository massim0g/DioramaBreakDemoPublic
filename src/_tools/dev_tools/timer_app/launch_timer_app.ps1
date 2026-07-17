$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDir = (Resolve-Path "$projectDir\..\..\..\..").Path

# Use project-local Odin if available (.deps/odin/ installed by install.ps1)
$localOdin = Join-Path $repoDir ".deps\odin"
if (Test-Path (Join-Path $localOdin "odin.exe")) {
    $env:PATH = "$localOdin;$env:PATH"
}

Push-Location $projectDir
Start-Process `
    -FilePath "odin.exe" `
    -ArgumentList "run", "timer_app.odin", "-file" `
    -WorkingDirectory $projectDir `
    -NoNewWindow `
    -Wait
Pop-Location