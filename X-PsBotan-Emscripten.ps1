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

$ErrorActionPreference = 'Stop'

Import-Module -Name "$PSScriptRoot/Z-PsBotan.ps1" -Force -NoClobber

$DestinationDir = [string]::IsNullOrWhiteSpace($DestinationDir) ? "$(Get-CppLibsDir)" : $DestinationDir

function Test-WindowsDependencyTools {
    Write-Host
    Write-InfoBlue "PSBotan - Emscripten - Test Windows dependency tools..."
    Assert-7ZipExecutable
    Assert-WslExecutable
    if ($ListModules.IsPresent) {
        Assert-PythonExecutable
    }
}

function Test-DependencyTools {
    Write-InfoBlue "PSBotan - Emscripten - Test dependency tools..."
    Write-Host
    Assert-TarExecutable
    Assert-PythonExecutable
    Assert-MakeExecutable
    Assert-GitExecutable
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
    $options = @()
    if ($BotanModules.Count -gt 0) {
        $options += "--minimized-build"
        $options += "--enable-modules=$($BotanModules -join ",")"
    }
    $options += $BotanOptions
    Test-DependencyTools
    Get-BotanSources
    New-CppLibsDir
    
    Install-EmscriptenSDK
    $__PSBOTAN_EMSCRIPTEN_CONFIGURATIONS.Keys | ForEach-Object {
        $configuration = $__PSBOTAN_EMSCRIPTEN_CONFIGURATIONS["$_"]
        Write-Host
        Write-InfoBlue "█ PsBotan - Building `"$($configuration.DistDirName)`""
        Write-Host
        $prefix = "$DestinationDir/$($configuration.DistDirName)"
        Write-Host "$prefix"
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

