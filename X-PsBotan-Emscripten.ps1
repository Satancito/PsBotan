[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "List_Modules")]
    [switch]
    $ListModules,

    [Parameter(ParameterSetName = "Build_Lib")]
    [switch]
    $Build, 

    [Parameter(ParameterSetName = "Build_Lib")]
    [string[]]
    $BotanModules = @(),

    [Parameter(ParameterSetName = "Build_Lib")]
    [string[]]
    $BotanOptions = @(),

    [Parameter(ParameterSetName = "Build_Lib")]
    [string]
    $DestinationDir = [string]::Empty,


    [Parameter(ParameterSetName = "Build_Lib")]
    [string]
    $DestinationDirSuffix = [string]::Empty
)

& git submodule init
& git submodule update --remote --recursive --force

$ErrorActionPreference = 'Stop'

Import-Module -Name "$PSScriptRoot/Z-PsBotan.ps1" -Force -NoClobber
Import-Module -Name "$PSScriptRoot/submodules/PsCoreFxs/Z-PsCoreFxs.ps1" -Force -NoClobber

$DestinationDir = [string]::IsNullOrWhiteSpace($DestinationDir) ? "$(Get-CppLibsDir)" : $DestinationDir

function Test-WindowsDependencyTools {
    Write-Host
    Write-InfoBlue "PSBotan - Emscripten - Test Windows dependency tools..."
    
    Write-InfoMagenta "== 7Zip"
    $command = Get-Command "$__PSCOREFXS_7_ZIP_EXE"
    Write-Host "$($command.Source)"
    & "$($command.Source)" h  "$($command.Source)"
    Write-Host

    Write-InfoMagenta "== Windows SubSystem for Linux"
    $command = Get-Command "wsl"
    Write-Host "$($command.Source)"
    & "$($command.Source)" --version
    Write-Host

    if ($ListModules.IsPresent) {
        Write-InfoMagenta "== Python"
        $command = Get-Command "python"
        Write-Host "$($command.Source)"
        & "$($command.Source)" --version
        Write-Host
    }
}

function Test-DependencyTools {
    Write-InfoBlue "PSBotan - Emscripten - Test dependency tools..."
    Write-Host

    Write-InfoMagenta "== Tar"
    $command = Get-Command "tar"
    Write-Host "$($command.Source)"
    & "$($command.Source)" h  "$($command.Source)"
    Write-Host

    Write-InfoMagenta "== Python"
    $command = Get-Command "python"
    Write-Host "$($command.Source)"
    & "$($command.Source)" --version
    Write-Host

    Write-InfoMagenta "== Make"
    $command = Get-Command "make"
    Write-Host "$($command.Source)"
    & "$($command.Source)" --version
    Write-Host

    Write-InfoMagenta "== Git"
    $command = Get-Command "git"
    Write-Host "$($command.Source)"
    & "$($command.Source)" --version
    Write-Host
}

function Build-BotanLibrary {
    if ($IsWindows) {
        Test-WindowsDependencyTools
        $scriptParameters = @{
            "Script"               = (Get-WslPath -Path "$PSCommandPath")
            "BotanModules"         = $BotanModules
            "BotanOptions"         = $BotanOptions
            "DestinationDir"       = (Get-WslPath -Path $DestinationDir)
            "DestinationDirSuffix" = $DestinationDirSuffix
        }
    
        Write-Warning "Incompatible platform: Windows. Using WSL."
        & wsl pwsh -Command {
            $params = $args[0]
            Write-Host "Wsl User: " -NoNewline ; & whoami
            & "$($params.Script)" -Build `
                -BotanModules $params.BotanModules `
                -BotanOptions $params.BotanOptions `
                -DestinationDir $params.DestinationDir `
                -DestinationDirSuffix $params.DestinationDirSuffix
        } -args $scriptParameters
        return
    
    }
    $DestinationDirSuffix = [string]::IsNullOrWhiteSpace($DestinationDirSuffix) ? [string]::Empty : "-$($DestinationDirSuffix)"
    $configurations = @{
        Debug   = @{
            Options = @("--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
            Name    = "Debug"
            CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/bin/EmscriptenWasmDebug"
        }
        Release = @{
            Options = @()
            Name    = "Release"
            CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/bin/EmscriptenWasmRelease"
        }
    }
    $options = @("--cpu=wasm", "--os=emscripten", "--cc=emcc", "--disable-shared-library")
    if ($BotanModules.Count -gt 0) {
        $options += "--minimized-build"
        $options += "--enable-modules=$($BotanModules -join ",")"
    }
    $options += $BotanOptions
    Test-DependencyTools
    Get-BotanSources
    New-CppLibsDir
    
    Install-EmscriptenSDK

    $configurations.Keys | ForEach-Object {
        $configuration = $configurations["$_"]
        $prefix = "Botan-$__PSBOTAN_BOTAN_VERSION-Emscripten-Wasm-$($configuration.Name)$DestinationDirSuffix"
        Write-Host
        Write-InfoBlue "█ PsBotan - Building `"$prefix`""
        Write-Host
        $prefix = "$DestinationDir/$prefix"
        try {
            New-Item -Path "$($configuration.CurrentWorkingDir)" -ItemType Directory -Force | Out-Null
            Push-Location  "$($configuration.CurrentWorkingDir)"
            & $env:EMSCRIPTEN_EMCONFIGURE python "$__PSBOTAN_BOTAN_EXPANDED_DIR/configure.py" $configuration.Options $options --prefix="$prefix"
            Remove-Item -Path "$prefix" -Force -Recurse -ErrorAction Ignore
            & $env:EMSCRIPTEN_EMMAKE make -j8 install
        }
        finally {
            Pop-Location
            Remove-Item -Path "$($configuration.CurrentWorkingDir)" -Force -Recurse -ErrorAction Ignore
        }
    }
    
}

if ($ListModules.IsPresent) {
    Show-BotanModules
    exit
}

if ($Build.IsPresent -or (!$Build.IsPresent)) {
    Build-BotanLibrary
    exit
}

