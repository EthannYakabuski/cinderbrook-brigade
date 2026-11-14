param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [string]$Python = 'python',
    [ValidateSet('Web','Android','Android Test APK')][string]$Target = 'Web',
    [string]$AndroidTemplate
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$buildRoot = Join-Path $projectRoot 'build'
$logRoot = Join-Path $buildRoot 'logs'
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) { throw 'Pass -Godot with the installed Godot 4.5.1 executable.' }

function Invoke-OwnedGodot([string[]]$Arguments, [string]$Label) {
    # ArgumentList avoids shell interpolation and Windows quote reconstruction.
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = [IO.Path]::GetFullPath($Godot)
    $start.WorkingDirectory = $projectRoot
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
    $taskProcess = [Diagnostics.Process]::new()
    $taskProcess.StartInfo = $start
    if (-not $taskProcess.Start()) { throw "Could not start Godot $Label." }
    $stdoutTask = $taskProcess.StandardOutput.ReadToEndAsync()
    $stderrTask = $taskProcess.StandardError.ReadToEndAsync()
    @{pid=$taskProcess.Id; arguments=$Arguments; started_utc=[DateTime]::UtcNow.ToString('o')} |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $logRoot "$Label-process.json") -Encoding utf8
    while (-not $taskProcess.WaitForExit(55000)) { Write-Output "Godot $Label is running (owned PID $($taskProcess.Id))." }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    [IO.File]::WriteAllText((Join-Path $logRoot "$Label.stdout.log"), $stdout)
    [IO.File]::WriteAllText((Join-Path $logRoot "$Label.stderr.log"), $stderr)
    $code = $taskProcess.ExitCode
    $taskProcess.Dispose()
    if ($code -ne 0) { throw "Godot $Label failed with exit code $code. See build/logs/." }
    $diagnostics = ($stdout + "`n" + $stderr) -split "`r?`n" | Where-Object {
        $_ -match 'SCRIPT ERROR|Parse Error|Assertion failed|^ERROR:|ObjectDB instances leaked|resources still in use at exit|Pages in use exist at exit' -and
        $_.Trim() -ne 'ERROR: Failed to read the root certificate store.'
    }
    if ($diagnostics) { throw "Godot $Label emitted an error despite exit code zero: $($diagnostics -join ' | ')" }
}

Push-Location $projectRoot
try {
    New-Item -ItemType Directory -Path $logRoot,(Join-Path $buildRoot 'android'),(Join-Path $buildRoot 'site/play') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $buildRoot '.gdignore'), '')
    Invoke-OwnedGodot @('--headless','--editor','--path',$projectRoot,'--import','--quit') 'import'
    if ($Target -eq 'Web') {
        $output = Join-Path $buildRoot 'site/play/index.html'
        Invoke-OwnedGodot @('--headless','--path',$projectRoot,'--export-release','Web',$output) 'export-web'
        & $Python tools/verify_web_export.py build/site/play --output build/web-export-validation.json
        if ($LASTEXITCODE -ne 0) { throw 'Exported Web byte validation failed.' }
    } else {
        if (-not $AndroidTemplate) {
            if (-not $env:APPDATA) { throw 'Pass -AndroidTemplate with the installed Godot android_source.zip.' }
            $AndroidTemplate = Join-Path $env:APPDATA 'Godot/export_templates/4.5.1.stable/android_source.zip'
        }
        & $Python platform/prepare_android.py --template $AndroidTemplate
        if ($LASTEXITCODE -ne 0) { throw 'Android source-template preparation failed.' }
        $filename = if ($Target -eq 'Android') { 'cinderbrook-brigade-debug.aab' } else { 'cinderbrook-brigade-test.apk' }
        $output = Join-Path $buildRoot "android/$filename"
        Invoke-OwnedGodot @('--headless','--path',$projectRoot,'--export-debug',$Target,$output) ($Target.Replace(' ','-'))
        if (-not (Test-Path -LiteralPath $output -PathType Leaf)) { throw 'Godot exited without the requested Android artifact.' }
        & $Python platform/tests/validate_platform.py --artifact $output
        if ($LASTEXITCODE -ne 0) { throw 'Android configuration/native-package validation failed.' }
        & $Python tools/verify_native_alignment.py $output --output "build/android/$filename-alignment.json"
        if ($LASTEXITCODE -ne 0) { throw 'Native 64-bit ELF alignment validation failed.' }
    }
    Get-FileHash -LiteralPath $output -Algorithm SHA256
} finally { Pop-Location }
