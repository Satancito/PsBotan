[CmdletBinding()]
param (
    [Parameter(ParameterSetName = "List_Modules")]
    [switch]
    $ListModules,

    [Parameter(ParameterSetName = "Build_VisualCpp_Debug", Mandatory = $true)]
    [Parameter(ParameterSetName = "Build_Emscripten_Debug", Mandatory = $true)]
    [switch]
    $Build, 
    
    [Parameter(ParameterSetName = "Build_VisualCpp_Debug", Mandatory = $true)]
    [switch]
    $VisualCppCompiler,

    [Parameter(ParameterSetName = "Build_Emscripten_Debug", Mandatory = $true)]
    [switch]
    $EmscriptenCompiler,

    [Parameter(ParameterSetName = "Build_VisualCpp_Debug", Mandatory = $true)]
    [Parameter(ParameterSetName = "Build_Emscripten_Debug", Mandatory = $true)]
    [switch]
    $DebugMode,

    [Parameter(ParameterSetName = "Build_VisualCpp_Debug", Mandatory = $true)]
    [ValidateSet("2022")]
    [string]
    $VisualStudioVersion,

    [Parameter(ParameterSetName = "List_Modules", Mandatory = $true)]
    [Parameter(ParameterSetName = "Build_VisualCpp_Debug", Mandatory = $true)]
    [Parameter(ParameterSetName = "Build_Emscripten_Debug", Mandatory = $true)]
    [ValidateSet("3.2.0")]
    [string]
    $Version,

    [Parameter(ParameterSetName = "Build_VisualCpp_Debug", Mandatory = $false)]
    [Parameter(ParameterSetName = "Build_Emscripten_Debug", Mandatory = $false)]
    [string[]]
    $BotanModules = @(),

    [Parameter(ParameterSetName = "Build_VisualCpp_Debug", Mandatory = $false)]
    [Parameter(ParameterSetName = "Build_Emscripten_Debug", Mandatory = $false)]
    [string[]]
    $BotanOptions = @(),

    [Parameter()]
    [string]
    $DestinationDir = "$PSScriptRoot/Dist",

    [Parameter(ParameterSetName = "Build_VisualCpp_Debug", Mandatory = $true)]
    [string]
    [ValidateSet("X86", "X64", "ARM64")]
    $Target
)

$ErrorActionPreference = "Stop"
Import-Module -Name "$(Get-Item "$PSScriptRoot/Z-PsCoreFxs.ps1")" -Force -NoClobber
Write-InfoDarkGray "▶▶▶ Running: $PSCommandPath"

$VISUAL_CPP_DEBUG_PARAMETER_SET = "Build_VisualCpp_Debug"
$EMSCRIPTEN_DEBUG_PARAMETER_SET = "Build_Emscripten_Debug"
$VISUAL_CPP_PARAMETER_SETS = @($VISUAL_CPP_DEBUG_PARAMETER_SET)
$EMSCRIPTEN_PARAMETER_SETS = @($EMSCRIPTEN_DEBUG_PARAMETER_SET)
$_7_ZIP_EXE = "C:\Program Files\7-Zip\7z.exe"
$TEMP_DIR = "$(Get-UserHome)/.PsBotan"
$EXTRA_WORKING_BUILD_DIR = "$TEMP_DIR/Build"
$BOTAN_URL = "https://botan.randombit.net/releases/Botan-$Version.tar.xz" 
$BOTAN_UNZIPPED_DIR = "$TEMP_DIR/Botan-$Version"
$BOTAN_TAR_XZ = "$TEMP_DIR/Botan-$Version.tar.xz"
$BOTAN_TAR = "$TEMP_DIR/Botan-$Version.tar"
$EMSCRIPTEN_INSTALL_SCRIPT = "$PSScriptRoot/modules/InsaneEmscripten/X-InsaneEm-InstallEmscripten.ps1"
$VCVARS_SCRIPT = "C:/Program Files/Microsoft Visual Studio/$VisualStudioVersion/Community/VC/Auxiliary/Build/vcvarsall.bat" 
$VCVARS_X86_SCRIPT = "C:/Program Files/Microsoft Visual Studio/$VisualStudioVersion/Community/VC/Auxiliary/Build/vcvars32.bat" 
$VCVARS_X64_SCRIPT = "C:/Program Files/Microsoft Visual Studio/$VisualStudioVersion/Community/VC/Auxiliary/Build/vcvars64.bat" 
$VCVARS_ARM64_SCRIPT = "C:/Program Files/Microsoft Visual Studio/$VisualStudioVersion/Community/VC/Auxiliary/Build/vcvarsamd64_arm64.bat" 
$WINDOWS_X86_TARGET = "X86"
$WINDOWS_X64_TARGET = "X64"
$WINDOWS_ARM64_TARGET = "ARM64"

