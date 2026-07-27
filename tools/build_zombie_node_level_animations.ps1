param(
    [string]$SourceDirectory = "C:\Users\jonhu\Downloads\Botnet  - Zombie Node\Zombie-Node",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot),
    [string]$OnlyAnimation = ""
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$python = (Get-Command python -ErrorAction Stop).Source
$backgroundTool = Join-Path $ProjectDirectory "tools\remove_connected_background.py"
$outputDirectory = Join-Path $ProjectDirectory "assets\Enemies\ZombieNode\Levels\Animations"
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
    "defend-the-data-zombie-node-levels-" + [guid]::NewGuid().ToString("N")
)
$frameSize = 315
$columns = 13
$framesPerSecond = 24.0
$connectedWhiteThreshold = 175
$connectedNeutralDelta = 64

$animations = @(
    @{
        Source = "Zombie-Node_LV1_Idle.mp4"
        Name = "ZombieNodeLV1Idle"
        Track = "idle_lv1"
        Loop = $true
    },
    @{
        Source = "Zombie-Node_LV1_Activate.mp4"
        Name = "ZombieNodeLV1Activate"
        Track = "activate_lv1"
        Loop = $false
    },
    @{
        Source = "Zombie-Node_LV1-LV2_Evolve.mp4"
        Name = "ZombieNodeLV1ToLV2Evolve"
        Track = "evolve_lv1_to_lv2"
        Loop = $false
    },
    @{
        Source = "Zombie-Node_LV2_Idle.mp4"
        Name = "ZombieNodeLV2Idle"
        Track = "idle_lv2"
        Loop = $true
    },
    @{
        Source = "Zombie-Node_LV2_Activate.mp4"
        Name = "ZombieNodeLV2Activate"
        Track = "activate_lv2"
        Loop = $false
    },
    @{
        Source = "Zombie-Node_LV2-LV3_Evolve.mp4"
        Name = "ZombieNodeLV2ToLV3Evolve"
        Track = "evolve_lv2_to_lv3"
        Loop = $false
    },
    @{
        Source = "Zombie-Node_LV3_Idle.mp4"
        Name = "ZombieNodeLV3Idle"
        Track = "idle_lv3"
        Loop = $true
    },
    @{
        Source = "Zombie-Node_LV3_Activate.mp4"
        Name = "ZombieNodeLV3Activate"
        Track = "activate_lv3"
        Loop = $false
    },
    @{
        Source = "Zombie-Node_LV3_Destroy.mp4"
        Name = "ZombieNodeLV3Destroy"
        Track = "destroy_lv3"
        Loop = $false
    }
)

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText(
        $Path,
        $Content,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Write-SpriteFramesResource {
    param(
        [string]$ResourcePath,
        [string]$AtlasResourcePath,
        [string]$TrackName,
        [int]$FrameCount,
        [bool]$Loop
    )

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine(
        "[gd_resource type=`"SpriteFrames`" load_steps=$($FrameCount + 2) format=3]"
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
        '"loop": ' + $Loop.ToString().ToLowerInvariant() + ','
    )
    [void]$builder.AppendLine('"name": &"' + $TrackName + '",')
    $speedText = $framesPerSecond.ToString(
        "0.0",
        [Globalization.CultureInfo]::InvariantCulture
    )
    [void]$builder.AppendLine('"speed": ' + $speedText)
    [void]$builder.AppendLine("}]")
    Write-Utf8NoBom $ResourcePath $builder.ToString()
}

try {
    foreach ($animation in $animations) {
        if (-not [string]::IsNullOrWhiteSpace($OnlyAnimation) `
                -and $animation.Name -ne $OnlyAnimation) {
            continue
        }

        $sourcePath = Join-Path $SourceDirectory $animation.Source
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Missing Zombie Node animation source: $sourcePath"
        }

        $frameDirectory = Join-Path $temporaryRoot $animation.Name
        New-Item -ItemType Directory -Path $frameDirectory -Force | Out-Null
        $framePattern = Join-Path $frameDirectory "frame_%04d.png"
        & $ffmpeg -y -hide_banner -loglevel error -i $sourcePath `
            -vf "fps=24,scale=${frameSize}:${frameSize}:flags=lanczos,format=rgba" `
            $framePattern
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while extracting $($animation.Source)"
        }

        & $python $backgroundTool $frameDirectory `
            --threshold $connectedWhiteThreshold `
            --neutral-delta $connectedNeutralDelta `
            --hard-alpha `
            --protect-center-holes
        if ($LASTEXITCODE -ne 0) {
            throw "Background removal failed for $($animation.Source)"
        }

        $frameCount = @(
            Get-ChildItem -LiteralPath $frameDirectory -Filter "frame_*.png" -File
        ).Count
        if ($frameCount -le 0) {
            throw "No frames were generated from $($animation.Source)"
        }

        $rows = [math]::Ceiling($frameCount / $columns)
        $atlasName = "$($animation.Name)Atlas.webp"
        $atlasPath = Join-Path $outputDirectory $atlasName
        & $ffmpeg -y -hide_banner -loglevel error -framerate 24 `
            -i $framePattern `
            -vf "tile=${columns}x${rows}:nb_frames=$frameCount" `
            -frames:v 1 -c:v libwebp -quality 92 -compression_level 6 `
            $atlasPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while assembling $atlasName"
        }

        $resourcePath = Join-Path $outputDirectory (
            "$($animation.Name)SpriteFrames.tres"
        )
        $atlasResourcePath = (
            "res://assets/Enemies/ZombieNode/Levels/Animations/$atlasName"
        )
        Write-SpriteFramesResource `
            -ResourcePath $resourcePath `
            -AtlasResourcePath $atlasResourcePath `
            -TrackName $animation.Track `
            -FrameCount $frameCount `
            -Loop ([bool]$animation.Loop)
        Write-Host "Built $($animation.Name): $frameCount frames."
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
