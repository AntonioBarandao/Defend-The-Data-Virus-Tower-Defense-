param(
    [string]$SourceDirectory = "C:\Users\jonhu\Downloads\XDR Mech",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot),
    [int]$OnlyLevel = 0
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$python = (Get-Command python -ErrorAction Stop).Source
$backgroundTool = Join-Path $ProjectDirectory "tools\remove_green_dominant_background.py"
$outputDirectory = Join-Path $ProjectDirectory "assets\Towers\XDR_Mech\Animations\Hit"
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) (
    "defend-the-data-xdr-hit-" + [guid]::NewGuid().ToString("N")
)
$frameSize = 360
$columns = 8
$framesPerSecond = 24.0
$resourceUids = @{
    1 = "uid://f35susjeujug"
    2 = "uid://c07gm2mimldnm"
    3 = "uid://dlnp0sclmbofj"
    4 = "uid://d3136xes3mimx"
    5 = "uid://mg6vp3tiwqm3"
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    [IO.File]::WriteAllText(
        $Path,
        $Content,
        [Text.UTF8Encoding]::new($false)
    )
}

function Write-HitSpriteFrames {
    param(
        [string]$ResourcePath,
        [string]$AtlasResourcePath,
        [string]$TrackName,
        [int]$FrameCount,
        [string]$ResourceUid,
        [bool]$LoopAnimation = $false
    )

    $builder = [Text.StringBuilder]::new()
    [void]$builder.AppendLine(
        "[gd_resource type=`"SpriteFrames`" load_steps=$($FrameCount + 2) format=3 uid=`"$ResourceUid`"]"
    )
    [void]$builder.AppendLine()
    [void]$builder.AppendLine(
        "[ext_resource type=`"Texture2D`" path=`"$AtlasResourcePath`" id=`"1_atlas`"]"
    )
    [void]$builder.AppendLine()
    for ($index = 0; $index -lt $FrameCount; $index++) {
        $column = $index % $columns
        $row = [math]::Floor($index / $columns)
        $id = "AtlasTexture_{0:D3}" -f $index
        [void]$builder.AppendLine(
            "[sub_resource type=`"AtlasTexture`" id=`"$id`"]"
        )
        [void]$builder.AppendLine('atlas = ExtResource("1_atlas")')
        [void]$builder.AppendLine(
            "region = Rect2($($column * $frameSize), $($row * $frameSize), $frameSize, $frameSize)"
        )
        [void]$builder.AppendLine()
    }

    [void]$builder.AppendLine("[resource]")
    [void]$builder.AppendLine("animations = [{")
    [void]$builder.AppendLine('"frames": [')
    for ($index = 0; $index -lt $FrameCount; $index++) {
        $id = "AtlasTexture_{0:D3}" -f $index
        [void]$builder.AppendLine("{")
        [void]$builder.AppendLine('"duration": 1.0,')
        [void]$builder.AppendLine('"texture": SubResource("' + $id + '")')
        [void]$builder.Append("}")
        [void]$builder.AppendLine(
            $(if ($index -lt $FrameCount - 1) { "," } else { "" })
        )
    }
    [void]$builder.AppendLine("],")
    [void]$builder.AppendLine(
        '"loop": ' + $LoopAnimation.ToString().ToLowerInvariant() + ','
    )
    [void]$builder.AppendLine('"name": &"' + $TrackName + '",')
    [void]$builder.AppendLine('"speed": 24.0')
    [void]$builder.AppendLine("}]")
    Write-Utf8NoBom $ResourcePath $builder.ToString()
}

try {
    foreach ($level in 1..5) {
        if ($OnlyLevel -gt 0 -and $OnlyLevel -ne $level) {
            continue
        }

        $sourcePath = Join-Path $SourceDirectory "XDR-Mech_LV$level-Hit.mp4"
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Missing XDR hit animation: $sourcePath"
        }

        $frameDirectory = Join-Path $temporaryRoot "LV$level"
        New-Item -ItemType Directory -Path $frameDirectory -Force | Out-Null
        $framePattern = Join-Path $frameDirectory "frame_%04d.png"
        & $ffmpeg -y -hide_banner -loglevel error -i $sourcePath `
            -vf "fps=24,scale=${frameSize}:${frameSize}:flags=lanczos,format=rgba" `
            $framePattern
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while extracting XDR LV$level hit frames."
        }

        $backgroundArguments = @(
            $backgroundTool,
            $frameDirectory,
            "--excess-start", "0",
            "--excess-full", "12",
            "--green-start", "0",
            "--green-full", "24",
            "--despill",
            "--clear-transparent-rgb",
            "--hard-key"
        )
        if ($level -eq 5) {
            $backgroundArguments += @(
                "--edge-connected-only",
                "--despill-all"
            )
        }
        & $python @backgroundArguments
        if ($LASTEXITCODE -ne 0) {
            throw "Green removal failed for XDR LV$level hit frames."
        }

        $frameCount = @(
            Get-ChildItem -LiteralPath $frameDirectory -Filter "frame_*.png" -File
        ).Count
        if ($frameCount -le 0) {
            throw "No XDR LV$level hit frames were generated."
        }

        $rows = [math]::Ceiling($frameCount / $columns)
        $atlasName = "XDRMechLV${level}HitAtlas.png"
        $atlasPath = Join-Path $outputDirectory $atlasName
        & $ffmpeg -y -hide_banner -loglevel error -framerate 24 `
            -i $framePattern `
            -vf "tile=${columns}x${rows}:nb_frames=$frameCount" `
            -frames:v 1 -c:v png -compression_level 9 -pred mixed `
            $atlasPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while assembling $atlasName."
        }

        $resourceName = "XDRMechLV${level}HitSpriteFrames.tres"
        $resourcePath = Join-Path $outputDirectory $resourceName
        Write-HitSpriteFrames `
            -ResourcePath $resourcePath `
            -AtlasResourcePath (
                "res://assets/Towers/XDR_Mech/Animations/Hit/$atlasName"
            ) `
            -TrackName "hit_lv$level" `
            -FrameCount $frameCount `
            -ResourceUid $resourceUids[$level] `
            -LoopAnimation ($level -le 2)
        Write-Host "Built XDR Mech LV$level hit: $frameCount frames."
    }
}
finally {
    $resolvedTemporaryRoot = [IO.Path]::GetFullPath($temporaryRoot)
    $resolvedSystemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolvedTemporaryRoot.StartsWith(
            $resolvedSystemTemp,
            [StringComparison]::OrdinalIgnoreCase
        ) -and (Test-Path -LiteralPath $resolvedTemporaryRoot)) {
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force
    }
}
