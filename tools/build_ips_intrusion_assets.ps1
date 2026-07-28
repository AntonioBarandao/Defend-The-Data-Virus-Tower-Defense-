param(
    [string]$SourceDirectory = "C:\Users\jonhu\Downloads\IPS Intrusion Factory",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$python = (Get-Command python -ErrorAction Stop).Source
$backgroundTool = Join-Path $PSScriptRoot "remove_green_dominant_background.py"
$atlasTool = Join-Path $PSScriptRoot "build_rgba_atlas.py"
$outputRoot = Join-Path $ProjectDirectory "assets\Towers\IPS_Intrusion\Animations"
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
    "defend-the-data-ips-" + [guid]::NewGuid().ToString("N")
)

$animations = @(
    @{
        Source = "IPS_Intrusion_Factory_LV1.mp4"
        OutputDirectory = "Factory"
        BaseName = "IPS_Intrusion_Factory_LV1_atlas_12fps"
        FrameSize = 256
        FrameRate = 12
    },
    @{
        Source = "IPS_Intrusion_Factory_LV2.mp4"
        OutputDirectory = "Factory"
        BaseName = "IPS_Intrusion_Factory_LV2_atlas_12fps"
        FrameSize = 256
        FrameRate = 12
    },
    @{
        Source = "IPS_Intrusion_Factory_LV3.mp4"
        OutputDirectory = "Factory"
        BaseName = "IPS_Intrusion_Factory_LV3_atlas_12fps"
        FrameSize = 256
        FrameRate = 12
    },
    @{
        Source = "IPS_Intrusion_Factory_LV4.mp4"
        OutputDirectory = "Factory"
        BaseName = "IPS_Intrusion_Factory_LV4_atlas_12fps"
        FrameSize = 256
        FrameRate = 12
    },
    @{
        Source = "IPS_Intrusion_Factory_LV5.mp4"
        OutputDirectory = "Factory"
        BaseName = "IPS_Intrusion_Factory_LV5_atlas_12fps"
        FrameSize = 256
        FrameRate = 12
    },
    @{
        Source = "Animated_Spikes.mp4"
        OutputDirectory = "Spikes"
        BaseName = "Animated_Spikes_atlas_12fps"
        FrameSize = 320
        FrameRate = 12
    },
    @{
        Source = "Animated_Spikes_LV5.mp4"
        OutputDirectory = "Spikes"
        BaseName = "Animated_Spikes_LV5_atlas_12fps"
        FrameSize = 320
        FrameRate = 12
    },
    @{
        Source = "Animated_Electricity.mp4"
        OutputDirectory = "Electricity"
        BaseName = "Animated_Electricity_atlas_12fps"
        FrameSize = 320
        FrameRate = 12
    }
)


function Invoke-CheckedProcess {
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [string]$FailureMessage
    )

    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw $FailureMessage
    }
}


function Build-AnimationAtlas {
    param([hashtable]$Definition)

    $sourcePath = Join-Path $SourceDirectory $Definition.Source
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing IPS source media: $sourcePath"
    }

    $outputDirectory = Join-Path $outputRoot $Definition.OutputDirectory
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    $frameDirectory = Join-Path $temporaryRoot $Definition.BaseName
    New-Item -ItemType Directory -Path $frameDirectory -Force | Out-Null

    $framePattern = Join-Path $frameDirectory "frame_%04d.png"
    $filter = (
        "fps=$($Definition.FrameRate)," +
        "scale=$($Definition.FrameSize):$($Definition.FrameSize):flags=lanczos," +
        "format=rgba"
    )
    Invoke-CheckedProcess -Executable $ffmpeg -Arguments @(
        "-y", "-hide_banner", "-loglevel", "error",
        "-i", $sourcePath,
        "-vf", $filter,
        "-compression_level", "4",
        $framePattern
    ) -FailureMessage "Failed to extract $sourcePath"

    Invoke-CheckedProcess -Executable $python -Arguments @(
        $backgroundTool,
        $frameDirectory,
        "--excess-start", "12",
        "--excess-full", "60",
        "--green-start", "30",
        "--green-full", "90",
        "--despill",
        "--edge-connected-only"
    ) -FailureMessage "Failed to remove the IPS green background."

    $frameCount = @(
        Get-ChildItem -LiteralPath $frameDirectory -Filter "frame_*.png" -File
    ).Count
    if ($frameCount -le 0) {
        throw "No frames were generated from $sourcePath"
    }

    $columns = 10
    $rows = [math]::Ceiling($frameCount / $columns)
    $outputPath = Join-Path $outputDirectory (
        "{0}.png" -f $Definition.BaseName
    )
    Invoke-CheckedProcess -Executable $python -Arguments @(
        $atlasTool,
        $frameDirectory,
        $outputPath,
        "--frame-size", "$($Definition.FrameSize)",
        "--columns", "$columns"
    ) -FailureMessage "Failed to assemble $outputPath"

    Write-Host (
        "Built {0}: {1} frames in one {2}x{3} lossless PNG atlas." -f
        $Definition.BaseName,
        $frameCount,
        ($columns * $Definition.FrameSize),
        ($rows * $Definition.FrameSize)
    )
}


if (-not (Test-Path -LiteralPath $backgroundTool)) {
    throw "Missing background removal tool: $backgroundTool"
}
if (-not (Test-Path -LiteralPath $atlasTool)) {
    throw "Missing RGBA atlas tool: $atlasTool"
}

New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null
try {
    foreach ($animation in $animations) {
        Build-AnimationAtlas -Definition $animation
    }
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
