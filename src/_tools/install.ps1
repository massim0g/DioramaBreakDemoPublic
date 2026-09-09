# One-time third-party dependency setup for Massimodin.
# Downloads the Odin compiler and FMOD Studio to project-local directories so they don't interfere with any system-wide installs.
# Also keeps the FMOD runtime dlls in sync with the installed FMOD Studio version.
# Optionally also fetches the Steam Runtime sysroot used for linux cross-builds (about a 1.2 GB download; only needed when building the linux target).

$ErrorActionPreference = "Stop"

# PowerShell 5.1 may default to TLS 1.0, which github.com and fmod.com reject
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Versions
$ODIN_VERSION = "dev-2026-06"
$FMOD_VERSION = "2.02.35"
$STEAMRT4_SDK_TAG = "4.0.20260805.254769"

# Paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = (Resolve-Path "$ScriptDir\..\..").Path
$DepsDir = Join-Path $ProjectDir ".deps"
$OdinDir = Join-Path $DepsDir "odin"
$OdinExe = Join-Path $OdinDir "odin.exe"


# Odin compiler
function Install-Odin {
    if (Test-Path $OdinExe) {
        # If odin.exe is broken and errors out, fall through and reinstall
        $versionOutput = ""
        try { $versionOutput = & $OdinExe version | Out-String } catch {}
        if ($versionOutput -match $ODIN_VERSION) {
            Write-Host "Odin is already installed: $($versionOutput.Trim())"
            return
        }
        Write-Host "Wrong Odin version installed ($($versionOutput.Trim())), replacing with $ODIN_VERSION..."
        Remove-Item $OdinDir -Recurse -Force -Confirm:$false
    }

    $zipName = "odin-windows-$ODIN_VERSION.zip"
    $zipUrl = "https://github.com/odin-lang/Odin/releases/download/$ODIN_VERSION/$zipName"
    $zipPath = Join-Path $DepsDir $zipName

    Write-Host "Downloading Odin version $ODIN_VERSION from $zipUrl..."
    New-Item -ItemType Directory -Path $DepsDir -Force | Out-Null
    (New-Object System.Net.WebClient).DownloadFile($zipUrl, $zipPath)

    Write-Host "Extracting Odin compiler..."
    $extractTemp = Join-Path $DepsDir "odin_extract"
    if (Test-Path $extractTemp) { Remove-Item $extractTemp -Recurse -Force -Confirm:$false }
    Expand-Archive -Path $zipPath -DestinationPath $extractTemp -Force

    # The zip may contain a subdirectory (e.g. "dist") or files directly
    $innerDirs = Get-ChildItem $extractTemp -Directory
    if ($innerDirs.Count -eq 1 -and (Test-Path (Join-Path $innerDirs[0].FullName "odin.exe"))) {
        Move-Item $innerDirs[0].FullName $OdinDir
        Remove-Item $extractTemp -Recurse -Force -Confirm:$false
    } elseif (Test-Path (Join-Path $extractTemp "odin.exe")) {
        Move-Item $extractTemp $OdinDir
    } else {
        Remove-Item $zipPath -Force -Confirm:$false
        Remove-Item $extractTemp -Recurse -Force -Confirm:$false
        throw "Could not find odin.exe in extracted archive"
    }

    Remove-Item $zipPath -Force -Confirm:$false
    Write-Host "Odin successfully installed to '$OdinDir'!"
}


# FMOD download helpers
# FMOD gates downloads behind account sign-in. The login token is cached so one sign-in covers everything that needs downloading in a single run.

$script:fmodToken = $null
$script:fmodEmail = $null

