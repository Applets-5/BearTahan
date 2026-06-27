param(
    [switch]$BuildApk
)

$ErrorActionPreference = "Stop"

function Run-Step {
    param(
        [string]$Name,
        [string[]]$Command
    )

    Write-Host ""
    Write-Host "==> $Name" -ForegroundColor Cyan
    $executable = $Command[0]
    $arguments = @()
    if ($Command.Length -gt 1) {
        $arguments = $Command[1..($Command.Length - 1)]
    }
    & $executable @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

function Run-Format-Check {
    Write-Host ""
    Write-Host "==> Check formatting" -ForegroundColor Cyan

    $dartFiles = git ls-files "*.dart"
    if (-not $dartFiles) {
        Write-Host "No tracked Dart files found."
        return
    }

    & dart format --output=none --set-exit-if-changed @dartFiles
    if ($LASTEXITCODE -ne 0) {
        throw "Check formatting failed with exit code $LASTEXITCODE"
    }
}

Run-Step "Install dependencies" @("flutter", "pub", "get")
Run-Format-Check
if (Test-Path "functions/index.js") {
    Run-Step "Check Firebase Functions syntax" @("node", "--check", "functions/index.js")
}
Run-Step "Analyze" @("flutter", "analyze", "--no-pub")
Run-Step "Test" @("flutter", "test", "--no-pub")

if ($BuildApk) {
    Run-Step "Build Android debug APK" @("flutter", "build", "apk", "--debug", "--no-pub")
}

Write-Host ""
Write-Host "Verification completed." -ForegroundColor Green
