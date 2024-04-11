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
    $DestinationDirSuffix = [string]::Empty,

    [Parameter(ParameterSetName = "Build_Lib")]
    [ValidateSet("2022")]
    [string]
    $VisualStudioVersion = "2022",

    [Parameter(ParameterSetName = "Build_Lib")]
    [ValidateSet("Community", "Professional", "Enterprise")]
    [string]    
    $VisualStudioEdition = "Community"
)

$ErrorActionPreference = 'Stop'

Import-Module -Name "$PSScriptRoot/Z-PsBotan.ps1" -Force -NoClobber

if (!$IsWindows) {
    Write-Warning "Incompatible platform `"$(Get-OsName)`". Try Another."
    exit
}

if (!($env:PROCESSOR_ARCHITECTURE -eq "AMD64")) {
    Write-Warning "Windows x64 operating system is required."
    exit
}

$DestinationDir = [string]::IsNullOrWhiteSpace($DestinationDir) ? "$(Get-CppLibsDir)" : $DestinationDir

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
Get-BotanSources
New-CppLibsDir

function Build-BotanLibrary {
    $DestinationDirSuffix = [string]::IsNullOrWhiteSpace($DestinationDirSuffix) ? [string]::Empty : "-$($DestinationDirSuffix)"
    $configurations = @{
        DebugDesktopX86   = @{
            Options           = @("--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
            Name              = "Debug"
            Platform          = "Desktop"
            Target            = "X86"
            CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/bin/Desktop-X86-Debug"
            VcvarsParameters  = @("$__PSCOREFXS_VCVARS_ARCH_X86", "-vcvars_spectre_libs=spectre")
        }

        ReleaseDesktopX86 = @{
            Options           = @()
            Name              = "Release"
            Platform          = "Desktop"
            Target            = "X86"
            CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/bin/Desktop-X86-Release"
            VcvarsParameters  = @("$__PSCOREFXS_VCVARS_ARCH_X86", "-vcvars_spectre_libs=spectre")
        }

        DebugDesktopX64   = @{
            Options           = @("--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
            Name              = "Debug"
            Platform          = "Desktop"
            Target            = "X64"
            CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/bin/Desktop-X64-Debug"
            VcvarsParameters  = @("$__PSCOREFXS_VCVARS_ARCH_X64", "-vcvars_spectre_libs=spectre")
        }

        ReleaseDesktopX64 = @{
            Options           = @()
            Name              = "Release"
            Platform          = "Desktop"
            Target            = "X64"
            CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/bin/Desktop-X64-Release"
            VcvarsParameters  = @("$__PSCOREFXS_VCVARS_ARCH_X64", "-vcvars_spectre_libs=spectre")
        }

        DebugDesktopArm64   = @{
            Options           = @("--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
            Name              = "Debug"
            Platform          = "Desktop"
            Target            = "Arm64"
            CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/bin/Desktop-Arm64-Debug"
            VcvarsParameters  = @("$__PSCOREFXS_VCVARS_ARCH_ARM64", "-vcvars_spectre_libs=spectre")
        }

        ReleaseDesktopArm64 = @{
            Options           = @()
            Name              = "Release"
            Platform          = "Desktop"
            Target            = "Arm64"
            CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/bin/Desktop-Arm64-Release"
            VcvarsParameters  = @("$__PSCOREFXS_VCVARS_ARCH_ARM64", "-vcvars_spectre_libs=spectre")
        }
    }

    $options = @("--os=windows", "--cc=msvc")
    if ($BotanModules.Count -gt 0) {
        $options += "--minimized-build"
        $options += "--enable-modules=$($BotanModules -join ",")"
    }
    $options += $BotanOptions

    $configurations.Keys | ForEach-Object {
        $configuration = $configurations["$_"]
        $configuration.Options += $options
        $configuration.Options += "--cpu=$($configuration.Target)"
        $configuration.Script = "$PSCommandPath"
        $configuration.WorkingDirectory = "$PSScriptRoot"
        $configuration.DestinationDirSuffix = $DestinationDirSuffix
        $configuration.VisualStudioVersion = $VisualStudioVersion
        $configuration.VisualStudioEdition = $VisualStudioEdition
        $configuration.DestinationDir = $DestinationDir
        & pwsh -WorkingDirectory "$PSScriptRoot" -NoProfile -Command {
            $configuration = $args[0]
            Import-Module -Name "$($configuration.WorkingDirectory)/submodules/PsCoreFxs/Z-PsCoreFxs.ps1" -Force -NoClobber
            Import-Module -Name "$($configuration.WorkingDirectory)/Z-PsBotan.ps1" -Force -NoClobber
            Set-Vcvars -VisualStudioVersion "$($configuration.VisualStudioVersion)" -VisualStudioEdition "$($configuration.VisualStudioEdition)" -Parameters $configuration.VcvarsParameters
            $prefix = "Botan-$__PSBOTAN_BOTAN_VERSION-Windows-$($configuration.Platform)-$($configuration.Target)-$($configuration.Name)$($configuration.DestinationDirSuffix)"
            Write-Host
            Write-InfoBlue "█ PsBotan - Building `"$prefix`""
            Write-Host

            $prefix = "$($configuration.DestinationDir)/$prefix"
            try {
                New-Item -Path "$($configuration.CurrentWorkingDir)" -ItemType Directory -Force | Out-Null
                Push-Location  "$($configuration.CurrentWorkingDir)"
                $null = Test-ExternalCommand -Command "python `'$__PSBOTAN_BOTAN_EXPANDED_DIR/configure.py`' $($configuration.Options -join " ") --build-tool=ninja --prefix=$prefix" -ThrowOnFailure -ShowExitCode
                $null = Test-ExternalCommand -Command "ninja" -ThrowOnFailure -ShowExitCode
                Remove-Item -Path "$prefix" -Force -Recurse -ErrorAction Ignore
                $null = Test-ExternalCommand -Command "ninja install" -ThrowOnFailure -ShowExitCode
            }
            finally {
                Pop-Location
                Remove-Item -Path "$($configuration.CurrentWorkingDir)" -Force -Recurse -ErrorAction Ignore
            }
        } -args $configuration
    }
} 


if ($ListModules.IsPresent) {
    Show-BotanModules
    exit
}

if ($Build.IsPresent -or !$Build.IsPresent) {
    Build-BotanLibrary
    exit
}


