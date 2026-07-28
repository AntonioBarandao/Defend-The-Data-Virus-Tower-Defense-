param(
    [string]$AntiGuardianSourceDirectory = "C:\Users\jonhu\Downloads\Anti-Cyberguardian",
    [string]$BotnetSourceDirectory = "C:\Users\jonhu\Downloads\Botnet  - Zombie Node\Botnet-Node",
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot),
    [string]$OnlyAnimation = ""
)

$ErrorActionPreference = "Stop"

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$python = (Get-Command python -ErrorAction Stop).Source
$backgroundTool = Join-Path $ProjectDirectory "tools\remove_green_dominant_background.py"
$antiOutputDirectory = Join-Path $ProjectDirectory "assets\Enemies\AntiCyberguardian\Animations"
$botnetOutputDirectory = Join-Path $ProjectDirectory "assets\Enemies\BotnetNode\Levels\Animations\FinalBoss"
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
    "defend-the-data-anti-cyberguardian-" + [guid]::NewGuid().ToString("N")
)
$frameSize = 512
$columns = 10
$framesPerSecond = 24.0

$animations = @(
    @{
        SourceDirectory = $AntiGuardianSourceDirectory
        OutputDirectory = $antiOutputDirectory
        Source = "Anti-Cyberguardian_Ability_Activate.mp4"
        Name = "AntiCyberguardianAbilityActivate"
        Track = "ability_activate"
        Loop = $false
    },
    @{
        SourceDirectory = $AntiGuardianSourceDirectory
        OutputDirectory = $antiOutputDirectory
        Source = "Anti-Cyberguardian_Ability_Idle.mp4"
        Name = "AntiCyberguardianAbilityIdle"
        Track = "ability_idle"
        Loop = $true
    },
    @{
        SourceDirectory = $AntiGuardianSourceDirectory
        OutputDirectory = $antiOutputDirectory
        Source = "Anti-Cyberguardian_Appear.mp4"
        Name = "AntiCyberguardianAppear"
        Track = "appear"
        Loop = $false
    },
    @{
        SourceDirectory = $AntiGuardianSourceDirectory
        OutputDirectory = $antiOutputDirectory
        Source = "Anti-Cyberguardian_Cloak_Disappear.mp4"
        Name = "AntiCyberguardianCloakDisappear"
        Track = "cloak_disappear"
        Loop = $false
    },
    @{
        SourceDirectory = $AntiGuardianSourceDirectory
        OutputDirectory = $antiOutputDirectory
        Source = "Anti-Cyberguardian-Collapse.mp4"
        Name = "AntiCyberguardianCollapse"
        Track = "collapse"
        Loop = $false
    },
    @{
        SourceDirectory = $AntiGuardianSourceDirectory
        OutputDirectory = $antiOutputDirectory
        Source = "Anti-Cyberguardian-Disappear_Defeat.mp4"
        Name = "AntiCyberguardianDisappearDefeat"
        Track = "disappear_defeat"
        Loop = $false
    },
    @{
        SourceDirectory = $AntiGuardianSourceDirectory
        OutputDirectory = $antiOutputDirectory
        Source = "Anti-Cyberguardian-Panting.mp4"
        Name = "AntiCyberguardianPanting"
        Track = "panting"
        Loop = $true
    },
    @{
        SourceDirectory = $AntiGuardianSourceDirectory
        OutputDirectory = $antiOutputDirectory
        Source = "Anti-Cyberguardian-Struggle_Panting.mp4"
        Name = "AntiCyberguardianStrugglePanting"
        Track = "struggle_panting"
        Loop = $true
    },
    @{
        SourceDirectory = $BotnetSourceDirectory
        OutputDirectory = $botnetOutputDirectory
        Source = "Botnet_LV3_Appear-Hollow.mp4"
        Name = "BotnetNodeLV3AppearHollow"
        Track = "appear_hollow_lv3"
        Loop = $false
    },
    @{
        SourceDirectory = $BotnetSourceDirectory
        OutputDirectory = $botnetOutputDirectory
        Source = "Botnet_LV3_Appear-Anti.mp4"
        Name = "BotnetNodeLV3AppearAnti"
        Track = "appear_anti_lv3"
        Loop = $false
    },
    @{
        SourceDirectory = $BotnetSourceDirectory
        OutputDirectory = $botnetOutputDirectory
        Source = "Botnet_LV3_Appear-Destroy.mp4"
        Name = "BotnetNodeLV3AppearDestroy"
        Track = "destroy_lv3"
        Loop = $false
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
    [void]$builder.AppendLine('"speed": 24.0')
    [void]$builder.AppendLine("}]")
    Write-Utf8NoBom $ResourcePath $builder.ToString()
}

New-Item -ItemType Directory -Force -Path $antiOutputDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $botnetOutputDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $temporaryRoot | Out-Null

try {
    foreach ($animation in $animations) {
        if (-not [string]::IsNullOrWhiteSpace($OnlyAnimation) `
                -and $animation.Name -ne $OnlyAnimation) {
            continue
        }

        $sourcePath = Join-Path $animation.SourceDirectory $animation.Source
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Missing final boss animation source: $sourcePath"
        }

        $frameDirectory = Join-Path $temporaryRoot $animation.Name
        New-Item -ItemType Directory -Force -Path $frameDirectory | Out-Null
        $framePattern = Join-Path $frameDirectory "frame_%04d.png"
        & $ffmpeg -y -hide_banner -loglevel error -i $sourcePath `
            -vf "fps=24,scale=${frameSize}:${frameSize}:flags=lanczos,format=rgba" `
            $framePattern
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while extracting $($animation.Source)"
        }

        & $python $backgroundTool $frameDirectory `
            --excess-start 0 `
            --excess-full 10 `
            --green-start 0 `
            --green-full 20 `
            --despill `
            --hard-key `
            --clear-transparent-rgb
        if ($LASTEXITCODE -ne 0) {
            throw "Green-screen removal failed for $($animation.Source)"
        }

        $frameCount = @(
            Get-ChildItem -LiteralPath $frameDirectory -Filter "frame_*.png" -File
        ).Count
        if ($frameCount -le 0) {
            throw "No frames were generated from $($animation.Source)"
        }

        $rows = [math]::Ceiling($frameCount / $columns)
        $usePngAtlas = $animation.Name -eq "AntiCyberguardianAppear"
        $atlasExtension = if ($usePngAtlas) { "png" } else { "webp" }
        $atlasName = "$($animation.Name)Atlas.$atlasExtension"
        $atlasPath = Join-Path $animation.OutputDirectory $atlasName
        if ($usePngAtlas) {
            & $ffmpeg -y -hide_banner -loglevel error -framerate 24 `
                -i $framePattern `
                -vf "tile=${columns}x${rows}:nb_frames=$frameCount,format=rgba" `
                -frames:v 1 -c:v png -compression_level 9 -pred mixed `
                $atlasPath
        }
        else {
            & $ffmpeg -y -hide_banner -loglevel error -framerate 24 `
                -i $framePattern `
                -vf "tile=${columns}x${rows}:nb_frames=$frameCount,format=rgba" `
                -frames:v 1 -c:v libwebp -lossless 1 -compression_level 6 `
                $atlasPath
        }
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while assembling $atlasName"
        }

        $resourcePath = Join-Path $animation.OutputDirectory (
            "$($animation.Name)SpriteFrames.tres"
        )
        $projectRoot = [System.IO.Path]::GetFullPath(
            $ProjectDirectory
        ).TrimEnd("\")
        $absoluteOutput = [System.IO.Path]::GetFullPath(
            $animation.OutputDirectory
        )
        if (-not $absoluteOutput.StartsWith(
                $projectRoot + "\",
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
            throw "Animation output is outside the project: $absoluteOutput"
        }
        $relativeOutput = $absoluteOutput.Substring(
            $projectRoot.Length + 1
        ).Replace("\", "/")
        Write-SpriteFramesResource `
            -ResourcePath $resourcePath `
            -AtlasResourcePath "res://$relativeOutput/$atlasName" `
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
