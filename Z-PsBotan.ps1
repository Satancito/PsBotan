$ErrorActionPreference = 'Stop'

Import-Module -Name "$PSScriptRoot/submodules/PsCoreFxs/Z-PsCoreFxs.ps1" -Force -NoClobber

# MARK: █ Constants
$__PSBOTAN_TEMP_DIR = "$(Get-UserHome)/.PsBotan"
$__PSBOTAN_GITHUB_URL = "https://github.com/Satancito/PsBotan.git"; $null = $__PSBOTAN_GITHUB_URL
$__PSBOTAN_BOTAN_VERSION = "3.4.0" # █> Update on next version.
$__PSBOTAN_BOTAN_COMPRESSED_FILE_SHA1 = "A3E039F019391B0363A38C07044BD92F9CA360CB" # █> Update on next version.
$__PSBOTAN_BOTAN_MAJOR_VERSION = "$("$__PSBOTAN_BOTAN_VERSION".Split(".") | Select-Object -First 1)"; $null = $__PSBOTAN_BOTAN_MAJOR_VERSION
$__PSBOTAN_BOTAN_URL = "https://botan.randombit.net/releases/Botan-$__PSBOTAN_BOTAN_VERSION.tar.xz" 
$__PSBOTAN_BOTAN_TAR_XZ_FILE = "$__PSBOTAN_TEMP_DIR/Botan-$__PSBOTAN_BOTAN_VERSION.tar.xz"
$__PSBOTAN_BOTAN_EXPANDED_DIR = "$__PSBOTAN_TEMP_DIR/Botan-$__PSBOTAN_BOTAN_VERSION"
$__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT = @{
    Emscripten     = "Botan-$__PSBOTAN_BOTAN_VERSION-Esmcripten-Wasm-{0}" # 0=Configuration
    Android        = "Botan-$__PSBOTAN_BOTAN_VERSION-Android-Api{0}-{1}-{2}" # 0=ApiLevel / 1=Abi / 2=Configuration
    WindowsDesktop = "Botan-$__PSBOTAN_BOTAN_VERSION-Windows-Desktop-{0}-{1}" # 0=Architecture / 1=Configuration
    WindowsUWP     = "Botan-$__PSBOTAN_BOTAN_VERSION-Windows-UWP-{0}-{1}" # 0=Architecture / 1=Configuration
}

# MARK: █ Emscripten build configurations
$__PSBOTAN_EMSCRIPTEN_BUILD_CONFIGURATIONS = [ordered]@{
    $__PSCOREFXS_EMSCRIPTEN_CONFIGURATIONS.Wasm.NameDebug   = [ordered]@{
        Name              = $__PSCOREFXS_DEBUG_CONFIGURATION
        Options           = @("--cpu=wasm", "--os=emscripten", "--cc=emcc", "--disable-shared-library", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Emscripten-Wasm"
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.Emscripten -f @($__PSCOREFXS_DEBUG_CONFIGURATION)
    }
    $__PSCOREFXS_EMSCRIPTEN_CONFIGURATIONS.Wasm.NameRelease = [ordered]@{
        Name              = $__PSCOREFXS_RELEASE_CONFIGURATION
        Options           = @("--cpu=wasm", "--os=emscripten", "--cc=emcc", "--disable-shared-library")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Emscripten-Wasm"
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.Emscripten -f @($__PSCOREFXS_RELEASE_CONFIGURATION)
    }
}; $null = $__PSBOTAN_EMSCRIPTEN_BUILD_CONFIGURATIONS

# MARK: █ Windows build configurations
$__PSBOTAN_WINDOWS_BUILD_CONFIGURATIONS = [ordered]@{
    $($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.NameDebug )     = [ordered]@{
        Name              = $__PSCOREFXS_DEBUG_CONFIGURATION
        Platform          = "Desktop"
        Options           = @("--cpu=X86", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.Name)"
        VcvarsParameters  = @("$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.VcVarsArch)", "$__PSCOREFXS_VCVARS_SPECTRE_MODE_PARAMETER")
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.WindowsDesktop -f @($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.Name, $__PSCOREFXS_DEBUG_CONFIGURATION)
    }

    $($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.NameDebug )     = [ordered]@{
        Name              = $__PSCOREFXS_DEBUG_CONFIGURATION
        Platform          = "Desktop"
        Options           = @("--cpu=X64", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.Name)"
        VcvarsParameters  = @("$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.VcVarsArch)", "$__PSCOREFXS_VCVARS_SPECTRE_MODE_PARAMETER")
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.WindowsDesktop -f @($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.Name, $__PSCOREFXS_DEBUG_CONFIGURATION)
    }

    $($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.NameDebug )   = [ordered]@{
        Name              = $__PSCOREFXS_DEBUG_CONFIGURATION
        Platform          = "Desktop"
        Options           = @("--cpu=Arm64", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.Name)"
        VcvarsParameters  = @("$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.VcVarsArch)", "$__PSCOREFXS_VCVARS_SPECTRE_MODE_PARAMETER")
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.WindowsDesktop -f @($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.Name, $__PSCOREFXS_DEBUG_CONFIGURATION)
    }

    $($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.NameRelease )   = [ordered]@{
        Name              = $__PSCOREFXS_RELEASE_CONFIGURATION
        Platform          = "Desktop"
        Options           = @("--cpu=X86")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.Name)"
        VcvarsParameters  = @("$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.VcVarsArch)", "$__PSCOREFXS_VCVARS_SPECTRE_MODE_PARAMETER")
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.WindowsDesktop -f @($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X86.Name, $__PSCOREFXS_RELEASE_CONFIGURATION)
    }
    
    $($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.NameRelease )   = [ordered]@{
        Name              = $__PSCOREFXS_RELEASE_CONFIGURATION
        Platform          = "Desktop"
        Options           = @("--cpu=X64")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.Name)"
        VcvarsParameters  = @("$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.VcVarsArch)", "$__PSCOREFXS_VCVARS_SPECTRE_MODE_PARAMETER")
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.WindowsDesktop -f @($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.X64.Name, $__PSCOREFXS_RELEASE_CONFIGURATION)
    }

    $($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.NameRelease ) = [ordered]@{
        Name              = $__PSCOREFXS_RELEASE_CONFIGURATION
        Platform          = "Desktop"
        Options           = @("--cpu=Arm64")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Windows-Desktop-$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.Name)"
        VcvarsParameters  = @("$($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.VcVarsArch)", "$__PSCOREFXS_VCVARS_SPECTRE_MODE_PARAMETER")
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.WindowsDesktop -f @($__PSCOREFXS_WINDOWS_ARCH_CONFIGURATIONS.Arm64.Name, $__PSCOREFXS_RELEASE_CONFIGURATION)
    }
}; $null = $__PSBOTAN_WINDOWS_BUILD_CONFIGURATIONS

