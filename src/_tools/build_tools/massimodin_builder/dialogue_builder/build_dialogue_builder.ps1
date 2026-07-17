# Compiles the standalone dialogue builder tool that fan localizers use to pack their translated dialogues.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = (Resolve-Path "$ScriptDir\..\..\..\..\..").Path
$OutExe = Join-Path -Path $ScriptDir -ChildPath "../../dialogue_builder.exe"

# Use project-local Odin if available (.deps/odin/ installed by install.ps1)
$LocalOdin = Join-Path $ProjectDir ".deps\odin"
if (Test-Path (Join-Path $LocalOdin "odin.exe")) {
    $env:PATH = "$LocalOdin;$env:PATH"
}

Write-Host "Compiling dialogue builder..."
& odin build $ScriptDir -out:$OutExe -subsystem:windows
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to compile dialogue builder."
    exit 1
}
Write-Host "Compiled $OutExe"
