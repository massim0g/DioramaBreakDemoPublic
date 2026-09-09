# Zips all non-gitignored repo files to F:\misc_backups\DioramaBreak, then prunes old backups.
# Triggered by the pre-push / post-merge / post-rewrite git hooks; safe to run manually too.

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$backupDir = "F:\misc_backups\DioramaBreak"
$keepCount = 5

if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Force $backupDir | Out-Null }

$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$today = Get-Date -Format "yyyy-MM-dd"
$zipName = "DioramaBreak_$stamp.zip"
$tmpPath = Join-Path $backupDir "$zipName.$PID.tmp"

# Zip via cmd so the NUL-separated file list pipes as raw bytes; System32 tar is bsdtar, which can write zips.
# -co = tracked + untracked, --exclude-standard drops gitignored files.
$tar = "$env:SystemRoot\System32\tar.exe"
Set-Location $repoRoot
cmd /c "git -c core.quotepath=false ls-files -coz --exclude-standard | `"$tar`" --null --format zip -cf `"$tmpPath`" -T -"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $tmpPath)) {
	if (Test-Path $tmpPath) { Remove-Item -Force $tmpPath }
	exit 1
}
# Serialize rename+prune across concurrent runs: without this, two finishing runs can each see the other as a same-day duplicate and mutually delete, leaving no backup from today.
# Zipping itself is safe to overlap (read-only, PID-unique tmp names).
# An abandoned mutex (a previous run killed mid-prune) still counts as acquired.
$mutex = New-Object System.Threading.Mutex($false, "DioramaBreakRepoBackup")
try { if (-not $mutex.WaitOne(60000)) { Remove-Item -Force $tmpPath; exit 1 } } catch [System.Threading.AbandonedMutexException] {}
try {
	# A run started the same second may have already produced this exact name; ours is then redundant.
	if (Test-Path (Join-Path $backupDir $zipName)) {
		Remove-Item -Force $tmpPath
	} else {
		Rename-Item $tmpPath $zipName
	}

	# Prune: stale tmps from killed runs, then any other backups from today, then oldest until only $keepCount remain.
	Get-ChildItem $backupDir -Filter "*.tmp" |
		Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-1) } |
		Remove-Item -Force
	Get-ChildItem $backupDir -Filter "DioramaBreak_*.zip" |
		Where-Object { $_.Name -like "DioramaBreak_$today*" -and $_.Name -ne $zipName } |
		Remove-Item -Force
	$backups = @(Get-ChildItem $backupDir -Filter "DioramaBreak_*.zip" | Sort-Object Name)
	if ($backups.Count -gt $keepCount) {
		$backups | Select-Object -First ($backups.Count - $keepCount) | Remove-Item -Force
	}
} finally { $mutex.ReleaseMutex() }
