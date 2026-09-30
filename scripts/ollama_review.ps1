param(
  [string]$Model = "qwen2.5-coder:7b",
  [string]$Repo = (Get-Location).Path,
  [string]$Prompt = "Audit this Flutter/Android repository for the next España Outdoor milestone. Prioritize build stability, PMTiles/offline maps, Valhalla routing, security/privacy, tests and release readiness. Do not invent files or dependencies. Return concrete findings with file paths and severity."
)

$ErrorActionPreference = "Stop"
$ollama = "http://127.0.0.1:11434/api/generate"

if (-not (Test-Path $Repo)) { throw "Repository not found: $Repo" }

$files = Get-ChildItem -Path $Repo -Recurse -File |
  Where-Object {
    $_.FullName -notmatch '\\.git\\|\\build\\|\\.dart_tool\\|\\node_modules\\|\\android\\\.gradle\\|\\data\\.*\\.pmtiles$' -and
    $_.Extension -in '.dart','.yaml','.yml','.md','.json','.toml','.sh','.ps1','.gradle','.properties'
  } |
  Select-Object -First 80

$parts = New-Object System.Collections.Generic.List[string]
foreach ($file in $files) {
  try {
    $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop
    if ($text.Length -gt 20000) { $text = $text.Substring(0,20000) }
    $relative = $file.FullName.Substring($Repo.Length).TrimStart('\','/')
    [void]$parts.Add("`n===== $relative =====`n$text")
  } catch { }
}

$fullPrompt = @"
You are the local senior code-review assistant for España Outdoor.

$Prompt

Repository snapshot:
$($parts -join "`n")

Rules:
1. Work only from the supplied repository snapshot.
2. Do not claim a test/build passed unless evidence is present.
3. Separate confirmed defects from recommendations.
4. Give the smallest safe next changes first.
5. Keep Android as MVP priority; do not prioritize iOS.
"@

$body = @{
  model = $Model
  prompt = $fullPrompt
  stream = $false
  options = @{ temperature = 0.1 }
} | ConvertTo-Json -Depth 8

$response = Invoke-RestMethod -Uri $ollama -Method Post -ContentType 'application/json' -Body $body
$response.response | Set-Content -LiteralPath (Join-Path $Repo 'ollama-review.md') -Encoding UTF8
Write-Host "Ollama review written to ollama-review.md using $Model"
