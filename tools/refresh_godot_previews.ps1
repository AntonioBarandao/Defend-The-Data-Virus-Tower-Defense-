param(
    [switch]$Full
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $projectRoot

$godotProcess = Get-Process | Where-Object { $_.ProcessName -match "Godot|godot" } | Select-Object -First 1
if ($godotProcess) {
    Write-Host "Godot is running as process $($godotProcess.Id). Close Godot, then run this script again."
    exit 1
}

$targets = @(
    ".godot/editor/filesystem_cache10",
    ".godot/editor/filesystem_update4",
    ".godot/editor/quick_open_dialog_cache.cfg",
    ".godot/imported",
    ".godot/shader_cache"
)

if ($Full) {
    $targets += @(
        ".godot/editor",
        ".godot/uid_cache.bin",
        ".godot/global_script_class_cache.cfg",
        ".godot/scene_groups_cache.cfg"
    )
}

foreach ($target in $targets) {
    $path = Join-Path $projectRoot $target
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Recurse -Force
        Write-Host "Removed $target"
    }
}

Write-Host "Preview/import caches cleared. Reopen the project in Godot and let it finish reimporting."