# Prompts with the standard Windows credential dialog. Returns $false if the user declines.
function Request-FmodLogin {
    if ($script:fmodToken) { return $true }

    Write-Host "An fmod.com account is needed to download it (free, create one at https://www.fmod.com/profile)."
    $credential = Get-Credential -Message "Sign in with your fmod.com account"
    if (-not $credential) { return $false }

    Write-Host "Logging in to fmod.com..."
    $email = $credential.UserName
    $authBytes = [Text.Encoding]::UTF8.GetBytes("${email}:$($credential.GetNetworkCredential().Password)")
    try {
        $login = Invoke-RestMethod -Uri "https://www.fmod.com/api-login" -Method Post `
            -Headers @{ Authorization = "Basic " + [Convert]::ToBase64String($authBytes) }
    } catch {
        throw "FMOD login failed, check your email and password. ($($_.Exception.Message))"
    }
    $script:fmodToken = $login.token
    $script:fmodEmail = $email
    return $true
}

function Save-FmodDownload {
    param([string]$FileName, [string]$Destination)

    # Look the file up in the account's download list rather than guessing FMOD's file paths.
    # Every platform entry of every product version holds up to 3 download slots,
    # each a dlNPath/dlNfilename field pair.
    Write-Host "Locating $FileName..."
    $downloads = Invoke-RestMethod -Uri "https://www.fmod.com/api-downloads" `
        -Headers @{ Authorization = "FMOD $script:fmodToken" }
    $filePath = $null
    foreach ($category in $downloads.downloads.categories) {
        foreach ($product in $category.products) {
            foreach ($version in $product.versions) {
                foreach ($platform in $version.platforms) {
                    foreach ($slot in 1..3) {
                        if ($platform."dl${slot}filename" -eq $FileName) { $filePath = $platform."dl${slot}Path" }
                    }
                }
            }
        }
    }
    if (-not $filePath) {
        throw "Could not find $FileName in fmod.com's download list. Download and install it manually from https://www.fmod.com/download, then re-run this script."
    }

    $linkUri = "https://www.fmod.com/api-get-download-link" +
        "?path=" + [uri]::EscapeDataString($filePath) +
        "&filename=" + [uri]::EscapeDataString($FileName) +
        "&user=" + [uri]::EscapeDataString($script:fmodEmail)
    $link = Invoke-RestMethod -Uri $linkUri -Headers @{ Authorization = "Bearer $script:fmodToken" }

    Write-Host "Downloading $FileName..."
    (New-Object System.Net.WebClient).DownloadFile($link.url, $Destination)
}

# Runs an FMOD installer silently into a custom directory
function Invoke-FmodInstaller {
    param([string]$InstallerPath, [string]$Destination)

    # The NSIS /D= flag can't handle quoted paths, so paths with spaces are out
    if ($Destination -match ' ') {
        throw "Project path contains spaces, which the FMOD installer can't extract to. Run the installer at $InstallerPath manually, then re-run this script."
    }
    Start-Process -FilePath $InstallerPath -ArgumentList "/S", "/D=$Destination" -Wait
}


# FMOD Studio
function Install-FmodStudio {
    $studioDir = Join-Path $DepsDir "fmod_studio"
    $studioExe = Join-Path $studioDir "fmodstudio.exe"
    # fmodstudio.exe carries no version metadata, so the version is tracked with a marker file
    $versionMarker = Join-Path $studioDir "installed_version.txt"

    # Already installed in .deps?
    if ((Test-Path $studioExe) -and (Test-Path $versionMarker)) {
        if ((Get-Content $versionMarker -Raw).Trim() -eq $FMOD_VERSION) {
            Write-Host "FMOD Studio $FMOD_VERSION is already installed in .deps."
            return
        }
        Write-Host "Wrong FMOD Studio version in .deps, replacing with $FMOD_VERSION..."
    }

    # Matching version already on this machine? Install dirs are versioned, so no version check needed.
    $systemExe = "C:\Program Files\FMOD SoundSystem\FMOD Studio $FMOD_VERSION\fmodstudio.exe"
    if (Test-Path $systemExe) {
        Write-Host "FMOD Studio $FMOD_VERSION found at '$(Split-Path $systemExe)'."
        return
    }
    $pathCmd = Get-Command fmodstudio.exe -ErrorAction SilentlyContinue
    if ($pathCmd -and ((Split-Path $pathCmd.Source) -match [regex]::Escape($FMOD_VERSION))) {
        Write-Host "FMOD Studio $FMOD_VERSION found on PATH at '$($pathCmd.Source)'."
        return
    }

    if (Test-Path $studioDir) { Remove-Item $studioDir -Recurse -Force -Confirm:$false }

    Write-Host ""
    Write-Host "FMOD Studio $FMOD_VERSION is required to build audio banks, but was not found."
    if (-not (Request-FmodLogin)) {
        Write-Host "Skipped. Either re-run this script to sign in, or download and install FMOD Studio $FMOD_VERSION manually from https://www.fmod.com/download."
        $script:installIncomplete = $true
        return
    }

    $fileName = "fmodstudio$($FMOD_VERSION -replace '\.','')win64-installer.exe"
    $installerPath = Join-Path $DepsDir $fileName
    New-Item -ItemType Directory -Path $DepsDir -Force | Out-Null
    Save-FmodDownload $fileName $installerPath

    # Install into .deps so any system-wide FMOD Studio is left untouched
    Write-Host "Installing FMOD Studio to '$studioDir'..."
    Invoke-FmodInstaller $installerPath $studioDir

    if (-not (Test-Path $studioExe)) {
        throw "FMOD Studio installer ran but fmodstudio.exe was not found in $studioDir"
    }
    Set-Content -Path $versionMarker -Value $FMOD_VERSION -Encoding Ascii
    Remove-Item $installerPath -Force -Confirm:$false
    Write-Host "FMOD Studio $FMOD_VERSION installed to .deps!"
}


# FMOD runtime dlls
function Update-FmodDlls {
    # fmod.dll reports ProductVersion "2.2.35"; [version] parses "2.02.35" to the same value
    $dllVersionMatches = {
        param([string]$dllPath)
        try { ([version](Get-Item $dllPath).VersionInfo.ProductVersion) -eq [version]$FMOD_VERSION }
        catch { $false }
    }

    $releaseDllDir = Join-Path $ProjectDir "lib\_win64\_releaseOnly"
    $debugDllDir = Join-Path $ProjectDir "lib\_win64\_debugOnly"

    $upToDate = (Test-Path (Join-Path $releaseDllDir "fmod.dll")) -and
        (Test-Path (Join-Path $releaseDllDir "fmodstudio.dll")) -and
        (Test-Path (Join-Path $debugDllDir "fmodL.dll")) -and
        (Test-Path (Join-Path $debugDllDir "fmodstudioL.dll")) -and
        (& $dllVersionMatches (Join-Path $releaseDllDir "fmod.dll"))
    if ($upToDate) {
        Write-Host "FMOD runtime dlls are up to date ($FMOD_VERSION)."
        return
    }
    Write-Host "FMOD runtime dlls under lib/ don't match $FMOD_VERSION, updating..."

    # Find an FMOD Engine SDK of the right version to copy from, downloading one if needed
    $sdkRoot = $null
    $candidates = @(
        "C:\Program Files (x86)\FMOD SoundSystem\FMOD Studio API Windows",
        (Join-Path $DepsDir "fmod_engine")
    )
    foreach ($candidate in $candidates) {
        if (& $dllVersionMatches (Join-Path $candidate "api\core\lib\x64\fmod.dll")) {
            $sdkRoot = $candidate
            break
        }
    }
    if (-not $sdkRoot) {
        Write-Host ""
        Write-Host "The FMOD Engine $FMOD_VERSION SDK is needed to update the dlls."
        if (-not (Request-FmodLogin)) {
            Write-Host "Skipped. Either re-run this script to sign in, or download and install FMOD Engine $FMOD_VERSION manually from https://www.fmod.com/download."
            $script:installIncomplete = $true
            return
        }

        $fileName = "fmodstudioapi$($FMOD_VERSION -replace '\.','')win-installer.exe"
        $installerPath = Join-Path $DepsDir $fileName
        New-Item -ItemType Directory -Path $DepsDir -Force | Out-Null
        Save-FmodDownload $fileName $installerPath

        $sdkRoot = Join-Path $DepsDir "fmod_engine"
        if (Test-Path $sdkRoot) { Remove-Item $sdkRoot -Recurse -Force -Confirm:$false }
        Write-Host "Installing FMOD Engine to '$sdkRoot'..."
        Invoke-FmodInstaller $installerPath $sdkRoot

        if (-not (Test-Path (Join-Path $sdkRoot "api\core\lib\x64\fmod.dll"))) {
            throw "FMOD Engine installer ran but the SDK was not found in $sdkRoot"
        }
        Remove-Item $installerPath -Force -Confirm:$false
    }

    Write-Host "Copying FMOD runtime dlls from '$sdkRoot'..."
    Copy-Item (Join-Path $sdkRoot "api\core\lib\x64\fmod.dll") $releaseDllDir -Force
    Copy-Item (Join-Path $sdkRoot "api\studio\lib\x64\fmodstudio.dll") $releaseDllDir -Force
    Copy-Item (Join-Path $sdkRoot "api\core\lib\x64\fmodL.dll") $debugDllDir -Force
    Copy-Item (Join-Path $sdkRoot "api\studio\lib\x64\fmodstudioL.dll") $debugDllDir -Force
    Write-Host "FMOD runtime dlls updated to $FMOD_VERSION!"
}


# Steam Runtime sysroot for linux cross-builds
# The linux binaries are linked against the Steam Runtime 4 ("steamrt4") libraries so they run on everything Steam runs on.
# The sysroot arrives as a prebaked sysroot.zip: downloaded from the public repo's linux-build-deps release,
# or produced from the steamrt SDK image by build_tools/release/generate_linux_build_deps.ps1 on machines that have it.

# Reads the steamrt tag baked into a sysroot.zip without extracting it.
function Get-SysrootZipVersion {
    param([string]$ZipPath)

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $entry = $zip.GetEntry("installed_version.txt")
        if (-not $entry) { return "" }
        $reader = New-Object IO.StreamReader($entry.Open())
        try { return $reader.ReadToEnd().Trim() } finally { $reader.Dispose() }
    } finally { $zip.Dispose() }
}

