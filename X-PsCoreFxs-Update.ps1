[CmdletBinding(DefaultParameterSetName = "seta")]
param (
    [Parameter(ParameterSetName = "seta")]
    [switch]
    $RemoveDeprecated,

    [Parameter(ParameterSetName = "seta")]
    [switch]
    $RemoveUnused,

    [Parameter(ParameterSetName = "setb")]
    [switch]
    $Reset,

    [switch]
    $Run
)

$ErrorActionPreference = "Stop"

function Select-ValueByPlatform {
    param (
        [parameter()]
        [System.Object]
        $WindowsValue = [string]::Empty,
        
        [parameter()]
        [System.Object]
        $LinuxValue = [string]::Empty,
        
        [parameter()]
        [System.Object]
        $MacOSValue = [string]::Empty
        
    )
    if ($IsWindows) {
        return $WindowsValue
    }
    if ($IsLinux) {
        return $LinuxValue
    }
    if ($IsMacOS) {
        return $MacOSValue
    }
        
    throw "Invalid Platform."
}
    
function Get-UserHome {
    return "$(Select-ValueByPlatform "$env:USERPROFILE" "$env:HOME" "$env:HOME")";
}

function Get-ItemTree() {
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String]
        $Path = ".",

        [Parameter()]
        [System.String]
        $Include = "*",

        [Parameter()]
        [switch]
        $IncludePath,

        [Parameter()]
        [switch]
        $Force

    )
    $result = @()
    if (!(Test-Path $Path)) {
        throw "Invalid path. The path `"$Path`" doesn't exist." #Test if path is valid.
    }
    if (Test-Path $Path -PathType Container) {
        $result += (Get-ChildItem "$Path" -Include "$Include" -Force:$Force -Recurse) # Add all items inside of a container, if path is a container.
    }
    if ($IncludePath.IsPresent) {
        $result += @(Get-Item $Path -Force) # Add the $Path in the result.
    }
    $result = , @($result | Sort-Object -Descending -Unique -Property "PSPath") # Sort elements by PSPath property, order in descending, remove duplicates with unique.
    return  $result
}

function Remove-ItemTree() {
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String]
        $Path
    )
    (Get-ItemTree -Path $Path -Force -IncludePath) | ForEach-Object {
        Remove-Item "$($_.PSPath)" -Force
        if ($PSBoundParameters.ContainsKey("Verbose")) {
            Write-Warning "Deleted: $($_.PSPath)"
        }
    }
}

function Test-LastExitCode {
    param (
        [Parameter()]
        [switch]
        $NoThrowError
    )
    if (($LASTEXITCODE -ne 0) -or (-not $?)) {
        if ($NoThrowError.IsPresent) {
            return $false
        }
        throw "ERROR: When execute last command. Check and try again. ExitCode = $($LASTEXITCODE)."
    }  
    if ($NoThrowError.IsPresent) {
        return $true
    }
}

#CUSTOM
function Set-GitRepository { 
    param (
        [Parameter()]
        [System.String]
        $RepositoryUrl,

        [Parameter()]
        [System.String]
        $Path = [System.String]::Empty
    )
    $tempDir = "$(Get-UserHome)/.PsCoreFxsTemp"
    $Path = ([System.String]::IsNullOrWhiteSpace($Path) ? "$tempDir" : $Path)
    $folderName = ($RepositoryUrl | Split-Path -Leaf).Replace(".git", [String]::Empty)  
    New-Item "$Path" -Force -ItemType Container | Out-Null
    Remove-ItemTree "$Path/$folderName" -ErrorAction Ignore
    try {
        Push-Location $Path
        git clone $RepositoryUrl
        Test-LastExitCode
    }
    finally {
        Pop-Location
    } 
}

function Get-GitRepositoryRemoteUrl {
    param (
        [string]
        $Path = [string]::Empty
    )

    if([string]::IsNullOrWhiteSpace($Path))
    {
        $Path = "$(Get-Location)"
    }
    $result = [string]::Empty
    try {
        Push-Location $Path
        return "$(Split-Path -Path (git remote get-url origin) -Leaf -ErrorAction Ignore)"
    }
    catch{
        return $result
    }
    finally {
        Pop-Location
    }
}


$tempDir = "$(Get-UserHome)/.PsCoreFxsTemp"
$Path = "$tempDir"
$PsCoreFxs = "https://github.com/Satancito/PsCoreFxs.git"
$RepoFolderName = "PsCoreFxs"
$RepoPath = "$Path/$RepoFolderName"
$Z_CONFIG = "Z-PsCoreFxsConfig.json"
$Z_PSCOREFXS = "Z-PsCoreFxs.ps1"
$X_UPDATE = $PSCommandPath | Split-Path -Leaf
$isSourceRepo = "$(Get-Location | Split-Path -Leaf)".Equals($RepoFolderName) -or (Get-GitRepositoryRemoteUrl).Equals("$RepoFolderName.git")
if ($isSourceRepo) {
    Write-Warning -Message "WARNING. Cannot overwrite original directory of scripts."
    Write-Host "███ End - Update - PsCoreFxs Scripts " -ForegroundColor Magenta
    exit
}

if (!$Run.IsPresent) {
    Write-Host "███ Cloning - PsCoreFxs Repo[$PsCoreFxs] in [$RepoPath]" -ForegroundColor Magenta
    Set-GitRepository $PsCoreFxs $Path 
    $newUpdateScript =  (Get-Content -Path "$RepoPath/$Z_CONFIG" | ConvertFrom-Json).UpdateScript 
    if (!"$X_UPDATE".Equals($newUpdateScript)) {
        Write-Host "Updating!" -ForegroundColor Magenta -NoNewline
        Write-Host "$X_UPDATE => $newUpdateScript"
    }
    Remove-Item "$Z_PSCOREFXS" -Force -ErrorAction Ignore
    Remove-Item "$X_UPDATE" -Force -ErrorAction Ignore
    Copy-Item -Path "$RepoPath/$Z_PSCOREFXS" $Z_PSCOREFXS -Force
    Copy-Item -Path "$RepoPath/$newUpdateScript" $newUpdateScript -Force
    & "./$newUpdateScript" -Run -RemoveDeprecated:$RemoveDeprecated -RemoveUnused:$RemoveUnused
    Write-Host 
    exit
}

# RUN MODE
Import-Module -Name "$(Get-Item "./Z-PsCoreFxs.ps1")" -Force -NoClobber
if ($Reset.IsPresent) {
    Remove-Item $Z_CONFIG -Force -ErrorAction Ignore
}

if (!(Test-Path $Z_CONFIG -PathType Leaf)) {
    Copy-Item -Path "$RepoPath/$Z_CONFIG" $Z_CONFIG -Force
    Write-PrettyKeyValue "Creating" "$Z_CONFIG"
}

$localJsonObject = (Get-Content -Path "./$Z_CONFIG" | ConvertFrom-Json) 
$lastJsonObject = (Get-Content -Path "$RepoPath/$Z_CONFIG" | ConvertFrom-Json)  

$localJsonObject.Files = ($null -eq $localJsonObject.Files ? ([System.Array]::Empty[System.String]()) : ([array]$localJsonObject.Files))
[array]$files = ($localJsonObject.Files | Where-Object { ($_ -notin $lastJsonObject.DeprecatedFiles) -and ($_ -in $lastJsonObject.Files) })
$localJsonObject.Files = $files
$localJsonObject.CoreFiles = $lastJsonObject.CoreFiles
Add-Member -MemberType NoteProperty -Name "LastSupportedFiles" -InputObject $localJsonObject -Value $lastJsonObject.Files -Force
#$localJsonObject.LastSupportedFiles = $lastJsonObject.Files
$localJsonObject.Build = $lastJsonObject.Build
$localJsonObject.DeprecatedFiles = $lastJsonObject.DeprecatedFiles

Set-JsonObject $localJsonObject $Z_CONFIG
Write-PrettyKeyValue "Updating!" "$Z_CONFIG"

if ($RemoveDeprecated.IsPresent) {
    $localJsonObject.DeprecatedFiles | ForEach-Object {
        if (Test-Path $_ -PathType Leaf) {
            Remove-Item $_ -Force -ErrorAction Ignore
            Write-PrettyKeyValue "Removed deprecated" "$_"
        }
    }
}

if ($RemoveUnused.IsPresent) {
    $lastJsonObject.Files | Where-Object { $_ -notin $localJsonObject.Files } | ForEach-Object {
        if (Test-Path $_ -PathType Leaf) {
            Remove-Item $_ -Force  -ErrorAction Ignore
            Write-PrettyKeyValue "Removed unused" "$_"
        }
    }
}

($localJsonObject.Files + $localJsonObject.CoreFiles) | ForEach-Object {
    $file = "$RepoPath/$_"
    if (!"$_".Equals($Z_CONFIG)) {
        if (Test-Path $file -PathType Leaf) {
            Copy-Item -Path $file -Destination $_ -Force 
            Write-PrettyKeyValue "Updating" "$_"
        }
        else {
            Write-PrettyKeyValue "Ignored" "$_"
        }
    }
}

Write-InfoMagenta "███ End - Update - PsCoreFxs Scripts " 