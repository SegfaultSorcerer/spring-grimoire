# PreToolUse hook: Block writes to production configuration files.
# Always active — no enable flag required. This is a safety measure.

$ErrorActionPreference = "Stop"

$input_json = [Console]::In.ReadToEnd() | ConvertFrom-Json
$filePath = $input_json.tool_input.file_path

if (-not $filePath) { exit 0 }

$basename = Split-Path $filePath -Leaf

if ($basename -match '^application-prod\..+' -or
    $basename -match '^application-production\..+' -or
    $basename -match '^bootstrap-prod\..+') {
    [Console]::Error.WriteLine("Blocked: Production configuration file '$basename' must not be modified by AI. Edit this file manually.")
    exit 2
}

exit 0
