param(
    [string]$BotnetSourceDirectory = "C:\Users\jonhu\Downloads\Botnet  - Zombie Node",
    [string]$VirusSourceDirectory = "C:\Users\jonhu\Downloads\Virus Types",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$outputDirectory = Join-Path $ProjectDirectory "assets\Enemies\BotnetNode\AntiCharge"
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("defend-the-data-botnet-minions-" + [guid]::NewGuid().ToString("N"))
$frameSize = 240
$columns = 16
$framesPerSecond = 24.0
$greenSpillFilter = "geq=r='r(X,Y)':g='if(gt(g(X,Y),max(r(X,Y),b(X,Y))*1.20),max(r(X,Y),b(X,Y)),g(X,Y))':b='b(X,Y)':a='alpha(X,Y)'"

$staticAssets = @(
    @{
        Source = Join-Path $BotnetSourceDirectory "Botnet-Minion\Botnet-Minion.png"
        Output = "BotnetMinion.png"
        Key = "0x2DD51F"
        Similarity = 0.20
    },
    @{
        Source = Join-Path $BotnetSourceDirectory "Botnet-Minion\Botnet-Minion_AntiCharged.png"
        Output = "BotnetMinionAntiCharged.png"
        Key = "0x2ED126"
        Similarity = 0.20
    },
    @{
        Source = Join-Path $VirusSourceDirectory "Red-Virus_AntiCharged.png"
        Output = "RedVirusAntiCharged.png"
        Key = "0x599C5C"
        Similarity = 0.22
    },
    @{
        Source = Join-Path $VirusSourceDirectory "Armored-Virus_AntiCharged.png"
        Output = "ArmoredVirusAntiCharged.png"
        Key = "0x1EEF1D"
        Similarity = 0.20
    },
    @{
        Source = Join-Path $VirusSourceDirectory "Mutant-Virus_AntiCharged.png"
        Output = "MutantVirusAntiCharged.png"
        Key = "0x659160"
        Similarity = 0.20
    }
)

$animations = @(
    @{
        Source = Join-Path $BotnetSourceDirectory "AntiCharge-VFX_Begin.mp4"
        Name = "AntiChargeBegin"
        Track = "begin"
        Key = "0x10CE1D"
        Similarity = 0.24
    },
    @{
        Source = Join-Path $BotnetSourceDirectory "AntiCharge-VFX_End.mp4"
        Name = "AntiChargeEnd"
        Track = "end"
        Key = "0x10CE1D"
        Similarity = 0.24
    },
    @{
        Source = Join-Path $VirusSourceDirectory "Red_Virus_Anti-Transform.mp4"
        Name = "RedVirusAntiTransform"
        Track = "transform"
        Key = "0x51A554"
        Similarity = 0.22
    },
    @{
        Source = Join-Path $VirusSourceDirectory "Armored_Virus_Anti-Transform.mp4"
        Name = "ArmoredVirusAntiTransform"
        Track = "transform"
        Key = "0x23DE27"
        Similarity = 0.22
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
        [int]$FrameCount
    )

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
    [void]$builder.AppendLine('"loop": false,')
    [void]$builder.AppendLine('"name": &"' + $TrackName + '",')
    [void]$builder.AppendLine('"speed": ' + $framesPerSecond.ToString("0.0", [Globalization.CultureInfo]::InvariantCulture))
    [void]$builder.AppendLine("}]")
    Write-Utf8NoBom $ResourcePath $builder.ToString()
}

try {
    foreach ($asset in $staticAssets) {
        if (-not (Test-Path -LiteralPath $asset.Source)) {
            throw "Missing Botnet anti-charge source: $($asset.Source)"
        }
        $outputPath = Join-Path $outputDirectory $asset.Output
        $filter = "scale=480:480:flags=lanczos,format=rgba,colorkey=$($asset.Key):$($asset.Similarity):0.025,$greenSpillFilter"
        & $ffmpeg -y -hide_banner -loglevel error -i $asset.Source `
            -vf $filter -frames:v 1 $outputPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while preparing $($asset.Output)"
        }
        Write-Host "Built $($asset.Output)."
    }

    foreach ($animation in $animations) {
        if (-not (Test-Path -LiteralPath $animation.Source)) {
            throw "Missing Botnet anti-charge source: $($animation.Source)"
        }

        $frameDirectory = Join-Path $temporaryRoot $animation.Name
        New-Item -ItemType Directory -Path $frameDirectory -Force | Out-Null
        $framePattern = Join-Path $frameDirectory "frame_%04d.png"
        $filter = "fps=24,scale=${frameSize}:${frameSize}:flags=lanczos,format=rgba,colorkey=$($animation.Key):$($animation.Similarity):0.025,$greenSpillFilter"
        & $ffmpeg -y -hide_banner -loglevel error -i $animation.Source `
            -vf $filter $framePattern
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while extracting $($animation.Name)"
        }

        $frameCount = @(
            Get-ChildItem -LiteralPath $frameDirectory -Filter "frame_*.png" -File
        ).Count
        if ($frameCount -le 0) {
            throw "No frames were generated for $($animation.Name)"
        }

        $rows = [math]::Ceiling($frameCount / $columns)
        $atlasName = "$($animation.Name)Atlas.webp"
        $atlasPath = Join-Path $outputDirectory $atlasName
        & $ffmpeg -y -hide_banner -loglevel error -framerate 24 `
            -i $framePattern `
            -vf "tile=${columns}x${rows}:nb_frames=$frameCount" `
            -frames:v 1 -c:v libwebp -quality 92 -compression_level 6 $atlasPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while assembling $atlasName"
        }

        Write-SpriteFramesResource `
            -ResourcePath (Join-Path $outputDirectory "$($animation.Name)SpriteFrames.tres") `
            -AtlasResourcePath "res://assets/Enemies/BotnetNode/AntiCharge/$atlasName" `
            -TrackName $animation.Track `
            -FrameCount $frameCount
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