function Set-Vcvars {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("X86", "X64", "ARM64")]
        [System.String]
        $Target,
        
        [Parameter()]
        [switch]
        $ShowValues
    )
    Write-Host
        Write-InfoBlue "Initialize environment " -NoNewline
    switch -CaseSensitive ($Target) {
        ($WINDOWS_X86_TARGET) {
            $vcvars = $VCVARS_X86_SCRIPT
        }
        ($WINDOWS_X64_TARGET) {
            $vcvars = $VCVARS_X64_SCRIPT
        }
        ($WINDOWS_ARM64_TARGET) {
            $vcvars = $VCVARS_ARM64_SCRIPT
        }
        default {
            throw "Invalid target $Target"
        }
    }

    if (!(Test-Path -Path $vcvars -PathType Leaf)) {
        throw "Invalid vcvars file, it doesn't exist. ""$vcvars"""
    }
    Write-InfoBlue "Running: $vcvars"
    Write-Host
    $pattern = "^([_A-Za-z]+\w*)=(.+)$"
    & cmd /c """$vcvars""  && SET" | . { process {
            $result = [System.Text.RegularExpressions.Regex]::Matches($_, $pattern)
            if ($result.Success) {
                Set-LocalEnvironmentVariable "$($result.Groups[1].Value)" "$($result.Groups[2].Value)"
                if ($ShowValues.IsPresent) {
                    Write-Host "$($result.Groups[1].Value)" -NoNewline -ForegroundColor Green
                    Write-Host "=" -NoNewline -ForegroundColor Yellow
                    Write-Host  "$($result.Groups[2].Value)" -ForegroundColor White
                }
            }
            else {
                Write-InfoDarkGray $_
            }
        } 
    }
    Write-Host
       
}

function Test-DependencyTools {
    Write-Host
    Write-InfoBlue "Test dependency tools..."
    Write-Host
    $result = $true
    $result = $result -and (Test-Command "python --version")
    Write-Host
    
    $result = $result -and (Test-Command "make --version")
    Write-Host

    $result = $result -and (Test-Command "git --version")
    Write-Host

    if ($IsWindows) {
        if (Test-Path -Path $_7_ZIP_EXE -PathType Leaf) {
            $result = $result -and $true
            Write-Host "✅ Command: $_7_ZIP_EXE"
        }
        else {
            Write-Host "❌ Command: $_7_ZIP_EXE"
        }
        Write-Host
    }

    if ($IsLinux -or $IsMacOS) {
        $result = $result -and (Test-Command "tar --version")
        Write-Host
    }

    if (!$result) {
        throw "Dependency tools are required."
    }
}

function Get-Botan {
    Write-Host
    Write-InfoBlue "Downloading Botan Version: $Version"
    Write-Host
    New-Item -Path "$TEMP_DIR" -ItemType Directory -Force | Out-Null
    Remove-Item -Path "$BOTAN_UNZIPPED_DIR" -Force -Recurse -ErrorAction Ignore
    New-Item -Path "$BOTAN_UNZIPPED_DIR" -ItemType Directory -Force | Out-Null
    if (!(Test-Path -Path $BOTAN_TAR_XZ -PathType Leaf)) {
        Write-Host "Downloading $BOTAN_URL"
        Write-Host "$BOTAN_URL"
        Invoke-WebRequest -Uri "$BOTAN_URL" -OutFile "$BOTAN_TAR_XZ"
    }
    else {
        Write-Host "Skipping download $BOTAN_URL"
    }
    Write-Host "Unzipping $(Split-Path $BOTAN_TAR_XZ -Leaf)..."
    if ($IsWindows) {
        & "$_7_ZIP_EXE" x -aoa -o"$TEMP_DIR" "$BOTAN_TAR_XZ" | Out-Null
        & "$_7_ZIP_EXE" x -aoa -o"$TEMP_DIR" -r "$BOTAN_TAR" | Out-Null
        Remove-Item -Force -Path "$BOTAN_TAR"
    }
    if ($IsLinux -or $IsMacOS) {
        tar -xf "$BOTAN_TAR_XZ" -C "$TEMP_DIR" --overwrite
    }
}

function Show-BotanModules {
    Write-Host
    Write-InfoBlue "Botan modules list:"
    Write-Host
    & python "$BOTAN_UNZIPPED_DIR\configure.py" --list-modules
}

function Build-Botan {
    try {
        Write-Host
        Write-InfoBlue "Building Botan Version: $Version"
        Write-Host
        if (!$Run.IsPresent) {
            $null = Test-Command "git submodule init" -ThrowOnFailure
            $null = Test-Command "git submodule update --remote --recursive" -ThrowOnFailure
        }

        Remove-Item "$EXTRA_WORKING_BUILD_DIR" -Force -Recurse -ErrorAction Ignore
        New-Item "$EXTRA_WORKING_BUILD_DIR" -ItemType Directory -Force | Out-Null
        #Push-Location "$EXTRA_WORKING_BUILD_DIR"
        Push-Location "$BOTAN_UNZIPPED_DIR"
    
        $prefix = "Botan-$version"
        $options = @()
        if ($DebugMode.IsPresent) {
            $options += "--debug-mode"
            $options += "--with-debug-info"
            $options += "--no-optimizations"
            $options += "--link-method=copy"
            $prefix += "-Debug"
        }
        else {
            $prefix += "-Release"
        }
        # WINDOWS - VISUAL C++
        if ($PSCmdlet.ParameterSetName -in $VISUAL_CPP_PARAMETER_SETS) {
            if (!($env:PROCESSOR_ARCHITECTURE -eq "AMD64")) {
                Write-Warning "Windows x64 operating system is required."
                exit
            }

            $prefix += "-Windows-$Target-Msvc"
            $options += "--cpu=$Target"
            $options += "--os=windows"
            $options += "--cc=msvc"
            $options += "--minimized-build"
            $options += "--prefix=$DestinationDir/$prefix"
            Write-InfoBlue "█ Building - $prefix"
            Set-Vcvars $Target -ShowValues
            Remove-Item "$DestinationDir/$prefix" -Force -Recurse -ErrorAction Ignore
            New-Item "$DestinationDir/$prefix" -ItemType Directory -Force | Out-Null
            & python "$BOTAN_UNZIPPED_DIR/configure.py" $options $BotanOptions --enable-modules=$($BotanModules -join ",")
            & nmake install
            exit
        }
        # EMSCRIPTEN
        if ($PSCmdlet.ParameterSetName -in $EMSCRIPTEN_PARAMETER_SETS) {
            & "$EMSCRIPTEN_INSTALL_SCRIPT" -Force
            $prefix += "-Emscripten"
            $options += "--cpu=wasm"
            $options += "--os=emscripten"
            $options += "--cc=emcc"
            $options += "--disable-shared-library"
            $options += "--minimized-build"
            $options += "--prefix=$DestinationDir/$prefix"
            Write-Host "█ Building - $prefix"
            if ($IsWindows) {
                Write-Warning "The compilation of Botan for Emscripten is not enabled due to issues with this platform. Use Linux, WSL instead."
                exit
            }
            Remove-Item "$DestinationDir/$prefix" -Force -Recurse -ErrorAction Ignore
            New-Item "$DestinationDir/$prefix" -ItemType Directory -Force | Out-Null
            & $env:EMSCRIPTEN_EMCONFIGURE python "$BOTAN_UNZIPPED_DIR/configure.py" $options $BotanOptions --enable-modules=$($BotanModules -join ",")
            & $env:EMSCRIPTEN_EMMAKE make make -C "$BOTAN_UNZIPPED_DIR/Makefile" install
            exit
        }
        exit
    }
    finally {
        Pop-Location
    }  
}

Test-DependencyTools 
Get-Botan

if ($ListModules.IsPresent) {
    Show-BotanModules
    exit 
}

if ($Build.IsPresent) {
    Build-Botan
}


