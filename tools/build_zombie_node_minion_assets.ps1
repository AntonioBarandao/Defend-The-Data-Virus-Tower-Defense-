param(
    [string]$SourceDirectory = "C:\Users\jonhu\Downloads\Botnet  - Zombie Node",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$python = (Get-Command python -ErrorAction Stop).Source
$backgroundTool = Join-Path $PSScriptRoot "remove_connected_background.py"
$minionSourceDirectory = Join-Path $SourceDirectory "Zombie-Minions"
$transformSource = Join-Path $SourceDirectory "Red-Mutant_Transform.mp4"
$outputDirectory = Join-Path $ProjectDirectory "assets\Enemies\ZombieNode\Minions"
$variantDirectory = Join-Path $outputDirectory "Variants"
$mutationDirectory = Join-Path $outputDirectory "Mutation"
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("defend-the-data-zombie-minions-" + [guid]::NewGuid().ToString("N"))
$frameDirectory = Join-Path $temporaryRoot "frames"

$variants = [ordered]@{
    "angry" = "Zombie-Node-Minion_Angry.png"
    "dizzy" = "Zombie-Node-Minion_Dizzy.png"
    "jealous" = "Zombie-Node-Minion_Jealous.png"
    "look" = "Zombie-Node-Minion_Look.png"
    "rampage" = "Zombie-Node-Minion_Rampage.png"
    "rip" = "Zombie-Node-Minion_RIP.png"
    "sad" = "Zombie-Node-Minion_Sad.png"
    "skull" = "Zombie-Node-Minion_Skull.png"
    "surprised" = "Zombie-Node-Minion_Suprised.png"
}

New-Item -ItemType Directory -Path $variantDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $mutationDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $frameDirectory -Force | Out-Null

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Write-MinionsSpriteFrames {
    param([string]$ResourcePath)

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine("[gd_resource type=`"SpriteFrames`" load_steps=$($variants.Count + 1) format=3]")
    [void]$builder.AppendLine()
    $resourceIndex = 1
    foreach ($entry in $variants.GetEnumerator()) {
        $assetName = "ZombieNodeMinion_{0}.png" -f ([Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($entry.Key))
        [void]$builder.AppendLine("[ext_resource type=`"Texture2D`" path=`"res://assets/Enemies/ZombieNode/Minions/Variants/$assetName`" id=`"$($resourceIndex)_$($entry.Key)`"]")
        $resourceIndex++
    }
    [void]$builder.AppendLine()
    [void]$builder.AppendLine("[resource]")
    [void]$builder.AppendLine("animations = [")
    $resourceIndex = 1
    $variantIndex = 0
    foreach ($entry in $variants.GetEnumerator()) {
        [void]$builder.AppendLine("{")
        [void]$builder.AppendLine('"frames": [{')
        [void]$builder.AppendLine('"duration": 1.0,')
        [void]$builder.AppendLine('"texture": ExtResource("' + $resourceIndex + '_' + $entry.Key + '")')
        [void]$builder.AppendLine("}],")
        [void]$builder.AppendLine('"loop": true,')
        [void]$builder.AppendLine('"name": &"' + $entry.Key + '",')
        [void]$builder.AppendLine('"speed": 1.0')
        [void]$builder.Append("}")
        [void]$builder.AppendLine($(if ($variantIndex -lt $variants.Count - 1) { "," } else { "" }))
        $resourceIndex++
        $variantIndex++
    }
    [void]$builder.AppendLine("]")
    Write-Utf8NoBom $ResourcePath $builder.ToString()
}

function Write-TransformSpriteFrames {
    param(
        [string]$ResourcePath,
        [int]$FrameCount,
        [int]$FrameSize = 480,
        [int]$Columns = 9,
        [double]$FramesPerSecond = 24.0
    )

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine("[gd_resource type=`"SpriteFrames`" load_steps=$($FrameCount + 2) format=3]")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine('[ext_resource type="Texture2D" path="res://assets/Enemies/ZombieNode/Minions/Mutation/RedMutantTransformAtlas.png" id="1_atlas"]')
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
        [void]$builder.AppendLine("{")
        [void]$builder.AppendLine('"duration": 1.0,')
        [void]$builder.AppendLine('"texture": SubResource("' + $id + '")')
        [void]$builder.Append("}")
        [void]$builder.AppendLine($(if ($index -lt $FrameCount - 1) { "," } else { "" }))
    }
    [void]$builder.AppendLine("],")
    [void]$builder.AppendLine('"loop": false,')
    [void]$builder.AppendLine('"name": &"transform",')
    [void]$builder.AppendLine('"speed": ' + $FramesPerSecond.ToString("0.0", [Globalization.CultureInfo]::InvariantCulture))
    [void]$builder.AppendLine("}]")
    Write-Utf8NoBom $ResourcePath $builder.ToString()
}

foreach ($entry in $variants.GetEnumerator()) {
    $sourcePath = Join-Path $minionSourceDirectory $entry.Value
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing Zombie Node minion source: $sourcePath"
    }
}
foreach ($requiredPath in @($transformSource, $backgroundTool)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing Zombie Node source asset: $requiredPath"
    }
}

try {
    foreach ($entry in $variants.GetEnumerator()) {
        $sourcePath = Join-Path $minionSourceDirectory $entry.Value
        $assetName = "ZombieNodeMinion_{0}.png" -f ([Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($entry.Key))
        $outputPath = Join-Path $variantDirectory $assetName
        & $ffmpeg -y -hide_banner -loglevel error -i $sourcePath `
            -vf "scale=720:720:flags=lanczos" -frames:v 1 $outputPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while preparing Zombie Node minion $($entry.Key)"
        }
        & $python $backgroundTool $outputPath
        if ($LASTEXITCODE -ne 0) {
            throw "Background removal failed for Zombie Node minion $($entry.Key)"
        }
    }

    Write-MinionsSpriteFrames (Join-Path $outputDirectory "ZombieNodeMinionSpriteFrames.tres")

    & $ffmpeg -y -hide_banner -loglevel error -i $transformSource `
        -vf "fps=24,scale=480:480:flags=lanczos" (Join-Path $frameDirectory "frame_%04d.png")
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed while extracting Red Mutant transform frames"
    }
    & $python $backgroundTool $frameDirectory
    if ($LASTEXITCODE -ne 0) {
        throw "Background removal failed for Red Mutant transform frames"
    }

    $frameCount = @(Get-ChildItem -LiteralPath $frameDirectory -Filter "frame_*.png" -File).Count
    if ($frameCount -le 0) {
        throw "No Red Mutant transform frames were generated"
    }
    & $ffmpeg -y -hide_banner -loglevel error -framerate 24 `
        -i (Join-Path $frameDirectory "frame_%04d.png") `
        -vf "tile=9x9:nb_frames=$frameCount" -frames:v 1 `
        (Join-Path $mutationDirectory "RedMutantTransformAtlas.png")
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed while assembling the Red Mutant transform atlas"
    }

    Write-TransformSpriteFrames `
        (Join-Path $mutationDirectory "RedMutantTransformSpriteFrames.tres") `
        $frameCount
    Write-Host "Built $($variants.Count) Zombie Node minions and $frameCount Red Mutant transform frames."
}
finally {
    $resolvedTemporaryRoot = [System.IO.Path]::GetFullPath($temporaryRoot)
    $resolvedSystemTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($resolvedTemporaryRoot.StartsWith($resolvedSystemTemp, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTemporaryRoot)) {
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force
    }
}
