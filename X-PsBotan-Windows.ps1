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
    $DistDirSuffix = [string]::Empty,

    [Parameter(ParameterSetName = "Build_Lib")]
    [ValidateSet("2022")]
    [string]
    $VisualStudioVersion = "2022",

    [Parameter(ParameterSetName = "Build_Lib")]
    [ValidateSet("Community", "Professional", "Enterprise")]
    [string]    
    $VisualStudioEdition = "Community",

    [switch]
    [Parameter(ParameterSetName = "Build_Lib")]
    $ForceDownloadBotan
)

$ErrorActionPreference = 'Stop'
Import-Module -Name "$PSScriptRoot/Z-PsBotan.ps1" -Force -NoClobber
$DestinationDir = [string]::IsNullOrWhiteSpace($DestinationDir) ? "$(Get-CppLibsDir)" : $DestinationDir

if (!$IsWindows) {
    Write-Warning "Incompatible platform `"$(Get-OsName)`". Try Another."
    exit
}

if (!($env:PROCESSOR_ARCHITECTURE -eq "AMD64")) {
    Write-Warning "Windows x64 processor architecture is required."
    exit
}


function Test-DependencyTools {
    Write-Host
    Write-InfoBlue "PSBotan - Test dependency tools..."
    Assert-7ZipExecutable
    Assert-PythonExecutable
    Assert-MakeExecutable
    Assert-GitExecutable
    Assert-NinjaBuildExecutable
}

Test-DependencyTools
Get-BotanSources -Force:$ForceDownloadBotan
New-CppLibsDir

function Build-BotanLibrary {
    $DistDirSuffix = [string]::IsNullOrWhiteSpace($DistDirSuffix) ? [string]::Empty : "-$($DistDirSuffix)"
    
    $options = @("--os=windows", "--cc=msvc")
    if ($BotanModules.Count -gt 0) {
        $options += "--minimized-build"
        $options += "--enable-modules=$($BotanModules -join ",")"
    }
    $options += $BotanOptions

    $__PSBOTAN_WINDOWS_BUILD_CONFIGURATIONS.Keys | ForEach-Object {
        $configuration = $__PSBOTAN_WINDOWS_BUILD_CONFIGURATIONS["$_"]
        $configuration.Options += $options
        $configuration.Options += "--cpu=$($configuration.ConfigureTarget)"
        $configuration.Script = "$PSCommandPath"
        $configuration.WorkingDirectory = "$PSScriptRoot"
        $configuration.DistDirSuffix = $DistDirSuffix
        $configuration.VisualStudioVersion = $VisualStudioVersion
        $configuration.VisualStudioEdition = $VisualStudioEdition
        $configuration.DestinationDir = $DestinationDir
        & pwsh -WorkingDirectory "$PSScriptRoot" -NoProfile -Command {
            $configuration = $args[0]
            Import-Module -Name "$($configuration.WorkingDirectory)/submodules/PsCoreFxs/Z-PsCoreFxs.ps1" -Force -NoClobber
            Import-Module -Name "$($configuration.WorkingDirectory)/Z-PsBotan.ps1" -Force -NoClobber
            Set-Vcvars -VisualStudioVersion "$($configuration.VisualStudioVersion)" -VisualStudioEdition "$($configuration.VisualStudioEdition)" -Parameters $configuration.VcvarsParameters
            $prefix = "$($configuration.DistDirName)$($configuration.DistDirSuffix)"
            Write-Host
            Write-InfoBlue "█ PsBotan - Building `"$prefix`""
            Write-Host

            $prefix = "$($configuration.DestinationDir)/$prefix"
            try {
                New-Item -Path "$($configuration.CurrentWorkingDir)" -ItemType Directory -Force | Out-Null
                Push-Location  "$($configuration.CurrentWorkingDir)"
                $null = Test-ExternalCommand -Command "$__PSCOREFXS_PYTHON_EXE `'$__PSBOTAN_BOTAN_EXPANDED_DIR/configure.py`' $($configuration.Options -join " ") --build-tool=ninja --prefix=$prefix" -ThrowOnFailure -ShowExitCode -NoAssertion
                $null = Test-ExternalCommand -Command "$__PSCOREFXS_NINJA_EXE" -ThrowOnFailure -ShowExitCode -NoAssertion
                Remove-Item -Path "$prefix" -Force -Recurse -ErrorAction Ignore
                $null = Test-ExternalCommand -Command "$__PSCOREFXS_NINJA_EXE install" -ThrowOnFailure -ShowExitCode -NoAssertion
            }
            finally {
                Pop-Location
                Remove-Item -Path "$($configuration.CurrentWorkingDir)" -Force -Recurse -ErrorAction Ignore
            }
        } -args $configuration
    }
} 


if ($ListModules.IsPresent) {
    Show-BotanModules -Force:$ForceDownloadBotan
    exit
}

if ($Build.IsPresent -or !$Build.IsPresent) {
    Build-BotanLibrary
    exit
}


