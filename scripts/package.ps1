# 按环境注入变量后打包。
# 用法:
#   .\scripts\package.ps1
#   .\scripts\package.ps1 -Env staging -Target apk
#   .\scripts\package.ps1 -Env prod -Target windows

[CmdletBinding()]
param(
    [string]$Env = 'prod',
    [ValidateSet('apk', 'appbundle', 'windows', 'web')]
    [string]$Target = 'apk'
)

$ErrorActionPreference = 'Stop'

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = Split-Path -Parent $scriptDir
Set-Location $root

function Resolve-AppEnv([string]$name) {
    switch ($name.Trim().ToLowerInvariant()) {
        { $_ -in @('dev', 'development') } {
            return [pscustomobject]@{
                Key   = 'dev'
                File  = 'env/development.env'
                Label = '开发'
            }
        }
        { $_ -in @('staging', 'test', 'qa') } {
            return [pscustomobject]@{
                Key   = 'staging'
                File  = 'env/staging.env'
                Label = '测试'
            }
        }
        { $_ -in @('prod', 'production') } {
            return [pscustomobject]@{
                Key   = 'prod'
                File  = 'env/production.env'
                Label = '生产'
            }
        }
        default {
            throw "未知环境: $name，请使用 dev / staging / prod"
        }
    }
}

function Find-Flutter {
    $cmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $localProps = Join-Path $root 'android/local.properties'
    if (Test-Path $localProps) {
        foreach ($line in Get-Content $localProps) {
            if ($line -match '^\s*flutter\.sdk=(.+)$') {
                $sdk = $Matches[1].Trim().Replace('\\', '\').TrimEnd('\')
                $bat = Join-Path $sdk 'bin/flutter.bat'
                if (Test-Path $bat) {
                    return $bat
                }
            }
        }
    }

    foreach ($candidate in @(
            'D:\sdk\flutter\bin\flutter.bat',
            (Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'),
            'C:\flutter\bin\flutter.bat'
        )) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw '找不到 flutter，请将 Flutter SDK 加入 PATH'
}

function Read-PubspecVersion {
    $text = Get-Content (Join-Path $root 'pubspec.yaml') -Raw
    if ($text -match '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
        return $Matches[1]
    }
    return '0.0.0'
}

function Invoke-Flutter([string]$flutter, [string[]]$FlutterArgs) {
    Write-Host ("flutter " + ($FlutterArgs -join ' '))
    & $flutter @FlutterArgs
    if ($LASTEXITCODE -ne 0) {
        throw "flutter 退出码 $LASTEXITCODE"
    }
}

$appEnv = Resolve-AppEnv $Env
$envFile = Join-Path $root $appEnv.File
if (-not (Test-Path $envFile)) {
    throw "缺少环境配置文件: $($appEnv.File)"
}

$flutter = Find-Flutter
$version = Read-PubspecVersion
$defineArg = "--dart-define-from-file=$($appEnv.File)"
$releaseDir = Join-Path $root 'release'
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

Write-Host "打包 $($appEnv.Label)环境 ($($appEnv.Key)) → $Target"
Write-Host "环境文件 $($appEnv.File)"

switch ($Target) {
    'apk' {
        Invoke-Flutter $flutter @('build', 'apk', '--release', $defineArg)
        $src = Join-Path $root 'build/app/outputs/flutter-apk/app-release.apk'
        if (-not (Test-Path $src)) {
            throw "未找到 APK: $src"
        }
        $dest = Join-Path $releaseDir "dimension-link-$version-$($appEnv.Key).apk"
        Copy-Item $src $dest -Force
        Write-Host "产物: $dest"
    }
    'appbundle' {
        Invoke-Flutter $flutter @('build', 'appbundle', '--release', $defineArg)
        $src = Join-Path $root 'build/app/outputs/bundle/release/app-release.aab'
        if (-not (Test-Path $src)) {
            throw "未找到 App Bundle: $src"
        }
        $dest = Join-Path $releaseDir "dimension-link-$version-$($appEnv.Key).aab"
        Copy-Item $src $dest -Force
        Write-Host "产物: $dest"
    }
    'windows' {
        Invoke-Flutter $flutter @('build', 'windows', '--release', $defineArg)
        $src = Join-Path $root 'build/windows/x64/runner/Release'
        if (-not (Test-Path $src)) {
            throw "未找到 Windows 产物: $src"
        }
        $dest = Join-Path $releaseDir "dimension-link-$version-$($appEnv.Key)-windows"
        if (Test-Path $dest) {
            Remove-Item $dest -Recurse -Force
        }
        Copy-Item $src $dest -Recurse -Force
        Write-Host "产物: $dest"
    }
    'web' {
        Invoke-Flutter $flutter @('build', 'web', '--release', $defineArg)
        $src = Join-Path $root 'build/web'
        if (-not (Test-Path $src)) {
            throw "未找到 Web 产物: $src"
        }
        $dest = Join-Path $releaseDir "dimension-link-$version-$($appEnv.Key)-web"
        if (Test-Path $dest) {
            Remove-Item $dest -Recurse -Force
        }
        Copy-Item $src $dest -Recurse -Force
        Write-Host "产物: $dest"
    }
}
