param(
    [string]$SourceDirectory = "C:\Users\jonhu\Downloads\SIEM Hawk",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot),
    [int[]]$Levels = @(2, 3, 4, 5)
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$python = (Get-Command python -ErrorAction Stop).Source
$backgroundTool = Join-Path (
    $ProjectDirectory
) "tools\remove_connected_color_background.py"
$atlasTool = Join-Path (
    $ProjectDirectory
) "tools\build_rgba_atlas.py"
$outputDirectory = Join-Path (
    $ProjectDirectory
) "assets\Towers\SIEM_Hawk\Attack"
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
    "defend-the-data-siem-hawk-attack-" + [guid]::NewGuid().ToString("N")
)
$frameSize = 320
$keyFrameSize = 480
$columns = 10
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

function Write-SpriteFrames {
    param(
        [int]$Level,
        [int]$FrameCount
    )

    $animationName = "attack_lv$Level"
    $atlasFileName = "SIEMHawkAttackLV${Level}Atlas.png"
    $resourcePath = Join-Path (
        $outputDirectory
    ) "SIEMHawkAttackLV${Level}SpriteFrames.tres"
    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine(
        "[gd_resource type=`"SpriteFrames`" load_steps=$($FrameCount + 2) format=3]"
    )
    [void]$builder.AppendLine()
    [void]$builder.AppendLine(
        "[ext_resource type=`"Texture2D`" path=`"res://assets/Towers/SIEM_Hawk/Attack/$atlasFileName`" id=`"1_atlas`"]"
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
    [void]$builder.AppendLine('"loop": true,')
    [void]$builder.AppendLine('"name": &"' + $animationName + '",')
    [void]$builder.AppendLine('"speed": 24.0')
    [void]$builder.AppendLine("}]")
    Write-Utf8NoBom $resourcePath $builder.ToString()
}

try {
    foreach ($level in $Levels) {
        if ($level -lt 2 -or $level -gt 5) {
            throw "SIEM Hawk attack level must be between 2 and 5."
        }
        $sourcePath = Join-Path (
            $SourceDirectory
        ) "SIEM_Hawk_Attack_LV${level}.mp4"
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Missing SIEM Hawk attack source: $sourcePath"
        }

        $sourceFrameDirectory = Join-Path $temporaryRoot "LV${level}_Source"
        $frameDirectory = Join-Path $temporaryRoot "LV$level"
        New-Item -ItemType Directory -Path $sourceFrameDirectory -Force |
            Out-Null
        New-Item -ItemType Directory -Path $frameDirectory -Force | Out-Null
        $sourceFramePattern = Join-Path (
            $sourceFrameDirectory
        ) "frame_%04d.png"
        $framePattern = Join-Path $frameDirectory "frame_%04d.png"
        & $ffmpeg -y -hide_banner -loglevel error -i $sourcePath `
            -vf "fps=24,scale=${keyFrameSize}:${keyFrameSize}:flags=lanczos,format=rgba" `
            $sourceFramePattern
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while extracting SIEM Hawk LV$level"
        }

        & $python $backgroundTool $sourceFrameDirectory `
            --inner-distance 8 `
            --outer-distance 145 `
            --despill `
            --fast-save
        if ($LASTEXITCODE -ne 0) {
            throw "Background removal failed for SIEM Hawk LV$level"
        }

        & $ffmpeg -y -hide_banner -loglevel error -framerate 24 `
            -i $sourceFramePattern `
            -vf "scale=${frameSize}:${frameSize}:flags=lanczos,format=rgba" `
            $framePattern
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while resizing SIEM Hawk LV$level"
        }

        $frameCount = @(
            Get-ChildItem -LiteralPath $frameDirectory `
                -Filter "frame_*.png" -File
        ).Count
        if ($frameCount -le 0) {
            throw "No frames generated for SIEM Hawk LV$level"
        }

        $atlasPath = Join-Path (
            $outputDirectory
        ) "SIEMHawkAttackLV${level}Atlas.png"
        & $python $atlasTool $frameDirectory $atlasPath `
            --frame-size $frameSize `
            --columns $columns
        if ($LASTEXITCODE -ne 0) {
            throw "Lossless atlas assembly failed for SIEM Hawk LV$level"
        }

        Write-SpriteFrames -Level $level -FrameCount $frameCount
        Write-Host "Built SIEM Hawk attack LV${level}: $frameCount frames."
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
