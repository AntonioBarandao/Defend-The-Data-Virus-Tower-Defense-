param(
    [string]$GuardianSourceDirectory = "C:\Users\jonhu\Downloads\Cyber Guardian",
    [string]$SfxSourceDirectory = "C:\Users\jonhu\Downloads\sfx",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$firewallRoot = Join-Path $ProjectDirectory "assets\Towers\CyberGuardian\Modes\Firewall"
$burnRoot = Join-Path $ProjectDirectory "assets\Effects\FirewallBurn"
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
    "defend-the-data-firewall-" + [guid]::NewGuid().ToString("N")
)

$animations = @(
    @{
        Source = Join-Path $GuardianSourceDirectory "Cyberguardian_Firewall_Idle.mp4"
        OutputDirectory = Join-Path $firewallRoot "Idle"
        BaseName = "Cyberguardian_Firewall_Idle_atlas_24fps"
        FrameSize = 720
        KeyColor = "0x25CF3D"
        Similarity = "0.22"
        Blend = "0.08"
        Despill = $true
    },
    @{
        Source = Join-Path $GuardianSourceDirectory "Cyberguardian_Firewall_Declare.mp4"
        OutputDirectory = Join-Path $firewallRoot "Declare"
        BaseName = "Cyberguardian_Firewall_Declare_atlas_24fps"
        FrameSize = 720
        KeyColor = "0x25CF3D"
        Similarity = "0.22"
        Blend = "0.08"
        Despill = $true
    },
    @{
        Source = Join-Path $GuardianSourceDirectory "Cyberguardian_Firewall_Active.mp4"
        OutputDirectory = Join-Path $firewallRoot "Active"
        BaseName = "Cyberguardian_Firewall_Active_atlas_24fps"
        FrameSize = 720
        KeyColor = "0x3EB24E"
        Similarity = "0.12"
        Blend = "0.06"
        Despill = $false
    },
    @{
        Source = Join-Path $SfxSourceDirectory "Fire_VFX_2.mp4"
        OutputDirectory = $burnRoot
        BaseName = "Fire_VFX_2_atlas_24fps"
        FrameSize = 320
        KeyColor = "0x15D839"
        Similarity = "0.22"
        Blend = "0.08"
        Despill = $true
    }
)

function Invoke-CheckedFfmpeg {
    param([string[]]$Arguments, [string]$FailureMessage)

    & $ffmpeg @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw $FailureMessage
    }
}

function Build-AnimationAtlas {
    param([hashtable]$Definition)

    if (-not (Test-Path -LiteralPath $Definition.Source)) {
        throw "Missing source media: $($Definition.Source)"
    }
    New-Item -ItemType Directory -Path $Definition.OutputDirectory -Force |
        Out-Null

    $frameDirectory = Join-Path $temporaryRoot $Definition.BaseName
    New-Item -ItemType Directory -Path $frameDirectory -Force | Out-Null
    $framePattern = Join-Path $frameDirectory "frame_%04d.png"
    $filter = (
        "fps=24," +
        "scale=$($Definition.FrameSize):$($Definition.FrameSize):flags=lanczos," +
        "format=rgba," +
        "colorkey=$($Definition.KeyColor):$($Definition.Similarity):$($Definition.Blend)"
    )
    if ($Definition.Despill) {
        $filter += ",despill=green:mix=0.25:expand=0"
    }
    $filter += ",format=rgba"

    Invoke-CheckedFfmpeg -Arguments @(
        "-y", "-hide_banner", "-loglevel", "error",
        "-i", $Definition.Source,
        "-vf", $filter,
        "-compression_level", "7",
        $framePattern
    ) -FailureMessage "Failed to extract $($Definition.Source)"

    $frameCount = @(
        Get-ChildItem -LiteralPath $frameDirectory -Filter "frame_*.png" -File
    ).Count
    if ($frameCount -le 0) {
        throw "No frames were generated from $($Definition.Source)"
    }

    $framesPerPage = 100
    $columns = 10
    $pageCount = [math]::Ceiling($frameCount / $framesPerPage)
    for ($pageIndex = 0; $pageIndex -lt $pageCount; $pageIndex++) {
        $firstFrame = $pageIndex * $framesPerPage + 1
        $framesOnPage = [math]::Min(
            $framesPerPage,
            $frameCount - $pageIndex * $framesPerPage
        )
        $rows = [math]::Ceiling($framesOnPage / $columns)
        $suffix = if ($pageCount -gt 1) {
            "_page$($pageIndex + 1)"
        } else {
            ""
        }
        $outputPath = Join-Path $Definition.OutputDirectory (
            "$($Definition.BaseName)$suffix.png"
        )
        Invoke-CheckedFfmpeg -Arguments @(
            "-y", "-hide_banner", "-loglevel", "error",
            "-framerate", "24",
            "-start_number", "$firstFrame",
            "-i", $framePattern,
            "-vf", "tile=${columns}x${rows}:nb_frames=$framesOnPage",
            "-frames:v", "1",
            "-compression_level", "9",
            "-pred", "mixed",
            $outputPath
        ) -FailureMessage "Failed to assemble $outputPath"
    }

    Write-Host "Built $($Definition.BaseName): $frameCount frames."
}

function Build-StaticAsset {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [string]$KeyColor,
        [string]$Similarity,
        [string]$Blend,
        [bool]$Despill
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Missing source image: $SourcePath"
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $OutputPath) -Force |
        Out-Null
    $filter = (
        "scale=720:720:flags=lanczos," +
        "format=rgba," +
        "colorkey=${KeyColor}:${Similarity}:${Blend}"
    )
    if ($Despill) {
        $filter += ",despill=green:mix=0.25:expand=0"
    }
    $filter += ",format=rgba"
    Invoke-CheckedFfmpeg -Arguments @(
        "-y", "-hide_banner", "-loglevel", "error",
        "-i", $SourcePath,
        "-vf", $filter,
        "-frames:v", "1",
        "-compression_level", "9",
        "-pred", "mixed",
        $OutputPath
    ) -FailureMessage "Failed to build $OutputPath"
}

New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null

try {
    foreach ($animation in $animations) {
        Build-AnimationAtlas -Definition $animation
    }

    Build-StaticAsset `
        -SourcePath (Join-Path $GuardianSourceDirectory "Cyberguardian_Firewall.png") `
        -OutputPath (Join-Path $firewallRoot "Field\Cyberguardian_Firewall.png") `
        -KeyColor "0x30D536" `
        -Similarity "0.24" `
        -Blend "0.08" `
        -Despill $true

    Build-StaticAsset `
        -SourcePath (Join-Path $GuardianSourceDirectory "Cyber_Guardian_Firewall_Icon.png") `
        -OutputPath (Join-Path $firewallRoot "Cyber_Guardian_Firewall_Icon.png") `
        -KeyColor "0x4B6D4D" `
        -Similarity "0.18" `
        -Blend "0.08" `
        -Despill $true
}
finally {
    $resolvedTemporaryRoot = [System.IO.Path]::GetFullPath($temporaryRoot)
    $resolvedSystemTemp = [System.IO.Path]::GetFullPath(
        [System.IO.Path]::GetTempPath()
    )
    if ($resolvedTemporaryRoot.StartsWith(
            $resolvedSystemTemp,
            [System.StringComparison]::OrdinalIgnoreCase
        ) -and (Test-Path -LiteralPath $resolvedTemporaryRoot)) {
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force
    }
}