# MARK: █ Android build configurations
$__PSBOTAN_ANDROID_BUILD_CONFIGURATIONS = [ordered]@{
    $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.NameDebug     = [ordered]@{ 
        Name              = $__PSCOREFXS_DEBUG_CONFIGURATION
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Triplet)"
        Options           = @("--cpu=$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Abi)", "--os=android", "--cc=clang", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name, $__PSCOREFXS_DEBUG_CONFIGURATION)
    }
    $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.NameDebug   = [ordered]@{ 
        Name              = $__PSCOREFXS_DEBUG_CONFIGURATION
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Triplet)"
        Options           = @("--cpu=$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Abi)", "--os=android", "--cc=clang", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name, $__PSCOREFXS_DEBUG_CONFIGURATION)
    }
    $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.NameDebug     = [ordered]@{ 
        Name              = $__PSCOREFXS_DEBUG_CONFIGURATION
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Triplet)"
        Options           = @("--cpu=$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Abi)", "--os=android", "--cc=clang", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name, $__PSCOREFXS_DEBUG_CONFIGURATION)
    }
    $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.NameDebug     = [ordered]@{ 
        Name              = $__PSCOREFXS_DEBUG_CONFIGURATION
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Triplet)"
        Options           = @("--cpu=$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Abi)", "--os=android", "--cc=clang", "--debug-mode", "--with-debug-info", "--no-optimizations", "--link-method=copy")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name, $__PSCOREFXS_DEBUG_CONFIGURATION) 
    }

    $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.NameRelease   = [ordered]@{ 
        Name              = $__PSCOREFXS_RELEASE_CONFIGURATION
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Triplet)"
        Options           = @("--cpu=$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Abi)", "--os=android", "--cc=clang")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name, $__PSCOREFXS_RELEASE_CONFIGURATION)
    }
    $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.NameRelease = [ordered]@{ 
        Name              = $__PSCOREFXS_RELEASE_CONFIGURATION
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Triplet)" 
        Options           = @("--cpu=$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Abi)", "--os=android", "--cc=clang")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name, $__PSCOREFXS_RELEASE_CONFIGURATION)
    }
    $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.NameRelease   = [ordered]@{ 
        Name              = $__PSCOREFXS_RELEASE_CONFIGURATION
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Triplet)"
        Options           = @("--cpu=$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Abi)", "--os=android", "--cc=clang")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name, $__PSCOREFXS_RELEASE_CONFIGURATION)
    }
    $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.NameRelease   = [ordered]@{ 
        Name              = $__PSCOREFXS_RELEASE_CONFIGURATION
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Triplet)"
        Options           = @("--cpu=$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Abi)", "--os=android", "--cc=clang")
        CurrentWorkingDir = "$__PSBOTAN_BOTAN_EXPANDED_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        DistDirName       = $__PSBOTAN_BOTAN_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", $__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name, $__PSCOREFXS_RELEASE_CONFIGURATION)
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

function Remove-PsBotan {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $RemoveWsl
    )
    Write-InfoBlue "Removing PsBotan"
    Write-Host "$__PSBOTAN_TEMP_DIR"
    Remove-Item -Path "$__PSBOTAN_TEMP_DIR" -Force -Recurse -ErrorAction Ignore
    if ($IsWindows -and $RemoveWsl.IsPresent) {
        $scriptParameters = @{
            "Script" = (Get-WslPath -Path "$PSCommandPath")
        }

        Write-Host "Removing in WSL."
        & wsl pwsh -Command {
            $params = $args[0]
            Write-Host "Wsl User: " -NoNewline ; & whoami
            Import-Module -Name "$($params.Script)" -Force -NoClobber
            Remove-PsBotan
        } -args $scriptParameters
    }
}
