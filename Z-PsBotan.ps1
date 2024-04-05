& git submodule init
& git submodule update --remote --recursive 

Import-Module -Name "$PSScriptRoot/submodules/PsCoreFxs/Z-PsCoreFxs.ps1" -Force -NoClobber

$ErrorActionPreference = 'Stop'
$__PSBOTAN_TEMP_DIR = "$(Get-UserHome)/.PsBotan"
$__CPP_LIBS_DIR = "$(Get-UserHome)/.CppLibs"
# █ Botan
$__BOTAN_VERSION = "3.3.0" # Update on next version.
$__BOTAN_COMPRESSED_FILE_SHA1 = "F8718BFB7F36446000912C182E14465CE7E65655" # Update on next version.
$__BOTAN_URL = "https://botan.randombit.net/releases/Botan-$__BOTAN_VERSION.tar.xz" 
$__BOTAN_TAR_XZ_FILE = "$__PSBOTAN_TEMP_DIR/Botan-$__BOTAN_VERSION.tar.xz"
$__BOTAN_EXPANDED_DIR = "$__PSBOTAN_TEMP_DIR/Botan-$__BOTAN_VERSION"
# █ Tools
$__EMSCRIPTEN_INSTALL_SCRIPT = "$PSScriptRoot/submodules/PsEmscripten/X-PsEmscripten-SDK.ps1"

# █ functions

function Get-BotanSources {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $NoOutput
    )
    Invoke-HttpDownload -Url "$__BOTAN_URL" -DestinationPath "$__PSBOTAN_TEMP_DIR" -Hash "$__BOTAN_COMPRESSED_FILE_SHA1" -HashAlgorithm SHA1
    Expand-TarXzArchive -Path "$__BOTAN_TAR_XZ_FILE" -DestinationPath "$__PSBOTAN_TEMP_DIR"
}

function Show-BotanModules {
    Write-Host
    Write-InfoBlue "█ PSBotan - Botan modules"
    Write-Host
    Get-BotanSources
    $modules = (& python "$__BOTAN_EXPANDED_DIR/configure.py" --list-modules) -join " | "
    Write-Host $modules
}