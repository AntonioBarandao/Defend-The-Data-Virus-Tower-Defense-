param(
    [string]$SourceDirectory = "C:\Users\jonhu\Downloads\Ransomware",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot),
    [string]$OnlyAnimation = ""
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$python = (Get-Command python -ErrorAction Stop).Source
$backgroundTool = Join-Path $ProjectDirectory "tools\remove_connected_background.py"
$outputDirectory = Join-Path $ProjectDirectory "assets\Enemies\Ransomware"
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("defend-the-data-ransomware-" + [guid]::NewGuid().ToString("N"))
$frameSize = 315
$columns = 13
$framesPerSecond = 24.0
$connectedWhiteThreshold = 175
$connectedNeutralDelta = 64
$globalWhiteSimilarity = 0.30
$globalWhiteBlend = 0.02

$animations = @(
    @{
        Source = "Ransomware_Appear.mp4"
        Name = "RansomwareAppear"
        Track = "appear"
        Loop = $false
        WhiteMode = "key"
    },
    @{
        Source = "Ransomware_Head_Appear.mp4"
        Name = "RansomwareHeadAppear"
        Track = "head_appear"
        Loop = $false
        WhiteMode = "global"
    },
    @{
        Source = "Ransomware_Idle.mp4"
        Name = "RansomwareIdle"
        Track = "idle"
        Loop = $true
        WhiteMode = "key"
    },
    @{
        Source = "Ransomware_FrontHead-Straight.mp4"
        Name = "RansomwareFrontStraight"
        Track = "front_straight"
        Loop = $true
        WhiteMode = "global"
    },
    @{
        Source = "Ransomware_Front_Head-Sides.mp4"
        Name = "RansomwareFrontSides"
        Track = "front_sides"
        Loop = $false
        WhiteMode = "global"
    },
    @{
        Source = "Ransomware_Destroy.mp4"
        Name = "RansomwareDestroy"
        Track = "destroy"
        Loop = $false
        WhiteMode = "connected"
    }
)

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null

