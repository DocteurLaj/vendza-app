param(
  [int]$TimeoutMinutes = 15,
  [string]$ApiBaseUrl = "https://api.example.com",
  [string]$GoogleWebClientId = "000000000000-valid.apps.googleusercontent.com"
)

$ErrorActionPreference = "Stop"

function Stop-ProcessTree {
  param([int]$RootProcessId)

  & taskkill.exe /PID $RootProcessId /T /F | Out-Host
}

function Invoke-WithTimeout {
  param(
    [string]$FilePath,
    [string[]]$Arguments,
    [int]$TimeoutSeconds
  )

  $commandLine = "$FilePath $($Arguments -join ' ')"
  Write-Host "Running: $commandLine"

  $process = Start-Process `
    -FilePath $FilePath `
    -ArgumentList $Arguments `
    -NoNewWindow `
    -PassThru `
    -Wait:$false

  $finished = $process.WaitForExit($TimeoutSeconds * 1000)
  if (-not $finished) {
    Stop-ProcessTree -RootProcessId $process.Id
    throw "Timed out after $TimeoutSeconds seconds: $commandLine"
  }

  if ($process.ExitCode -ne 0) {
    throw "Command failed with exit code $($process.ExitCode): $commandLine"
  }
}

$timeoutSeconds = $TimeoutMinutes * 60

Invoke-WithTimeout -FilePath "flutter" -Arguments @("pub", "get") -TimeoutSeconds $timeoutSeconds

Invoke-WithTimeout `
  -FilePath "flutter" `
  -Arguments @(
    "build",
    "web",
    "--release",
    "--dart-define=VENDZA_API_BASE_URL=$ApiBaseUrl",
    "--dart-define=GOOGLE_WEB_CLIENT_ID=$GoogleWebClientId"
  ) `
  -TimeoutSeconds $timeoutSeconds

Write-Host "Web validation completed."
