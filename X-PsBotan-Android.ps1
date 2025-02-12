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

    [Parameter(ParameterSetName = "Build_Lib")]
    [string]
    $AndroidAPI,

    [switch]
    [Parameter(ParameterSetName = "Build_Lib")]
    $ForceDownloadNDK,

    [switch]
    [Parameter(ParameterSetName = "Build_Lib")]
    $ForceDownloadBotan,

    [Parameter(Mandatory = $true, ParameterSetName = "Remove_Temp")]
    [switch]
    $Clean
)

$ErrorActionPreference = 'Stop'
Import-Module -Name "$PSScriptRoot/Z-PsBotan.ps1" -Force -NoClobber



function Test-WindowsDependencyTools {
    Write-Host
    Write-InfoBlue "PSBotan - Android - Test Windows dependency tools..."
    Assert-7ZipExecutable
    Assert-WslExecutable
    if ($ListModules.IsPresent) {
        Assert-PythonExecutable
    }
}

function Test-DependencyTools {
    Write-InfoBlue "PSBotan - Android - Test dependency tools..."
    Write-Host
    Assert-TarExecutable
    Assert-PythonExecutable
    Assert-MakeExecutable
    Assert-GitExecutable
    Assert-UnzipExecutable
}

function Build-BotanLibrary {
    $AndroidAPI = $AndroidAPI = Get-ValidAndroidNDKApi -Api $AndroidAPI -Latest -Assert
    $DestinationDir = [string]::IsNullOrWhiteSpace($DestinationDir) ? "$(Get-CppLibsDir)" : $DestinationDir
    if ($IsWindows) {
        Test-WindowsDependencyTools
        $scriptParameters = @{
            Script             = (Get-WslPath -Path "$PSCommandPath")
            BotanModules       = $BotanModules
            BotanOptions       = $BotanOptions
            DestinationDir     = (Get-WslPath -Path $DestinationDir)
            DistDirSuffix      = $DistDirSuffix
            AndroidAPI         = $AndroidAPI
            ForceDownloadNDK   = $ForceDownloadNDK.IsPresent
            ForceDownloadBotan = $ForceDownloadBotan.IsPresent
        }
        Write-Warning "Incompatible platform: Windows. Using WSL."
        & wsl pwsh -Command {
            $params = $args[0]
            Write-Host "Wsl User: " -NoNewline ; & whoami
            & "$($params.Script)" `
                -BotanModules $params.BotanModules `
                -BotanOptions $params.BotanOptions `
                -DestinationDir $params.DestinationDir `
                -DistDirSuffix $params.DistDirSuffix `
                -AndroidAPI $params.AndroidAPI `
                -ForceDownloadNDK:$params.ForceDownloadNDK `
                -ForceDownloadBotan:$params.ForceDownloadBotan

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
    Install-AndroidNDK -Force:$ForceDownloadNDK
    $androidNdkVariant = $__PSCOREFXS_ANDROID_NDK_OS_VARIANTS["$(Get-OsName -Minimal)"]
    $__PSBOTAN_ANDROID_BUILD_CONFIGURATIONS.Keys | ForEach-Object {
        $configuration = $__PSBOTAN_ANDROID_BUILD_CONFIGURATIONS["$_"]
        try {
            $prefix = "$DestinationDir/$($configuration.DistDirName -f @($AndroidAPI))$DistDirSuffix"
            Write-Host
            Write-InfoBlue "█ PsBotan - Building `"$prefix`""
            Write-Host
            New-Item -Path "$($configuration.CurrentWorkingDir)" -ItemType Directory -Force | Out-Null
            Push-Location  "$($configuration.CurrentWorkingDir)"
            $env:CXX = "$($androidNdkVariant.ToolchainsDir)/bin/$($configuration.Triplet)$AndroidAPI-$__PSCOREFXS_ANDROID_NDK_CLANG_PLUS_PLUS_EXE_SUFFIX"
            $env:AR = "$($androidNdkVariant.ToolchainsDir)/bin/$__PSCOREFXS_ANDROID_NDK_AR_EXE"
            $null = Test-ExternalCommand -Command "`"$__PSCOREFXS_PYTHON_EXE`" `"$__PSBOTAN_BOTAN_EXPANDED_DIR/configure.py`" $($configuration.Options) $($options) --prefix=$prefix" -ThrowOnFailure -ShowExitCode -NoAssertion
            Remove-Item -Path "$prefix" -Force -Recurse -ErrorAction Ignore
            $null = Test-ExternalCommand -Command "$env:EMSCRIPTEN_EMMAKE `"$__PSCOREFXS_MAKE_EXE`" install" -ThrowOnFailure -ShowExitCode -NoAssertion
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

