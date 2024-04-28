$ErrorActionPreference = 'Stop'

Import-Module -Name "$PSScriptRoot/submodules/PsCoreFxs/Z-PsCoreFxs.ps1" -Force -NoClobber

# MARK: █ Constants
$__PSBOTAN_TEMP_DIR = "$(Get-UserHome)/.PsBotan"
$__PSBOTAN_GITHUB_URL = "https://github.com/Satancito/PsBotan.git"; $null = $__PSBOTAN_GITHUB_URL
$__PSBOTAN_BOTAN_VERSION = "3.4.0" # █> Update on next version.
$__PSBOTAN_BOTAN_MAJOR_VERSION = "$("$__PSBOTAN_BOTAN_VERSION".Split(".") | Select-Object -First 1)"; $null = $__PSBOTAN_BOTAN_MAJOR_VERSION
$__PSBOTAN_BOTAN_COMPRESSED_FILE_SHA1 = "A3E039F019391B0363A38C07044BD92F9CA360CB" # █> Update on next version.
$__PSBOTAN_BOTAN_URL = "https://botan.randombit.net/releases/Botan-$__PSBOTAN_BOTAN_VERSION.tar.xz" 
$__PSBOTAN_BOTAN_TAR_XZ_FILE = "$__PSBOTAN_TEMP_DIR/Botan-$__PSBOTAN_BOTAN_VERSION.tar.xz"
$__PSBOTAN_BOTAN_EXPANDED_DIR = "$__PSBOTAN_TEMP_DIR/Botan-$__PSBOTAN_BOTAN_VERSION"

# MARK: █ Emscripten build configurations
$__PSBOTAN_EMSCRIPTEN_BUILD_CONFIGURATIONS = [ordered]@{
    Debug   = @{
        Name              = "Debug"
        Options           = @("--cpu=wasm", "--os=emscripten", "--cc=emcc", "--disable-shared-library", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/EmscriptenWasm"
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Emscripten-Wasm-Debug"
    }
    Release = @{
        Name              = "Release"
        Options           = @("--cpu=wasm", "--os=emscripten", "--cc=emcc", "--disable-shared-library")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/EmscriptenWasm"
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Emscripten-Wasm-Release"
    }
}; $null = $__PSBOTAN_EMSCRIPTEN_BUILD_CONFIGURATIONS

# MARK: █ Windows build configurations
$__PSBOTAN_WINDOWS_BUILD_CONFIGURATIONS = [ordered]@{
    DebugDesktopX86     = @{
        Name              = "Debug"
        Platform          = "Desktop"
        ConfigureTarget   = "X86"
        Options           = @("--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.Name)"
        VcvarsParameters  = @("$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.VcVarsArch)", "$__PSCOREFXS_VCVARS_SPECTRE_MODE_PARAMETER")
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.Name)-Release"
    }

    DebugDesktopX64     = @{
        Name              = "Debug"
        Platform          = "Desktop"
        ConfigureTarget   = "X64"
        Options           = @("--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.Name)"
        VcvarsParameters  = @("$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.VcVarsArch)", "$__PSCOREFXS_VCVARS_SPECTRE_MODE_PARAMETER")
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.Name)-Release"
    }

    DebugDesktopArm64   = @{
        Name              = "Debug"
        Platform          = "Desktop"
        ConfigureTarget   = "Arm64"
        Options           = @("--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.Name)"
        VcvarsParameters  = @("$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.VcVarsArch)", "$__PSCOREFXS_VCVARS_SPECTRE_MODE_PARAMETER")
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.Name)-Release"
    }

    ReleaseDesktopX86   = @{
        Name              = "Release"
        Platform          = "Desktop"
        ConfigureTarget   = "X86"
        Options           = @()
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.Name)"
        VcvarsParameters  = @("$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.VcVarsArch)", "$__PSCOREFXS_VCVARS_SPECTRE_MODE_PARAMETER")
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.Name)-Release"
    }
    
    ReleaseDesktopX64   = @{
        Name              = "Release"
        Platform          = "Desktop"
        ConfigureTarget   = "X64"
        Options           = @()
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.Name)"
        VcvarsParameters  = @("$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.VcVarsArch)", "$__PSCOREFXS_VCVARS_SPECTRE_MODE_PARAMETER")
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.Name)-Release"
    }

    ReleaseDesktopArm64 = @{
        Name              = "Release"
        Platform          = "Desktop"
        ConfigureTarget   = "Arm64"
        Options           = @()
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.Name)"
        VcvarsParameters  = @("$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.VcVarsArch)", "$__PSCOREFXS_VCVARS_SPECTRE_MODE_PARAMETER")
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.Name)-Release"
    }
}; $null = $__PSBOTAN_WINDOWS_BUILD_CONFIGURATIONS

# MARK: █ Android build configurations

$__PSBOTAN_ANDROID_BUILD_CONFIGURATIONS = [ordered]@{
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)-Debug"     = @{ 
        Name              = "Debug"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Abi)"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Triplet)"
        Options           = @( "--os=android", "--cc=clang", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)-Debug"     
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)-Debug"   = @{ 
        Name              = "Debug"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Abi)"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Triplet)"
        Options           = @( "--os=android", "--cc=clang", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)-Debug"     
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)-Debug"     = @{ 
        Name              = "Debug"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Abi)"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Triplet)"
        Options           = @("--os=android", "--cc=clang", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)-Debug"   
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)-Debug"     = @{ 
        Name              = "Debug"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Abi)"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Triplet)"
        Options           = @("--os=android", "--cc=clang", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)-Debug"   
    }

    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)-Release"   = @{ 
        Name              = "Release"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Abi)"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Triplet)"
        Options           = @("--os=android", "--cc=clang")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)-Release"
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)-Release" = @{ 
        Name              = "Release"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Abi)"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Triplet)" 
        Options           = @("--os=android", "--cc=clang")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)-Release" 
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)-Release"   = @{ 
        Name              = "Release"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Abi)"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Triplet)"
        Options           = @("--os=android", "--cc=clang")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)-Release" 
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)-Release"   = @{ 
        Name              = "Release"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Abi)"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Triplet)"
        Options           = @("--os=android", "--cc=clang")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        DistDirName       = "Botan-$__PSBOTAN_BOTAN_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)-Release"  
    }
}; $null = $__PSBOTAN_ANDROID_BUILD_CONFIGURATIONS

# MARK: █ Functions

function Get-BotanSources {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $Force
    )
    Invoke-HttpDownload -Url "$__PSBOTAN_BOTAN_URL" -DestinationPath "$__PSBOTAN_TEMP_DIR" -Hash "$__PSBOTAN_BOTAN_COMPRESSED_FILE_SHA1" -HashAlgorithm SHA1 -Force:$Force
    Expand-TarXzArchive -Path "$__PSBOTAN_BOTAN_TAR_XZ_FILE" -DestinationPath "$__PSBOTAN_TEMP_DIR"
}

function Show-BotanModules {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $Force
    )
    Write-Host
    Write-InfoBlue "PSBotan - Botan modules"
    Get-BotanSources -Force:$Force
    $modules = (& $__PSCOREFXS_PYTHON_EXE "$__PSBOTAN_BOTAN_EXPANDED_DIR/configure.py" --list-modules) -join " | "
    Write-Host $modules
}

