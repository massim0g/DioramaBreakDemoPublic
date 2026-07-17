# Kills any running build daemon, recompiles it, and relaunches it.
# Replaces the old Watchman-based full_build_reconstruction.ps1.
# The daemon cleans the build directory and does a full rebuild itself on startup, then stays attached, streaming its output to this terminal across game runs.
# Pass -release to skip the debug-config prompt (used by release_build_export.ps1).
param(
    [switch]$release
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = "$ScriptDir\..\..\.." | Convert-Path
$BuilderPackage = Join-Path -Path $ScriptDir -ChildPath "massimodin_builder"
$BuilderExe = Join-Path -Path $ScriptDir -ChildPath "massimodin_builder.exe"
$BuildConfigPath = Join-Path -Path $ProjectDir -ChildPath "src\build_config.json"

# Use project-local Odin if available (.deps/odin/ installed by install.ps1)
# (FMOD Studio in .deps needs no PATH entry, the builder resolves it itself)
$LocalOdin = Join-Path $ProjectDir ".deps\odin"
if (Test-Path (Join-Path $LocalOdin "odin.exe")) {
    $env:PATH = "$LocalOdin;$env:PATH"
}

Write-Host "STARTING FULL BUILD RECONSTRUCTION..."

# Kill any running daemon and wait until it's actually gone so its exe isn't locked when we recompile.
# The daemon runs inside a kill-on-close job object, so its children (compilers, fmod, the game) die with it.
$daemon = Get-Process -Name massimodin_builder -ErrorAction SilentlyContinue
if ($daemon) {
    $daemon | Stop-Process -Force
    $daemon | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue
}

# When run interactively, guard against accidentally building in release mode
if (-not $release) {
    $buildConfig = Get-Content $BuildConfigPath -Raw | ConvertFrom-Json
    if (-not $buildConfig.debug) {
        $answer = Read-Host "Build config is set to release mode. Switch to debug? (y/n)"
        if ($answer -eq 'y') {
            $buildConfig.debug = $true
            $buildConfig | ConvertTo-Json | Set-Content $BuildConfigPath
            Write-Host "Config set to debug!"
        }
    }
}

# Recompile the daemon
Write-Host "Compiling builder..."
& odin build $BuilderPackage -out:$BuilderExe
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to compile builder."
    exit 1
}

Write-Host "Launching builder..."
# Launch the daemon as an independent process so this script returns immediately instead of blocking the terminal. 
# -NoNewWindow keeps it attached to the current console, so its output prints to the VS Code terminal.
# The daemon does a full rebuild, then enters watch mode and keeps running after this script exits.
Start-Process -FilePath $BuilderExe -NoNewWindow
