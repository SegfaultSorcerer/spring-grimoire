# PostToolUse hook: Auto-compile after Java file changes.
# Requires enable flag: .spring-grimoire/auto-compile.enabled

$ErrorActionPreference = "Stop"

$input_json = [Console]::In.ReadToEnd() | ConvertFrom-Json
$filePath = $input_json.tool_input.file_path

if (-not $filePath) { exit 0 }
if ($filePath -notlike "*.java") { exit 0 }

$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { "." }
$flagFile = Join-Path $projectDir ".spring-grimoire" "auto-compile.enabled"

if (-not (Test-Path $flagFile)) { exit 0 }

Push-Location $projectDir

try {
    if (Test-Path "pom.xml") {
        $output = & mvn compile -q -T 1C 2>&1 | Select-Object -Last 30
        if ($LASTEXITCODE -ne 0) {
            [Console]::Error.WriteLine("Compilation failed:")
            [Console]::Error.WriteLine($output -join "`n")
            exit 2
        }
    } elseif ((Test-Path "build.gradle") -or (Test-Path "build.gradle.kts")) {
        $gradleCmd = if (Test-Path ".\gradlew.bat") { ".\gradlew.bat" } else { "gradle" }
        $output = & $gradleCmd compileJava -q 2>&1 | Select-Object -Last 30
        if ($LASTEXITCODE -ne 0) {
            [Console]::Error.WriteLine("Compilation failed:")
            [Console]::Error.WriteLine($output -join "`n")
            exit 2
        }
    } else {
        exit 0
    }

    Write-Output '{"systemMessage": "Compilation successful"}'
} finally {
    Pop-Location
}

exit 0
