param(
    [string]$SourcePath = "C:\Users\jonhu\Downloads\Botnet  - Zombie Node\Zombie-Node\Zombie-Node-Minion_LV1_Activate.mp4",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$outputDirectory = Join-Path $ProjectDirectory "assets\Enemies\ZombieNode\Levels\MinionActivate"
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("defend-the-data-zombie-activate-" + [guid]::NewGuid().ToString("N"))
$frameDirectory = Join-Path $temporaryRoot "frames"
$frameSize = 360
$columns = 13
$framesPerSecond = 24.0

if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "Missing Zombie Node activation source: $SourcePath"
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $frameDirectory -Force | Out-Null

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Write-ActivationSpriteFrames {
    param(
        [string]$ResourcePath,
        [int]$FrameCount
    )

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine("[gd_resource type=`"SpriteFrames`" load_steps=$($FrameCount + 2) format=3]")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine('[ext_resource type="Texture2D" path="res://assets/Enemies/ZombieNode/Levels/MinionActivate/ZombieNodeMinionLV1ActivateAtlas.png" id="1_atlas"]')
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
    [void]$builder.AppendLine('"loop": false,')
    [void]$builder.AppendLine('"name": &"activate",')
    [void]$builder.AppendLine('"speed": ' + $framesPerSecond.ToString("0.0", [Globalization.CultureInfo]::InvariantCulture))
    [void]$builder.AppendLine("}]")
    Write-Utf8NoBom $ResourcePath $builder.ToString()
}

try {
    & $ffmpeg -y -hide_banner -loglevel error -i $SourcePath `
        -vf "fps=24,scale=360:360:flags=lanczos,format=rgba,colorkey=0xFFFFFF:0.12:0.0" `
        (Join-Path $frameDirectory "frame_%04d.png")
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed while extracting the Zombie Node activation frames"
    }

    $frameCount = @(Get-ChildItem -LiteralPath $frameDirectory -Filter "frame_*.png" -File).Count
    if ($frameCount -le 0) {
        throw "No Zombie Node activation frames were generated"
    }

    & $ffmpeg -y -hide_banner -loglevel error -framerate 24 `
        -i (Join-Path $frameDirectory "frame_%04d.png") `
        -vf "tile=13x12:nb_frames=$frameCount" -frames:v 1 `
        (Join-Path $outputDirectory "ZombieNodeMinionLV1ActivateAtlas.png")
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed while assembling the Zombie Node activation atlas"
    }

    Write-ActivationSpriteFrames `
        (Join-Path $outputDirectory "ZombieNodeMinionLV1ActivateSpriteFrames.tres") `
        $frameCount
    Write-Host "Built the $frameCount-frame Zombie Node LV1 minion activation atlas."
}
finally {
    $resolvedTemporaryRoot = [System.IO.Path]::GetFullPath($temporaryRoot)
    $resolvedSystemTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($resolvedTemporaryRoot.StartsWith($resolvedSystemTemp, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTemporaryRoot)) {
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force
    }
}
