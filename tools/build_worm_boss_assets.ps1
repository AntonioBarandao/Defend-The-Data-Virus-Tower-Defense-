param(
    [string]$SourceDirectory = "C:\Users\jonhu\Downloads\WormBoss",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$python = (Get-Command python -ErrorAction Stop).Source
$backgroundTool = Join-Path $ProjectDirectory "tools\remove_connected_background.py"
$outputDirectory = Join-Path $ProjectDirectory "assets\Enemies\WormBoss"
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
    "defend-the-data-worm-boss-" + [guid]::NewGuid().ToString("N")
)
$frameSize = 315
$columns = 13
$framesPerSecond = 24.0

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

function Remove-ConnectedBackground {
    param([string]$Path)
    & $python $backgroundTool $Path `
        --threshold 175 `
        --neutral-delta 64 `
        --hard-alpha
    if ($LASTEXITCODE -ne 0) {
        throw "Background removal failed for $Path"
    }
}

function Write-SpriteFrames {
    param(
        [string]$ResourcePath,
        [string]$AtlasFileName,
        [string]$AnimationName,
        [int]$FrameCount,
        [bool]$Loop
    )

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine(
        "[gd_resource type=`"SpriteFrames`" load_steps=$($FrameCount + 2) format=3]"
    )
    [void]$builder.AppendLine()
    [void]$builder.AppendLine(
        "[ext_resource type=`"Texture2D`" path=`"res://assets/Enemies/WormBoss/$AtlasFileName`" id=`"1_atlas`"]"
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
    [void]$builder.AppendLine('"name": &"' + $AnimationName + '",')
    [void]$builder.AppendLine('"speed": 24.0')
    [void]$builder.AppendLine("}]")
    Write-Utf8NoBom $ResourcePath $builder.ToString()
}

function Build-AnimatedAtlas {
    param(
        [string]$SourceFileName,
        [string]$AtlasFileName,
        [string]$ResourceFileName,
        [string]$AnimationName,
        [bool]$Loop
    )

    $sourcePath = Join-Path $SourceDirectory $SourceFileName
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing Worm Boss source: $sourcePath"
    }

    $frameDirectory = Join-Path $temporaryRoot $AnimationName
    New-Item -ItemType Directory -Path $frameDirectory -Force | Out-Null
    $framePattern = Join-Path $frameDirectory "frame_%04d.png"
    & $ffmpeg -y -hide_banner -loglevel error -i $sourcePath `
        -vf "fps=24,scale=${frameSize}:${frameSize}:flags=lanczos,format=rgba" `
        $framePattern
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed while extracting $SourceFileName"
    }
    Remove-ConnectedBackground $frameDirectory

    $frameCount = @(
        Get-ChildItem -LiteralPath $frameDirectory -Filter "frame_*.png" -File
    ).Count
    if ($frameCount -le 0) {
        throw "No frames were generated from $SourceFileName"
    }

    $rows = [math]::Ceiling($frameCount / $columns)
    $atlasPath = Join-Path $outputDirectory $AtlasFileName
    & $ffmpeg -y -hide_banner -loglevel error -framerate 24 `
        -i $framePattern `
        -vf "tile=${columns}x${rows}:nb_frames=$frameCount" `
        -frames:v 1 -c:v libwebp -quality 92 -compression_level 6 `
        $atlasPath
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed while assembling $AtlasFileName"
    }

    Write-SpriteFrames `
        -ResourcePath (Join-Path $outputDirectory $ResourceFileName) `
        -AtlasFileName $AtlasFileName `
        -AnimationName $AnimationName `
        -FrameCount $frameCount `
        -Loop $Loop
    Write-Host "Built ${AnimationName}: $frameCount frames."
}

try {
    $staticAssets = @(
        @{
            Source = "Worm_Head.png"
            Output = "WormHeadStatic.png"
        },
        @{
            Source = "Worm_Body.png"
            Output = "WormBody.png"
        },
        @{
            Source = "Worm_Tail.png"
            Output = "WormTail.png"
        }
    )

    foreach ($asset in $staticAssets) {
        $sourcePath = Join-Path $SourceDirectory $asset.Source
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Missing Worm Boss source: $sourcePath"
        }

        $outputPath = Join-Path $outputDirectory $asset.Output
        & $ffmpeg -y -hide_banner -loglevel error -i $sourcePath `
            -vf "scale=${frameSize}:${frameSize}:flags=lanczos,format=rgba" `
            -frames:v 1 $outputPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while preparing $($asset.Source)"
        }
        Remove-ConnectedBackground $outputPath
        Write-Host "Built $($asset.Output)."
    }

    $animatedAssets = @(
        @{
            Source = "Worm_Head.mp4"
            Atlas = "WormHeadAnimationAtlas.webp"
            Resource = "WormHeadSpriteFrames.tres"
            Animation = "head"
            Loop = $true
        },
        @{
            Source = "Worm_Head_Destroy.mp4"
            Atlas = "WormHeadDestroyAtlas.webp"
            Resource = "WormHeadDestroySpriteFrames.tres"
            Animation = "head_destroy"
            Loop = $false
        },
        @{
            Source = "Worm_Body_Destroy.mp4"
            Atlas = "WormBodyDestroyAtlas.webp"
            Resource = "WormBodyDestroySpriteFrames.tres"
            Animation = "body_destroy"
            Loop = $false
        },
        @{
            Source = "Worm_Tail_Destroy.mp4"
            Atlas = "WormTailDestroyAtlas.webp"
            Resource = "WormTailDestroySpriteFrames.tres"
            Animation = "tail_destroy"
            Loop = $false
        }
    )

    foreach ($asset in $animatedAssets) {
        Build-AnimatedAtlas `
            -SourceFileName $asset.Source `
            -AtlasFileName $asset.Atlas `
            -ResourceFileName $asset.Resource `
            -AnimationName $asset.Animation `
            -Loop $asset.Loop
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
