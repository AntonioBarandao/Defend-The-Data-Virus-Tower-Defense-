param(
    [string]$SourceDirectory = "C:\Users\jonhu\Downloads\Botnet  - Zombie Node\Zombie-Node",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$ffprobe = (Get-Command ffprobe -ErrorAction Stop).Source
$python = (Get-Command python -ErrorAction Stop).Source
$outputDirectory = Join-Path $ProjectDirectory "assets\Enemies\ZombieNode\Levels"
$animationDirectory = Join-Path $outputDirectory "Entrance"
$backgroundTool = Join-Path $PSScriptRoot "remove_connected_background.py"
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("defend-the-data-zombie-node-" + [guid]::NewGuid().ToString("N"))
$frameDirectory = Join-Path $temporaryRoot "frames"

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $animationDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $frameDirectory -Force | Out-Null

function Invoke-Checked {
    param([scriptblock]$Command, [string]$Description)
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Description failed with exit code $LASTEXITCODE"
    }
}

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Write-EntranceSpriteFrames {
    param(
        [string]$ResourcePath,
        [int]$FrameCount,
        [int]$FrameSize = 480,
        [int]$Columns = 12,
        [double]$FramesPerSecond = 24.0
    )

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine("[gd_resource type=`"SpriteFrames`" load_steps=$($FrameCount + 2) format=3]")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine('[ext_resource type="Texture2D" path="res://assets/Enemies/ZombieNode/Levels/Entrance/ZombieNodeLV1EntranceAtlas.png" id="1_atlas"]')
    [void]$builder.AppendLine()
    for ($index = 0; $index -lt $FrameCount; $index++) {
        $column = $index % $Columns
        $row = [math]::Floor($index / $Columns)
        $id = "AtlasTexture_{0:D3}" -f $index
        [void]$builder.AppendLine("[sub_resource type=`"AtlasTexture`" id=`"$id`"]")
        [void]$builder.AppendLine('atlas = ExtResource("1_atlas")')
        [void]$builder.AppendLine("region = Rect2($($column * $FrameSize), $($row * $FrameSize), $FrameSize, $FrameSize)")
        [void]$builder.AppendLine()
    }
    [void]$builder.AppendLine("[resource]")
    [void]$builder.AppendLine("animations = [{")
    [void]$builder.AppendLine('"frames": [')
    for ($index = 0; $index -lt $FrameCount; $index++) {
        $id = "AtlasTexture_{0:D3}" -f $index
        [void]$builder.AppendLine('{')
        [void]$builder.AppendLine('"duration": 1.0,')
        [void]$builder.AppendLine('"texture": SubResource("' + $id + '")')
        [void]$builder.Append('}')
        [void]$builder.AppendLine($(if ($index -lt $FrameCount - 1) { ',' } else { '' }))
    }
    [void]$builder.AppendLine("],")
    [void]$builder.AppendLine('"loop": false,')
    [void]$builder.AppendLine('"name": &"entrance",')
    [void]$builder.AppendLine('"speed": ' + $FramesPerSecond.ToString("0.0", [Globalization.CultureInfo]::InvariantCulture))
    [void]$builder.AppendLine("}]")
    Write-Utf8NoBom $ResourcePath $builder.ToString()
}

$entranceSource = Join-Path $SourceDirectory "Zombie-Node-Minion_LV1_Entrance.mp4"
$levelSources = @(
    (Join-Path $SourceDirectory "Zombie-Node-Sprite_LV1.png"),
    (Join-Path $SourceDirectory "Zombie-Node-Sprite_LV2.png"),
    (Join-Path $SourceDirectory "Zombie-Node-Sprite_LV3.png")
)

foreach ($requiredPath in @($entranceSource) + $levelSources + @($backgroundTool)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing Zombie Node source asset: $requiredPath"
    }
}

try {
    for ($level = 1; $level -le 3; $level++) {
        $outputPath = Join-Path $outputDirectory ("ZombieNodeLV{0}.png" -f $level)
        & $ffmpeg -y -hide_banner -loglevel error -i $levelSources[$level - 1] `
            -vf "scale=720:720:flags=lanczos,format=rgba,colorkey=0xFFFFFF:0.12:0.0" -frames:v 1 $outputPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while preparing Zombie Node level $level"
        }
    }

    & $ffmpeg -y -hide_banner -loglevel error -i $entranceSource `
        -vf "fps=24,scale=480:480:flags=lanczos" (Join-Path $frameDirectory "frame_%04d.png")
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed while extracting Zombie Node entrance frames"
    }
    & $python $backgroundTool $frameDirectory
    if ($LASTEXITCODE -ne 0) {
        throw "Background removal failed for Zombie Node entrance frames"
    }

    $frameCount = @(Get-ChildItem -LiteralPath $frameDirectory -Filter "frame_*.png" -File).Count
    if ($frameCount -le 0) {
        throw "No Zombie Node entrance frames were generated"
    }
    & $ffmpeg -y -hide_banner -loglevel error -framerate 24 `
        -i (Join-Path $frameDirectory "frame_%04d.png") `
        -vf "tile=12x11:nb_frames=$frameCount" -frames:v 1 `
        (Join-Path $animationDirectory "ZombieNodeLV1EntranceAtlas.png")
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed while assembling the Zombie Node entrance atlas"
    }

    Write-EntranceSpriteFrames `
        (Join-Path $animationDirectory "ZombieNodeLV1EntranceSpriteFrames.tres") `
        $frameCount
    Write-Host "Built Zombie Node levels and $frameCount entrance frames in $outputDirectory"
}
finally {
    $resolvedTemporaryRoot = [System.IO.Path]::GetFullPath($temporaryRoot)
    $resolvedSystemTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($resolvedTemporaryRoot.StartsWith($resolvedSystemTemp, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTemporaryRoot)) {
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force
    }
}
