# PostToolUse hook: Run Checkstyle after Java file edits.
# Requires enable flag: .spring-grimoire/checkstyle.enabled

$ErrorActionPreference = "Stop"

$input_json = [Console]::In.ReadToEnd() | ConvertFrom-Json
$filePath = $input_json.tool_input.file_path

if (-not $filePath) { exit 0 }
if ($filePath -notlike "*.java") { exit 0 }

$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { "." }
$flagFile = Join-Path $projectDir ".spring-grimoire" "checkstyle.enabled"

if (-not (Test-Path $flagFile)) { exit 0 }

Push-Location $projectDir

try {
    if (Test-Path "pom.xml") {
        $output = & mvn checkstyle:check -q 2>&1 | Select-Object -Last 30
        if ($LASTEXITCODE -ne 0) {
            [Console]::Error.WriteLine("Checkstyle violations found:")
            [Console]::Error.WriteLine($output -join "`n")
            exit 2
        }
    } elseif ((Test-Path "build.gradle") -or (Test-Path "build.gradle.kts")) {
        $gradleCmd = if (Test-Path ".\gradlew.bat") { ".\gradlew.bat" } else { "gradle" }
        $output = & $gradleCmd checkstyleMain -q 2>&1 | Select-Object -Last 30
        if ($LASTEXITCODE -ne 0) {
            [Console]::Error.WriteLine("Checkstyle violations found:")
            [Console]::Error.WriteLine($output -join "`n")
            exit 2
        }
    } else {
        exit 0
    }

    # Optional: SpotBugs
    $spotbugsFlag = Join-Path $projectDir ".spring-grimoire" "spotbugs.enabled"
    if (Test-Path $spotbugsFlag) {
        if (Test-Path "pom.xml") {
            $output = & mvn spotbugs:check -q 2>&1 | Select-Object -Last 30
        } else {
            $output = & $gradleCmd spotbugsMain -q 2>&1 | Select-Object -Last 30
        }
        if ($LASTEXITCODE -ne 0) {
            [Console]::Error.WriteLine("SpotBugs issues found:")
            [Console]::Error.WriteLine($output -join "`n")
            exit 2
        }
    }
} finally {
    Pop-Location
}

exit 0
