param(
    [string]$SourceDirectory = "C:\Users\jonhu\Downloads\Adware - Spyware - Phishing\Spyware",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$python = (Get-Command python -ErrorAction Stop).Source
$backgroundTool = Join-Path $ProjectDirectory "tools\remove_connected_color_background.py"
$greenBackgroundTool = Join-Path (
    $ProjectDirectory
) "tools\remove_green_dominant_background.py"
$outputDirectory = Join-Path $ProjectDirectory "assets\Enemies\Spyware\Animations"
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
    "defend-the-data-spyware-" + [guid]::NewGuid().ToString("N")
)
$frameSize = 320
$columns = 10
$framesPerSecond = 24.0

$animations = @(
    @{
        Source = "Spyware-Walking.mp4"
        BaseName = "SpywareWalking"
        Animation = "walking"
        Loop = $true
        GreenDominanceKey = $true
    },
    @{
        Source = "Spyware_VFX-Appear.mp4"
        BaseName = "SpywareVFXAppear"
        Animation = "vfx_appear"
        Loop = $false
        InnerDistance = 12
        OuterDistance = 92
    },
    @{
        Source = "Spyware_VFX-Active.mp4"
        BaseName = "SpywareVFXActive"
        Animation = "vfx_active"
        Loop = $true
        InnerDistance = 12
        OuterDistance = 92
    },
    @{
        Source = "Spyware_VFX-Dissapear.mp4"
        BaseName = "SpywareVFXDisappear"
        Animation = "vfx_disappear"
        Loop = $false
        InnerDistance = 12
        OuterDistance = 92
    }
)

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)

    [System.IO.File]::WriteAllText(
        $Path,
        $Content,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Write-SpriteFrames {
    param(
        [hashtable]$Definition,
        [int]$FrameCount
    )

    $atlasFileName = "$($Definition.BaseName)Atlas.webp"
    $resourcePath = Join-Path (
        $outputDirectory
    ) "$($Definition.BaseName)SpriteFrames.tres"
    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine(
        "[gd_resource type=`"SpriteFrames`" load_steps=$($FrameCount + 2) format=3]"
    )
    [void]$builder.AppendLine()
    [void]$builder.AppendLine(
        "[ext_resource type=`"Texture2D`" path=`"res://assets/Enemies/Spyware/Animations/$atlasFileName`" id=`"1_atlas`"]"
    )
    [void]$builder.AppendLine()

    for ($index = 0; $index -lt $FrameCount; $index++) {
        $column = $index % $columns
        $row = [math]::Floor($index / $columns)
        $id = "AtlasTexture_{0:D3}" -f $index
        [void]$builder.AppendLine("[sub_resource type=`"AtlasTexture`" id=`"$id`"]")
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
        '"loop": ' + $(if ($Definition.Loop) { "true" } else { "false" }) + ","
    )
    [void]$builder.AppendLine('"name": &"' + $Definition.Animation + '",')
    [void]$builder.AppendLine('"speed": 24.0')
    [void]$builder.AppendLine("}]")

    Write-Utf8NoBom $resourcePath $builder.ToString()
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null

try {
    foreach ($definition in $animations) {
        $sourcePath = Join-Path $SourceDirectory $definition.Source
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Missing Spyware source media: $sourcePath"
        }

        $frameDirectory = Join-Path $temporaryRoot $definition.BaseName
        New-Item -ItemType Directory -Path $frameDirectory -Force | Out-Null
        $framePattern = Join-Path $frameDirectory "frame_%04d.png"
        $filter = "fps=24,scale=${frameSize}:${frameSize}:flags=lanczos,format=rgba"
        & $ffmpeg -y -hide_banner -loglevel error -i $sourcePath `
            -vf $filter `
            $framePattern
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while extracting $($definition.Source)"
        }

        if ($definition.GreenDominanceKey) {
            & $python $greenBackgroundTool $frameDirectory `
                --excess-start 20 `
                --excess-full 72 `
                --green-start 35 `
                --green-full 90 `
                --despill
            if ($LASTEXITCODE -ne 0) {
                throw "Green background removal failed for $($definition.Source)"
            }
        }
        else {
            & $python $backgroundTool $frameDirectory `
                --inner-distance $definition.InnerDistance `
                --outer-distance $definition.OuterDistance `
                --despill
            if ($LASTEXITCODE -ne 0) {
                throw "Background removal failed for $($definition.Source)"
            }
        }

        $frameCount = @(
            Get-ChildItem -LiteralPath $frameDirectory -Filter "frame_*.png" -File
        ).Count
        if ($frameCount -le 0) {
            throw "No frames generated from $($definition.Source)"
        }

        $rows = [math]::Ceiling($frameCount / $columns)
        $atlasPath = Join-Path $outputDirectory "$($definition.BaseName)Atlas.webp"
        & $ffmpeg -y -hide_banner -loglevel error -framerate 24 `
            -i $framePattern `
            -vf "tile=${columns}x${rows}:nb_frames=$frameCount" `
            -frames:v 1 -c:v libwebp -lossless 1 -compression_level 6 `
            $atlasPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while assembling $($definition.BaseName)"
        }

        Write-SpriteFrames -Definition $definition -FrameCount $frameCount
        Write-Host "Built $($definition.Animation): $frameCount frames."
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
