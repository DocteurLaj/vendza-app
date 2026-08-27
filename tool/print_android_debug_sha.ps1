# Prints the debug keystore SHA-1 / SHA-256 for Google Cloud Android OAuth.
# Package / applicationId: app.vendza.marketplace
#
# Usage (PowerShell):
#   .\tool\print_android_debug_sha.ps1

$ErrorActionPreference = 'Stop'

$keystore = Join-Path $env:USERPROFILE '.android\debug.keystore'
if (-not (Test-Path $keystore)) {
  Write-Error "Debug keystore not found: $keystore"
}

$ktCandidates = @(
  (Join-Path ${env:ProgramFiles} 'Android\Android Studio\jbr\bin\keytool.exe'),
  (Join-Path $env:LOCALAPPDATA 'Android\Sdk\jbr\bin\keytool.exe')
)
if ($env:JAVA_HOME) {
  $ktCandidates = @((Join-Path $env:JAVA_HOME 'bin\keytool.exe')) + $ktCandidates
}

$keytool = $ktCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $keytool) {
  Write-Error 'keytool.exe not found. Install Android Studio JBR or set JAVA_HOME.'
}

Write-Host 'Package: app.vendza.marketplace'
Write-Host "Keystore: $keystore"
Write-Host "keytool: $keytool"
Write-Host ''

& $keytool -list -v -alias androiddebugkey -keystore $keystore -storepass android -keypass android |
  Select-String -Pattern 'SHA|Empreinte|Fingerprint|Alias' |
  ForEach-Object { $_.Line.Trim() }

Write-Host ''
Write-Host 'Register BOTH SHA-1 and SHA-256 on the Android OAuth client in the'
Write-Host 'same Google Cloud project as the Web client (GOOGLE_WEB_CLIENT_ID).'
Write-Host 'See docs/GOOGLE_SIGN_IN.md'
