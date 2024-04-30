[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "List_Modules")]
    [switch]
    $ListModules,

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
    $DistDirSuffix = [string]::Empty,

    [switch]
    [Parameter(ParameterSetName = "Build_Lib")]
    $ForceInstallEmscriptenSDK,

    [switch]
    [Parameter(ParameterSetName = "Build_Lib")]
    $ForceDownloadBotan,

    [Parameter(Mandatory=$true, ParameterSetName = "Remove_Temp")]
    [switch]
    $Clean
)

$ErrorActionPreference = 'Stop'
Import-Module -Name "$PSScriptRoot/Z-PsBotan.ps1" -Force -NoClobber

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
    $DestinationDir = [string]::IsNullOrWhiteSpace($DestinationDir) ? "$(Get-CppLibsDir)" : $DestinationDir
    if ($IsWindows) {
        Test-WindowsDependencyTools
        $scriptParameters = @{
            "Script"         = (Get-WslPath -Path "$PSCommandPath")
            "BotanModules"   = $BotanModules
            "BotanOptions"   = $BotanOptions
            "DestinationDir" = (Get-WslPath -Path $DestinationDir)
            "DistDirSuffix"  = $DistDirSuffix
        }
    
        Write-Warning "Incompatible platform: Windows. Using WSL."
        & wsl pwsh -Command {
            $params = $args[0]
            Write-Host "Wsl User: " -NoNewline ; & whoami
            & "$($params.Script)" `
                -BotanModules $params.BotanModules `
                -BotanOptions $params.BotanOptions `
                -DestinationDir $params.DestinationDir `
                -DistDirSuffix $params.DistDirSuffix
        } -args $scriptParameters
        return
    
    }
    $DistDirSuffix = [string]::IsNullOrWhiteSpace($DistDirSuffix) ? [string]::Empty : "-$($DistDirSuffix)"
    $options = @()
    if ($BotanModules.Count -gt 0) {
        $options += "--minimized-build"
        $options += "--enable-modules=$($BotanModules -join ",")"
    }
    $options += $BotanOptions
    Test-DependencyTools
    Get-BotanSources -Force:$ForceDownloadBotan
    New-CppLibsDir
    
    Install-EmscriptenSDK -Force:$ForceInstallEmscriptenSDK
    $__PSBOTAN_EMSCRIPTEN_BUILD_CONFIGURATIONS.Keys | ForEach-Object {
        $configuration = $__PSBOTAN_EMSCRIPTEN_BUILD_CONFIGURATIONS["$_"]
        try {
            $prefix = "$DestinationDir/$($configuration.DistDirName)$DistDirSuffix"
            Write-Host
            Write-InfoBlue "█ PsBotan - Building `"$($configuration.DistDirName)`""
            Write-Host
            New-Item -Path "$($configuration.CurrentWorkingDir)" -ItemType Directory -Force | Out-Null
            Push-Location  "$($configuration.CurrentWorkingDir)"
            $null = Test-ExternalCommand -Command "$env:EMSCRIPTEN_EMCONFIGURE $__PSCOREFXS_PYTHON_EXE `"$__PSBOTAN_BOTAN_EXPANDED_DIR/configure.py`" $($configuration.Options) $($options) --prefix=$prefix" -ThrowOnFailure -ShowExitCode -NoAssertion
            Remove-Item -Path "$prefix" -Force -Recurse -ErrorAction Ignore
            $null = Test-ExternalCommand -Command "$env:EMSCRIPTEN_EMMAKE make -j8 install" -ThrowOnFailure -ShowExitCode -NoAssertion
        }
        finally {
            Pop-Location
            Remove-Item -Path "$($configuration.CurrentWorkingDir)" -Force -Recurse -ErrorAction Ignore
        }
    }
    
}

if ($ListModules.IsPresent) {
    Show-BotanModules -Force:$ForceDownloadBotan
    exit
}

if ($Clean.IsPresent) {
    Remove-PsBotan -RemoveWsl
    exit
}

Build-BotanLibrary
exit


