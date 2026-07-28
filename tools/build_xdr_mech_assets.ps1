param(
    [string]$SourceDirectory = "C:\Users\jonhu\Downloads\XDR Mech",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$ffprobe = (Get-Command ffprobe -ErrorAction Stop).Source
$python = (Get-Command python -ErrorAction Stop).Source
$backgroundTool = Join-Path $ProjectDirectory "tools\remove_green_dominant_background.py"
$outputDirectory = Join-Path $ProjectDirectory "assets\Towers\XDR_Mech"
$animationDirectory = Join-Path $outputDirectory "Animations"
New-Item -ItemType Directory -Path $animationDirectory -Force | Out-Null

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-Ffmpeg {
    param(
        [string]$InputPath,
        [string]$Filter,
        [string]$OutputPath
    )

    & $ffmpeg -y -hide_banner -loglevel error -i $InputPath -vf $Filter -frames:v 1 $OutputPath
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed while building $OutputPath"
    }
}

function Invoke-ConnectedGreenRemoval {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [int]$FrameSize = 360
    )

    $temporaryPath = Join-Path ([IO.Path]::GetTempPath()) (
        "xdr-connected-key-" + [guid]::NewGuid().ToString("N") + ".png"
    )
    try {
        & $ffmpeg -y -hide_banner -loglevel error -i $InputPath `
            -vf "format=rgba" -frames:v 1 $temporaryPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while preparing $InputPath"
        }
        & $python $backgroundTool $temporaryPath `
            --excess-start 0 `
            --excess-full 12 `
            --green-start 0 `
            --green-full 24 `
            --despill `
            --despill-all `
            --edge-connected-only `
            --clear-transparent-rgb `
            --hard-key
        if ($LASTEXITCODE -ne 0) {
            throw "Green removal failed for $InputPath"
        }
        & $ffmpeg -y -hide_banner -loglevel error -i $temporaryPath `
            -vf "scale=${FrameSize}:${FrameSize}:flags=lanczos" `
            -frames:v 1 -c:v png -compression_level 9 -pred mixed `
            $OutputPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while resizing $OutputPath"
        }
        & $python $backgroundTool $OutputPath `
            --despill-all `
            --preserve-alpha `
            --clear-transparent-rgb
        if ($LASTEXITCODE -ne 0) {
            throw "Final green despill failed for $OutputPath"
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Get-VideoFrameCount {
    param([string]$InputPath)

    $value = & $ffprobe -v error -select_streams v:0 -count_frames `
        -show_entries stream=nb_read_frames -of default=nokey=1:noprint_wrappers=1 $InputPath
    $parsedFrameCount = 0
    if ($LASTEXITCODE -ne 0 -or -not [int]::TryParse(($value | Select-Object -First 1), [ref]$parsedFrameCount)) {
        throw "Unable to read the frame count for $InputPath"
    }
    return $parsedFrameCount
}

function Write-LegSpriteFrames {
    param(
        [string]$ResourcePath,
        [string]$IdleTextureResourcePath,
        [string]$AtlasTextureResourcePath,
        [int]$FrameCount,
        [int]$FrameSize = 360,
        [int]$Columns = 8,
        [double]$FramesPerSecond = 24.0
    )

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine("[gd_resource type=`"SpriteFrames`" load_steps=$($FrameCount + 3) format=3]")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine("[ext_resource type=`"Texture2D`" path=`"$IdleTextureResourcePath`" id=`"1_idle`"]")
    [void]$builder.AppendLine("[ext_resource type=`"Texture2D`" path=`"$AtlasTextureResourcePath`" id=`"2_atlas`"]")
    [void]$builder.AppendLine()

    for ($index = 0; $index -lt $FrameCount; $index++) {
        $column = $index % $Columns
        $row = [math]::Floor($index / $Columns)
        $id = "AtlasTexture_{0:D3}" -f $index
        [void]$builder.AppendLine("[sub_resource type=`"AtlasTexture`" id=`"$id`"]")
        [void]$builder.AppendLine('atlas = ExtResource("2_atlas")')
        [void]$builder.AppendLine("region = Rect2($($column * $FrameSize), $($row * $FrameSize), $FrameSize, $FrameSize)")
        [void]$builder.AppendLine()
    }

    [void]$builder.AppendLine("[resource]")
    [void]$builder.AppendLine("animations = [{")
    [void]$builder.AppendLine('"frames": [{')
    [void]$builder.AppendLine('"duration": 1.0,')
    [void]$builder.AppendLine('"texture": ExtResource("1_idle")')
    [void]$builder.AppendLine("}],")
    [void]$builder.AppendLine('"loop": true,')
    [void]$builder.AppendLine('"name": &"idle",')
    [void]$builder.AppendLine('"speed": 1.0')
    [void]$builder.AppendLine("}, {")
    [void]$builder.AppendLine('"frames": [')
    for ($index = 0; $index -lt $FrameCount; $index++) {
        $id = "AtlasTexture_{0:D3}" -f $index
        [void]$builder.AppendLine("{")
        [void]$builder.AppendLine('"duration": 1.0,')
        [void]$builder.AppendLine('"texture": SubResource("' + $id + '")')
        [void]$builder.Append('}')
        if ($index -lt $FrameCount - 1) {
            [void]$builder.AppendLine(',')
        } else {
            [void]$builder.AppendLine()
        }
    }
    [void]$builder.AppendLine("],")
    [void]$builder.AppendLine('"loop": true,')
    [void]$builder.AppendLine('"name": &"walk",')
    [void]$builder.AppendLine('"speed": ' + $FramesPerSecond.ToString("0.0", [Globalization.CultureInfo]::InvariantCulture))
    [void]$builder.AppendLine("}]")

    Write-Utf8NoBom $ResourcePath $builder.ToString()
}

$displaySource = Join-Path $SourceDirectory "Display-XPR_Mech.png"
$levelOneHeadSource = Join-Path $SourceDirectory "XDR_Mech_LV1_Head_Image.png"
$levelTwoHeadSource = Join-Path $SourceDirectory "XDR_Mech_LV2_Head_Image.png"
$levelThreeHeadSource = Join-Path $SourceDirectory "XDR_Mech_LV3_Head_Image.png"
$levelFourHeadSource = Join-Path $SourceDirectory "XDR_Mech_LV4_Head_Image.png"
$levelOneLegSource = Join-Path $SourceDirectory "XDR_Mech_LV1-4_Leg_Image.png"
$levelFiveHeadSource = Join-Path $SourceDirectory "XDR_Mech_LV5_Head_Image.png"
$levelFiveLegSource = Join-Path $SourceDirectory "XDR_Mech_LV5_Leg_Image.png"
$levelOneWalkSource = Join-Path $SourceDirectory "XDR-Mech_LV1-Walking.mp4"
$levelFiveWalkSource = Join-Path $SourceDirectory "XDR-Mech_LV5-Walking.mp4"

foreach ($requiredPath in @(
    $displaySource,
    $levelOneHeadSource,
    $levelTwoHeadSource,
    $levelThreeHeadSource,
    $levelFourHeadSource,
    $levelOneLegSource,
    $levelFiveHeadSource,
    $levelFiveLegSource,
    $levelOneWalkSource,
    $levelFiveWalkSource
)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing XDR source asset: $requiredPath"
    }
}