Get-ChildItem -LiteralPath $outputDirectory -Filter "*Atlas.png" -File |
    Remove-Item -Force

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Write-SpriteFramesResource {
    param(
        [string]$ResourcePath,
        [string]$AtlasResourcePath,
        [string]$TrackName,
        [int]$FrameCount,
        [bool]$Loop
    )

    $rows = [math]::Ceiling($FrameCount / $columns)
    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine("[gd_resource type=`"SpriteFrames`" load_steps=$($FrameCount + 2) format=3]")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine("[ext_resource type=`"Texture2D`" path=`"$AtlasResourcePath`" id=`"1_atlas`"]")
    [void]$builder.AppendLine()
    for ($index = 0; $index -lt $FrameCount; $index++) {
        $column = $index % $columns
        $row = [math]::Floor($index / $columns)
        $id = "AtlasTexture_{0:D3}" -f $index
        [void]$builder.AppendLine("[sub_resource type=`"AtlasTexture`" id=`"$id`"]")
        [void]$builder.AppendLine('atlas = ExtResource("1_atlas")')
        [void]$builder.AppendLine("region = Rect2($($column * $frameSize), $($row * $frameSize), $frameSize, $frameSize)")
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
        [void]$builder.AppendLine($(if ($index -lt $FrameCount - 1) { "," } else { "" }))
    }
    [void]$builder.AppendLine("],")
    [void]$builder.AppendLine('"loop": ' + $Loop.ToString().ToLowerInvariant() + ',')
    [void]$builder.AppendLine('"name": &"' + $TrackName + '",')
    [void]$builder.AppendLine('"speed": ' + $framesPerSecond.ToString("0.0", [Globalization.CultureInfo]::InvariantCulture))
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
            throw "Missing Ransomware source: $sourcePath"
        }

        $frameDirectory = Join-Path $temporaryRoot $animation.Name
        New-Item -ItemType Directory -Path $frameDirectory -Force | Out-Null
        $framePattern = Join-Path $frameDirectory "frame_%04d.png"
        $videoFilter = "fps=24,scale=${frameSize}:${frameSize}:flags=lanczos,format=rgba"
        if ($animation.WhiteMode -eq "key") {
            $videoFilter += ",colorkey=0xFFFFFF:0.28:0.0"
        }
        elseif ($animation.WhiteMode -eq "global") {
            $similarity = $globalWhiteSimilarity.ToString(
                "0.00",
                [Globalization.CultureInfo]::InvariantCulture
            )
            $blend = $globalWhiteBlend.ToString(
                "0.00",
                [Globalization.CultureInfo]::InvariantCulture
            )
            $videoFilter += ",colorkey=0xFFFFFF:${similarity}:${blend}"
        }

        & $ffmpeg -y -hide_banner -loglevel error -i $sourcePath -vf $videoFilter $framePattern
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while extracting $($animation.Source)"
        }

        if ($animation.WhiteMode -eq "connected") {
            & $python $backgroundTool $frameDirectory `
                --threshold $connectedWhiteThreshold `
                --neutral-delta $connectedNeutralDelta `
                --hard-alpha `
                --protect-center-holes
            if ($LASTEXITCODE -ne 0) {
                throw "Connected-background removal failed for $($animation.Source)"
            }
        }

        $frameCount = @(Get-ChildItem -LiteralPath $frameDirectory -Filter "frame_*.png" -File).Count
        if ($frameCount -le 0) {
            throw "No frames were generated from $($animation.Source)"
        }

        $rows = [math]::Ceiling($frameCount / $columns)
        $atlasName = "$($animation.Name)Atlas.webp"
        $atlasPath = Join-Path $outputDirectory $atlasName
        & $ffmpeg -y -hide_banner -loglevel error -framerate 24 -i $framePattern `
            -vf "tile=${columns}x${rows}:nb_frames=$frameCount" -frames:v 1 `
            -c:v libwebp -quality 92 -compression_level 6 $atlasPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while assembling $atlasName"
        }

        $resourcePath = Join-Path $outputDirectory "$($animation.Name)SpriteFrames.tres"
        $atlasResourcePath = "res://assets/Enemies/Ransomware/$atlasName"
        Write-SpriteFramesResource `
            -ResourcePath $resourcePath `
            -AtlasResourcePath $atlasResourcePath `
            -TrackName $animation.Track `
            -FrameCount $frameCount `
            -Loop ([bool]$animation.Loop)
        Write-Host "Built $($animation.Name): $frameCount frames."
    }

    if ([string]::IsNullOrWhiteSpace($OnlyAnimation)) {
        $frontHeadSource = Join-Path $SourceDirectory "Ransomware_Front-Head.png"
        $frontHeadOutput = Join-Path $outputDirectory "RansomwareFrontHead.png"
        & $ffmpeg -y -hide_banner -loglevel error -i $frontHeadSource `
            -vf "scale=${frameSize}:${frameSize}:flags=lanczos,format=rgba" `
            -frames:v 1 $frontHeadOutput
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while preparing the Ransomware front-head texture"
        }
        & $python $backgroundTool $frontHeadOutput `
            --threshold $connectedWhiteThreshold `
            --neutral-delta $connectedNeutralDelta `
            --hard-alpha `
            --protect-center-holes
        if ($LASTEXITCODE -ne 0) {
            throw "Connected-background removal failed for the Ransomware front-head texture"
        }
        Write-Host "Built RansomwareFrontHead.png."
    }
}
finally {
    $resolvedTemporaryRoot = [System.IO.Path]::GetFullPath($temporaryRoot)
    $resolvedSystemTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($resolvedTemporaryRoot.StartsWith($resolvedSystemTemp, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTemporaryRoot)) {
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force
    }
}