function Install-Steamrt4Sysroot {
    $dest = Join-Path $DepsDir "steamrt4_sysroot"
    # The steamrt tag is tracked with a marker file (baked into the zip), same idea as FMOD Studio
    $versionMarker = Join-Path $dest "installed_version.txt"
    if ((Test-Path $versionMarker) -and (Get-Content $versionMarker -Raw).Trim() -eq $STEAMRT4_SDK_TAG) {
        Write-Host "Steam Runtime 4 sysroot ($STEAMRT4_SDK_TAG) is already installed in '$dest'."
        return
    }
    if (Test-Path $dest) {
        Write-Host "Incorrect Steam Runtime sysroot version in .deps, replacing with $STEAMRT4_SDK_TAG..."
        Remove-Item $dest -Recurse -Force -Confirm:$false
    }

    # Find a steamrt4_sysroot.zip of the right version: a local copy, then generating one, then downloading one
    $buildToolsDir = Join-Path $ScriptDir "build_tools"
    $zipPath = Join-Path $buildToolsDir "steamrt4_sysroot.zip"
    if ((Test-Path $zipPath) -and (Get-SysrootZipVersion $zipPath) -ne $STEAMRT4_SDK_TAG) {
        Write-Host "The local steamrt4_sysroot.zip has the wrong version, discarding it."
        Remove-Item $zipPath -Force -Confirm:$false
    }
    if (-not (Test-Path $zipPath)) {
        $generateScript = Join-Path $buildToolsDir "release\generate_linux_build_deps.ps1"
        if (Test-Path $generateScript) {
            & $generateScript
        } else {
            $url = "https://github.com/massim0g/DioramaBreakDemoPublic/releases/latest/download/steamrt4_sysroot_$STEAMRT4_SDK_TAG.zip"
            Write-Host "Downloading the prebaked sysroot from $url (about 700 MB)..."
            (New-Object System.Net.WebClient).DownloadFile($url, $zipPath)
        }
        if ((Get-SysrootZipVersion $zipPath) -ne $STEAMRT4_SDK_TAG) {
            throw "steamrt4_sysroot.zip does not carry the expected steamrt tag $STEAMRT4_SDK_TAG"
        }
    }

    # Extract into a scratch directory and only move into place once complete, so an interrupted
    # run never leaves a half-populated sysroot behind.
    Write-Host "Extracting the sysroot (about 2.7 GB)..."
    $scratch = "$dest.incomplete"
    if (Test-Path $scratch) { Remove-Item $scratch -Recurse -Force -Confirm:$false }
    Expand-Archive -Path $zipPath -DestinationPath $scratch
    Move-Item $scratch $dest

    Write-Host "Steam Runtime 4 sysroot installed to '$dest'."
}


# Run

Write-Host "INSTALLING MASSIMODIN GAME ENGINE DEPENDENCIES..."
Write-Host ""

$script:installIncomplete = $false

Install-Odin
Write-Host ""
Install-FmodStudio
Write-Host ""
Update-FmodDlls
Write-Host ""

# Junction so dialogue files can reference portrait sprites relatively
$portraitsLink = Join-Path $ProjectDir "dialogues\portraits"
if (-not (Test-Path $portraitsLink)) {
    New-Item -ItemType Junction -Path $portraitsLink -Target (Join-Path $ProjectDir "sprites\portraits") | Out-Null
    Write-Host "Created junction dialogues\portraits -> sprites\portraits"
}

Write-Host ""
if ($script:installIncomplete) {
    Write-Host "Some dependencies still need manual steps, see the messages above."
    exit 1
}
Write-Host "INSTALL COMPLETE!"
Write-Host "Launch the builder daemon using src\_tools\build_tools\relaunch_builder.ps1"
Write-Host ""

if((Read-Host "Would you also like to install linux build dependencies (y/n)?") -eq "y"){
    Install-Steamrt4Sysroot
    Write-Host ""
    Write-Host "LINUX BUILD DEPENDENCIES INSTALLED!"
}
