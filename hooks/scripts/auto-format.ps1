# PostToolUse hook: Auto-format Java files with google-java-format.
# Requires enable flag: .spring-grimoire/auto-format.enabled

$ErrorActionPreference = "Stop"

$input_json = $input | ConvertFrom-Json
$filePath = $input_json.tool_input.file_path

if (-not $filePath) { exit 0 }
if ($filePath -notlike "*.java") { exit 0 }

$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { "." }
$flagFile = Join-Path $projectDir ".spring-grimoire" "auto-format.enabled"

if (-not (Test-Path $flagFile)) { exit 0 }
if (-not (Test-Path $filePath)) { exit 0 }

# Find google-java-format
$gjf = Get-Command google-java-format -ErrorAction SilentlyContinue
$gjfJar = Join-Path $env:USERPROFILE ".local" "share" "google-java-format" "google-java-format.jar"

if ($gjf) {
    & google-java-format --replace $filePath 2>$null
    if ($LASTEXITCODE -eq 0) {
        $name = Split-Path $filePath -Leaf
        Write-Output "{`"systemMessage`": `"Auto-formatted $name with google-java-format`"}"
    }
} elseif (Test-Path $gjfJar) {
    & java -jar $gjfJar --replace $filePath 2>$null
    if ($LASTEXITCODE -eq 0) {
        $name = Split-Path $filePath -Leaf
        Write-Output "{`"systemMessage`": `"Auto-formatted $name with google-java-format`"}"
    }
}

exit 0
