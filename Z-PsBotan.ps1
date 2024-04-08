& git submodule init
& git submodule update --remote --recursive 

Import-Module -Name "$PSScriptRoot/submodules/PsCoreFxs/Z-PsCoreFxs.ps1" -Force -NoClobber

$ErrorActionPreference = 'Stop'

$__PSBOTAN_TEMP_DIR = "$(Get-UserHome)/.PsBotan"
$__PSBOTAN_BOTAN_VERSION = "3.3.0" # █> Update on next version.
$__PSBOTAN_BOTAN_COMPRESSED_FILE_SHA1 = "F8718BFB7F36446000912C182E14465CE7E65655" # █> Update on next version.
$__PSBOTAN_BOTAN_URL = "https://botan.randombit.net/releases/Botan-$__PSBOTAN_BOTAN_VERSION.tar.xz" 
$__PSBOTAN_BOTAN_TAR_XZ_FILE = "$__PSBOTAN_TEMP_DIR/Botan-$__PSBOTAN_BOTAN_VERSION.tar.xz"
$__PSBOTAN_BOTAN_EXPANDED_DIR = "$__PSBOTAN_TEMP_DIR/Botan-$__PSBOTAN_BOTAN_VERSION"

# █ functions

function Get-BotanSources {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $NoOutput
    )
    Invoke-HttpDownload -Url "$__PSBOTAN_BOTAN_URL" -DestinationPath "$__PSBOTAN_TEMP_DIR" -Hash "$__PSBOTAN_BOTAN_COMPRESSED_FILE_SHA1" -HashAlgorithm SHA1
    Expand-TarXzArchive -Path "$__PSBOTAN_BOTAN_TAR_XZ_FILE" -DestinationPath "$__PSBOTAN_TEMP_DIR"
}

function Show-BotanModules {
    Write-Host
    Write-InfoBlue "PSBotan - Botan modules"
    Get-BotanSources
    $modules = (& python "$__PSBOTAN_BOTAN_EXPANDED_DIR/configure.py" --list-modules) -join " | "
    Write-Host $modules
}