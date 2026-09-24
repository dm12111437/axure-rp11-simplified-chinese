param(
    [string]$AxureRoot = ""
)

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$SourceFile = Join-Path $RootDir "lang\default"

if (!(Test-Path $SourceFile)) {
    throw "Source language file not found: $SourceFile"
}

if ([string]::IsNullOrWhiteSpace($AxureRoot)) {
    $Candidates = @(
        "C:\Program Files (x86)\Axure\Axure RP 11",
        "C:\Program Files\Axure\Axure RP 11"
    )

    # Prefer a directory that really contains the Axure RP 11 executable.
    foreach ($Candidate in $Candidates) {
        if (Test-Path (Join-Path $Candidate "AxureRP11.exe")) {
            $AxureRoot = $Candidate
            break
        }
    }

    # Fall back to any existing candidate directory.
    if ([string]::IsNullOrWhiteSpace($AxureRoot)) {
        foreach ($Candidate in $Candidates) {
            if (Test-Path $Candidate) {
                $AxureRoot = $Candidate
                break
            }
        }
    }
}

if ([string]::IsNullOrWhiteSpace($AxureRoot)) {
    throw "Axure RP 11 installation directory was not found. Please pass -AxureRoot explicitly."
}

$TargetDir = Join-Path $AxureRoot "lang"
$TargetFile = Join-Path $TargetDir "default"

# Fresh Axure RP 11 installs no longer ship a "lang" directory,
# so create it when it is missing instead of aborting.
if (!(Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Write-Host "Created language directory: $TargetDir"
}

if (Test-Path $TargetFile) {
    $BackupFile = "$TargetFile.bak"
    if (!(Test-Path $BackupFile)) {
        Copy-Item $TargetFile $BackupFile -Force
        Write-Host "Backed up existing language file to: $BackupFile"
    }
    else {
        Write-Host "Backup already exists, left untouched: $BackupFile"
    }
}
else {
    Write-Host "No existing language file found; performing a fresh install."
}

Copy-Item $SourceFile $TargetFile -Force

$SourceHash = (Get-FileHash $SourceFile -Algorithm SHA256).Hash
$TargetHash = (Get-FileHash $TargetFile -Algorithm SHA256).Hash

if ($SourceHash -ne $TargetHash) {
    throw "Verification failed: installed file hash does not match the source language file."
}

Write-Host "Installation completed: $TargetFile"
Write-Host "SHA256: $TargetHash"
Write-Host "Please fully quit Axure RP 11 and reopen it."
