param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('ANDROID_KEYSTORE_BASE64', 'ANDROID_KEYSTORE_PASSWORD', 'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD')]
    [string]$Name
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$settings = @{}
foreach ($line in Get-Content -LiteralPath (Join-Path $projectRoot 'android/key.properties') -Encoding utf8) {
    if ($line -match '^\s*[#!]' -or [string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line -split '=', 2
    $settings[$parts[0].Trim()] = [regex]::Replace($parts[1], '\\(.)', {
        param($match)
        switch ($match.Groups[1].Value) {
            'n' { "`n" }
            'r' { "`r" }
            't' { "`t" }
            default { $match.Groups[1].Value }
        }
    })
}

$value = switch ($Name) {
    'ANDROID_KEYSTORE_BASE64' {
        $keyFile = [IO.Path]::GetFullPath((Join-Path (Join-Path $projectRoot 'android') $settings['storeFile']))
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($keyFile))
    }
    'ANDROID_KEYSTORE_PASSWORD' { $settings['storePassword'] }
    'ANDROID_KEY_ALIAS' { $settings['keyAlias'] }
    'ANDROID_KEY_PASSWORD' { $settings['keyPassword'] }
}
if ([string]::IsNullOrEmpty($value)) { throw '签名配置缺失，请先配置 android/key.properties' }
Set-Clipboard -Value $value
Write-Output "已复制 $Name，请粘贴到 GitHub 对应的 Actions Secret；未打印凭据。"
