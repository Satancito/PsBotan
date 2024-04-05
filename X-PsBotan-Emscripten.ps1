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

Import-Module -Name "$PSScriptRoot/Z-PsBotan.ps1" -Force -NoClobber
Import-Module -Name "$PSScriptRoot/submodules/PsCoreFxs/Z-PsCoreFxs.ps1" -Force -NoClobber

$DestinationDir = [string]::IsNullOrWhiteSpace($DestinationDir) ? "$__CPP_LIBS_DIR" : $DestinationDir

function Test-WindowsDependencyTools {
    Write-Host
    Write-InfoBlue "PSBotan - Emscripten - Test Windows dependency tools..."
    
    Write-InfoMagenta "== 7Zip"
    $command = Get-Command "$__7_ZIP_EXE"
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
    Write-Host
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
            Cwd = "$__BOTAN_EXPANDED_DIR/bin/Debug"
        }
        Release = @{
            Options = @()
            Name    = "Release"
            Cwd = "$__BOTAN_EXPANDED_DIR/bin/Release"
        }
    }
    $options = @("--cpu=wasm", "--os=emscripten", "--cc=emcc", "--disable-shared-library")
    if ($BotanModules.Count -gt 0) {
        $options += "--minimized-build"
        $options += "--enable-modules=$($BotanModules -join ",")"
    }

    Test-DependencyTools
    Get-BotanSources
    New-CppLibsDir
    & "$__EMSCRIPTEN_INSTALL_SCRIPT" -Install

    $configurations.Keys | ForEach-Object {
        $configuration = $configurations["$_"]
        $prefix = "Botan-$__BOTAN_VERSION-Emscripten-Wasm-$($configuration.Name)$DestinationDirSuffix"
        Write-Host
        Write-InfoBlue "█ PsBotan - Building `"$prefix`""
        Write-Host
        Remove-Item -Path "$prefix" -Force -Recurse -ErrorAction Ignore
        try {
            New-Item -Path "$($configuration.Cwd)" -ItemType Directory -Force | Out-Null
            Push-Location  "$($configuration.Cwd)"
            & $env:EMSCRIPTEN_EMCONFIGURE python "$__BOTAN_EXPANDED_DIR/configure.py" $configuration.Options $options $BotanOptions --prefix="$DestinationDir/$prefix"
            & $env:EMSCRIPTEN_EMMAKE make -j8 install
        }
        finally {
            Pop-Location
        }
    }
    
}

if ($Build.IsPresent -or (!$ListModules.IsPresent)) {
    Build-BotanLibrary
    exit
}

if ($ListModules.IsPresent) {
    Show-BotanModules
    exit
}