Invoke-Ffmpeg $displaySource `
    "scale=720:720:flags=lanczos,format=rgba" `
    (Join-Path $outputDirectory "Display_XDR_Mech.png")
Invoke-Ffmpeg $levelOneHeadSource `
    "format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(gt(g(X,Y),max(r(X,Y),b(X,Y))+12),0,255)',scale=360:360:flags=lanczos" `
    (Join-Path $outputDirectory "XDR_Mech_LV1_Head_Idle.png")
Invoke-Ffmpeg $levelTwoHeadSource `
    "format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(gt(g(X,Y),max(r(X,Y),b(X,Y))+12),0,255)',scale=360:360:flags=lanczos" `
    (Join-Path $outputDirectory "XDR_Mech_LV2_Head_Idle.png")
Invoke-Ffmpeg $levelThreeHeadSource `
    "format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(gt(g(X,Y),max(r(X,Y),b(X,Y))+12),0,255)',scale=360:360:flags=lanczos" `
    (Join-Path $outputDirectory "XDR_Mech_LV3_Head_Idle.png")
Invoke-Ffmpeg $levelFourHeadSource `
    "format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(gt(g(X,Y),max(r(X,Y),b(X,Y))+12),0,255)',scale=360:360:flags=lanczos" `
    (Join-Path $outputDirectory "XDR_Mech_LV4_Head_Idle.png")
Invoke-Ffmpeg $levelOneLegSource `
    "format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(gt(g(X,Y),max(r(X,Y),b(X,Y))+12),0,255)',scale=360:360:flags=lanczos" `
    (Join-Path $outputDirectory "XDR_Mech_LV1_Leg_Idle.png")
Invoke-ConnectedGreenRemoval `
    $levelFiveHeadSource `
    (Join-Path $outputDirectory "XDR_Mech_LV5_Head_Idle.png")
Invoke-ConnectedGreenRemoval `
    $levelFiveLegSource `
    (Join-Path $outputDirectory "XDR_Mech_LV5_Leg_Idle.png")

$levelOneFrameCount = Get-VideoFrameCount $levelOneWalkSource
$levelFiveFrameCount = Get-VideoFrameCount $levelFiveWalkSource
Invoke-Ffmpeg $levelOneWalkSource `
    "fps=24,format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(gt(g(X,Y),max(r(X,Y),b(X,Y))+12),0,255)',scale=360:360:flags=lanczos,tile=8x10" `
    (Join-Path $animationDirectory "XDR_Mech_LV1_Leg_Walk_Atlas_24fps.png")
Invoke-Ffmpeg $levelFiveWalkSource `
    "fps=24,format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(gt(g(X,Y),max(r(X,Y),b(X,Y))+12),0,255)',scale=360:360:flags=lanczos,tile=8x10" `
    (Join-Path $animationDirectory "XDR_Mech_LV5_Leg_Walk_Atlas_24fps.png")

Write-LegSpriteFrames `
    (Join-Path $outputDirectory "XDRMechLegSpriteFrames.tres") `
    "res://assets/Towers/XDR_Mech/XDR_Mech_LV1_Leg_Idle.png" `
    "res://assets/Towers/XDR_Mech/Animations/XDR_Mech_LV1_Leg_Walk_Atlas_24fps.png" `
    $levelOneFrameCount
Write-LegSpriteFrames `
    (Join-Path $outputDirectory "XDRMechLV5LegSpriteFrames.tres") `
    "res://assets/Towers/XDR_Mech/XDR_Mech_LV5_Leg_Idle.png" `
    "res://assets/Towers/XDR_Mech/Animations/XDR_Mech_LV5_Leg_Walk_Atlas_24fps.png" `
    $levelFiveFrameCount

Write-Host "Built XDR Mech assets in $outputDirectory"
Write-Host "LV1 walking frames: $levelOneFrameCount"
Write-Host "LV5 walking frames: $levelFiveFrameCount"
