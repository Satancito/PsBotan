function Pop-LocationStack {
    param (
        [string]
        $StackName = [string]::Empty,

        [int]
        $Count = 0
    )

    if ($Count -lt 0) {
        $Count = 0
    }

    if ([string]::IsNullOrWhiteSpace($StackName)) {
        if ($Count -eq 0) {
            $Count = (Get-Location -Stack).Count
        }
        for ($i = 0; $i -lt $Count; $i++) {
            Pop-Location 
        }
    }
    else {
        $stackCount = (Get-Location -Stack -StackName $StackName).Count 
        if ($Count -eq 0) {
            $Count = $stackCount
        }
        if ($Count -gt $stackCount) {
            $Count = $stackCount
        }
        for ($i = 0; $i -lt $Count; $i++) {
            try {
                
                Pop-Location -StackName $StackName 
            }
            finally {
                
            }
        }
    }
    
}

function Get-InternalPreference {
    param (
        
    )

    return @{
        ForceOverwriteConstans = $true
    }
    
}

function Get-StringCoalesce {
    param (
        [string]
        [Parameter()]
        $Value,

        [string]
        [Parameter()]
        $Value2,

        [switch]
        $Force
    )
    if (!$Force.IsPresent -and [string]::IsNullOrWhiteSpace($Value2)) {
        throw [System.ArgumentException]::new("$(Get-VariableName $Value2) value can't be null or whitespace.")
    }
    return [string]::IsNullOrWhiteSpace($value) ? $Value2 : $Value
}

function Get-StringEmptyOrValue {
    param (
        [string]
        [Parameter()]
        $TestValue,

        [string]
        [Parameter(Mandatory = $true)]
        $Value
    )
    return [string]::IsNullOrWhiteSpace($TestValue) ? [string]::Empty : $Value
}

function Set-GlobalConstant {
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Value
    )
    Process {
        $Force = (Get-InternalPreference).ForceOverwriteConstans
        if (!(Get-Variable "$Name"  -ErrorAction 'Ignore')) {
            Set-Variable -Name "$Name" -Option Constant -Value "$Value" -Scope Global -Force:$Force
        }
    }
}

function Set-GlobalVariable {
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $false, Position = 1, ValueFromPipeline = $true)]
        [System.String]
        $Value = ""
    )
    Process {
        Set-Variable -Name "$Name" -Value "$Value" -Scope Global
    }
}

function Write-TextColor {
    Param(
        [parameter(Position = 0, ValueFromPipeline = $true)]
        [Object]
        $Info,

        [parameter(Position = 1, ValueFromPipeline = $true)]
        [System.ConsoleColor]
        $ForegroundColor = [System.ConsoleColor]::White,
    
        [parameter(Position = 2, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        foreach ($value in $Info) {
            if ($NoNewLine) {
                Write-Host $value -ForegroundColor $ForegroundColor -NoNewline
            }
            else {
                Write-Host $value -ForegroundColor $ForegroundColor
            }
        }            
    }
}

function Write-PrettyKeyValue {
    [CmdletBinding()]
    Param(
        [parameter(Position = 0, ValueFromPipeline = $true)]
        [Object]
        $Key,

        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Object]
        $Value,

        [parameter(Position = 2, ValueFromPipeline = $true)]
        [System.ConsoleColor]
        $LabelForegroudColor = [System.ConsoleColor]::Magenta,

        [parameter(Position = 3, ValueFromPipeline = $true)]
        [System.ConsoleColor]
        $InfoForegroundColor = [System.ConsoleColor]::White,

        [parameter(Position = 4, ValueFromPipeline = $true, Mandatory = $false)]
        [Switch]
        $NoNewLine,

        [Parameter(Position = 5, Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]
        $IsDebug
    )
    
    Process {
        if ($IsDebug) {
            Write-InfoYellow "DEBUG: " -NoNewLine
        }
        Write-TextColor "$($Key): " $LabelForegroudColor -NoNewLine
        foreach ($value in $Value) {
            Write-TextColor $value $InfoForegroundColor -NoNewline:$NoNewLine
        }
    }
}

function Write-InfoRed {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $false)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information Red $NoNewLine
    }
}

function Write-InfoDarkRed {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $false)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information DarkRed $NoNewLine
    }
}

function Write-InfoYellow {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information Yellow $NoNewLine
    }
}

function Write-InfoDarkYellow {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information DarkYellow $NoNewLine
    }
}

function Write-InfoGray {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information Gray $NoNewLine
    }
}

function Write-InfoDarkGray {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information DarkGray $NoNewLine
    }
}

function Write-InfoGreen {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $false)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information Green $NoNewLine
    }
}

function Write-InfoDarkGreen {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information DarkGreen $NoNewLine
    }
}

function Write-InfoMagenta {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information Magenta $NoNewLine
    }
}

function Write-InfoDarkMagenta {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information DarkMagenta $NoNewLine
    }
}

function Write-InfoWhite {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information White $NoNewLine
    }
}

function Write-InfoBlue {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information Blue $NoNewLine
    }
}

function Write-InfoDarkBlue {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information DarkBlue $NoNewLine
    }
}

function Write-InfoCyan {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information Cyan $NoNewLine
    }
}

function Write-InfoDarkCyan {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information Cyan $NoNewLine
    }
}

function Write-InfoBlack {
    Param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $Information,
    
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [Switch]
        $NoNewLine
    )

    Process {
        Write-TextColor $Information Black $NoNewLine
    }
}

function Test-OnlyWindows {
    param (
    )
    process {
        if (!$IsWindows) {
            Write-Error "Windows Operating system is required for run this function."
            exit
        }
    }
}

function Test-OnlyLinux {
    param (
    )
    process {
        if (!$IsLinux) {
            Write-Error "Linux Operating system is required for run this function."
            exit
        }
    }
}

function Test-OnlyMacOS {
    param (
    )
    process {
        if (!$IsMacOS) {
            Write-Error "MacOS Operating system is required for run this function."
            exit
        }
    }
}

class DbProviderSet : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return @($Global:SQLSERVER_PROVIDER, $Global:POSTGRESQL_PROVIDER, $Global:MYSQL_PROVIDER, $Global:ORACLE_PROVIDER, $Global:ALL_PROVIDER)
    }
}

function Stop-WhenIsDbProviderName {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Value
    )
    switch ($Value) {
        { $_ -in [DbProviderSet]::new().GetValidValues() } {
            throw "Value cannot be a db Provider"
        }
        default {
            return;
        }       
    }
}

function Install-EfCoreTools {
    param (
        
    )
    Write-Host "██ Try Install Entity Framework Core Tools" -ForegroundColor Blue
    if (Get-Command dotnet-ef -ErrorAction Ignore) {
        "Updating..."
        dotnet tool update --global dotnet-ef
    }
    else {
        "Installing..."
        dotnet tool install --global dotnet-ef
        
    }
    dotnet-ef --version
}

function Add-EfCoreMigration {
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet([DbProviderSet], IgnoreCase = $false, ErrorMessage = "Value `"{0}`" is invalid. Try one of: `"{1}`"")]
        $Provider,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Project,

        [Parameter(Mandatory = $true)]
        [System.String]
        $StartupProject,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Context = "",

        [switch]
        $InstallEfCoreTools
    )
    if ($InstallEfCoreTools.IsPresent) {
        Install-EfCoreTools
    }
    Stop-WhenIsDbProviderName -Value $Name

    $projectFile = "$(Get-Item -Path "$Project/*.csproj" | Split-Path -Leaf)"
    $startupProjectFile = "$(Get-Item -Path "$StartupProject/*.csproj" | Split-Path -Leaf)" 


    switch ($Provider) {
        { $_ -in @($SQLSERVER_PROVIDER, $POSTGRESQL_PROVIDER, $MYSQL_PROVIDER, $ORACLE_PROVIDER) } { 
            $Context = "$($Context)$($Provider)DbContext"
            $outputDir = "Migrations/$Provider/$($Context)_"
        }

        ($ALL_PROVIDER) {
            Add-EfCoreMigration -Name $Name -Provider $SQLSERVER_PROVIDER -Project $project -StartupProject $startupProject -Context $Context
            Add-EfCoreMigration -Name $Name -Provider $POSTGRESQL_PROVIDER -Project $project -StartupProject $startupProject -Context $Context
            Add-EfCoreMigration -Name $Name -Provider $MYSQL_PROVIDER -Project $project -StartupProject $startupProject -Context $Context
            Add-EfCoreMigration -Name $Name -Provider $ORACLE_PROVIDER -Project $project -StartupProject $startupProject -Context $Context
            return
        } 

        Default {
            Write-Error "Invalid Provider"
            exit
        }

    }
    Write-Host "█ Add Migration - $context - $outputDir" -ForegroundColor Magenta
    dotnet add "$StartupProject/$startupProjectFile" package "Microsoft.EntityFrameworkCore.Design"
    if ($projectFile -cne $startupProjectFile) {
        dotnet add "$StartupProject/$startupProjectFile" reference "$Project/$projectFile"
    }
    dotnet-ef migrations add "Migration_$($context)_$Name" --startup-project "$StartupProject" --project "$Project" --context "$context" --output-dir "$outputDir" --verbose
}

function Remove-EfCoreMigration {
    param ( 
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet([DbProviderSet], IgnoreCase = $false, ErrorMessage = "Value `"{0}`" is invalid. Try one of: `"{1}`"")]
        [System.String]
        $Provider = "All",

        [Parameter(Mandatory = $true)]
        [System.String]
        $Project,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        $StartupProject,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Context = "",

        [switch]
        $Force,

        [switch]
        $InstallEfCoreTools
    )
    if ($InstallEfCoreTools.IsPresent) {
        Install-EfCoreTools
    }

    $projectFile = "$(Get-Item -Path "$Project/*.csproj" | Split-Path -Leaf)"
    $startupProjectFile = "$(Get-Item -Path "$StartupProject/*.csproj" | Split-Path -Leaf)" 

    switch ($Provider) {
        { $_ -in @($SQLSERVER_PROVIDER, $POSTGRESQL_PROVIDER, $MYSQL_PROVIDER, $ORACLE_PROVIDER) } { 
            $Context = "$($Context)$($Provider)DbContext"
        }

        ($ALL_PROVIDER) {
            Remove-EfCoreMigration -Provider $SQLSERVER_PROVIDER -Project $Project -StartupProject $StartupProject -Context $context
            Remove-EfCoreMigration -Provider $POSTGRESQL_PROVIDER -Project $Project -StartupProject $StartupProject -Context $Context
            Remove-EfCoreMigration -Provider $MYSQL_PROVIDER -Project $Project -StartupProject $StartupProject -Context $Context
            Remove-EfCoreMigration -Provider $ORACLE_PROVIDER -Project $Project -StartupProject $StartupProject -Context $Context
            return
        } 

        Default {
            Write-Error "Invalid Provider"
            exit
        }
    }
    Write-Host "█ Remove Migration - $context" -ForegroundColor Magenta
    dotnet add "$StartupProject/$startupProjectFile" package "Microsoft.EntityFrameworkCore.Design"
    if ($projectFile -cne $startupProjectFile) {
        dotnet add "$StartupProject/$startupProjectFile" reference "$Project/$projectFile"
    }
    #Con el parámetro --force Elimina la migración desde código y desde la base de datos.
    dotnet ef migrations remove --startup-project "$startupProject" --project "$project" --context "$context" --verbose "$($Force.IsPresent ? "--force" : ([string]::Empty))"
    
}

function Remove-EfCoreDatabase {
    param (
        [System.String]
        [ValidateSet([DbProviderSet], IgnoreCase = $false, ErrorMessage = "Value `"{0}`" is invalid. Try one of: `"{1}`"")]
        $Provider = "All",
        [Parameter(Mandatory = $true)]
        [System.String]
        $Project,
        [Parameter(Mandatory = $true)]
        [System.String]
        $StartupProject,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Context = "",

        [switch]
        $InstallEfCoreTools
    )
    if ($InstallEfCoreTools.IsPresent) {
        Install-EfCoreTools
    }

    $projectFile = "$(Get-Item -Path "$Project/*.csproj" | Split-Path -Leaf)"
    $startupProjectFile = "$(Get-Item -Path "$StartupProject/*.csproj" | Split-Path -Leaf)" 

    switch ($Provider) {
        { $_ -in @($SQLSERVER_PROVIDER, $POSTGRESQL_PROVIDER, $MYSQL_PROVIDER, $ORACLE_PROVIDER) } { 
            $Context = "$($Context)$($Provider)DbContext"
        }

        ($ALL_PROVIDER) {
            Remove-EfCoreDatabase -Provider $SQLSERVER_PROVIDER -Project $project -StartupProject $startupProject -Context $Context
            Remove-EfCoreDatabase -Provider $POSTGRESQL_PROVIDER -Project $project -StartupProject $startupProject -Context $Context
            Remove-EfCoreDatabase -Provider $MYSQL_PROVIDER -Project $project -StartupProject $startupProject -Context $Context
            Remove-EfCoreDatabase -Provider $ORACLE_PROVIDER -Project $project -StartupProject $startupProject -Context $Context
            return;
        } 

        Default {
            Write-Error "Invalid Provider"
            exit
        }

    }
    Write-Host "█ Remove Database - $context" -ForegroundColor Magenta
    dotnet add "$StartupProject/$startupProjectFile" package "Microsoft.EntityFrameworkCore.Design"
    if ($projectFile -cne $startupProjectFile) {
        dotnet add "$StartupProject/$startupProjectFile" reference "$Project/$projectFile"
    }
    dotnet-ef database drop --startup-project "$startupProject" --context "$context" --project "$project" --force --verbose
}

function Update-EfCoreDatabase {
    param (
        [System.String]
        [ValidateSet([DbProviderSet], IgnoreCase = $false, ErrorMessage = "Value `"{0}`" is invalid. Try one of: `"{1}`"")]
        $Provider = "All",
        
        [Parameter(Mandatory = $true)]
        [System.String]
        $Project,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        $StartupProject,

        [System.String]
        $Context = "",

        [switch]
        $InstallEfCoreTools
    )
    if ($InstallEfCoreTools.IsPresent) {
        Install-EfCoreTools
    }

    $projectFile = "$(Get-Item -Path "$Project/*.csproj" | Split-Path -Leaf)"
    $startupProjectFile = "$(Get-Item -Path "$StartupProject/*.csproj" | Split-Path -Leaf)" 

    switch ($Provider) {
        { $_ -in @($SQLSERVER_PROVIDER, $POSTGRESQL_PROVIDER, $MYSQL_PROVIDER, $ORACLE_PROVIDER) } { 
            $Context = "$($Context)$($Provider)DbContext"
        }

        ($ALL_PROVIDER) {
            Update-EfCoreDatabase -Provider $SQLSERVER_PROVIDER -Project $Project -StartupProject $StartupProject -Context $Context
            Update-EfCoreDatabase -Provider $POSTGRESQL_PROVIDER -Project $Project -StartupProject $StartupProject -Context $Context
            Update-EfCoreDatabase -Provider $MYSQL_PROVIDER -Project $Project -StartupProject $StartupProject -Context $Context
            Update-EfCoreDatabase -Provider $ORACLE_PROVIDER -Project $Project -StartupProject $StartupProject -Context $Context
            return
        }

        Default {
            Write-Error "Invalid Provider"
            exit
        }
    }
    Write-Host "█ Update database - $context" -ForegroundColor Magenta
    dotnet add "$StartupProject/$startupProjectFile" package "Microsoft.EntityFrameworkCore.Design"
    if ($projectFile -cne $startupProjectFile) {
        dotnet add "$StartupProject/$startupProjectFile" reference "$Project/$projectFile"
    }
    dotnet-ef database update --startup-project "$StartupProject" --context "$context" --project "$Project" --verbose
}

function New-EfCoreMigrationScript {
    param (
        [System.String]
        $Name = [String]::Empty,
        
        [System.String]
        [ValidateSet([DbProviderSet], IgnoreCase = $false, ErrorMessage = "Value `"{0}`" is invalid. Try one of: `"{1}`"")]
        $Provider = "All",
        
        [Parameter(Mandatory = $true)]
        [System.String]
        $Project,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        $StartupProject,

        [System.String]
        $Context = [string]::Empty,

        [switch]
        $Idempotent,

        [switch]
        $InstallEfCoreTools
    )

    if ($InstallEfCoreTools.IsPresent) {
        Install-EfCoreTools
    }
    Stop-WhenIsDbProviderName -Value $Name

    $projectFile = "$(Get-Item -Path "$Project/*.csproj" | Split-Path -Leaf)"
    $startupProjectFile = "$(Get-Item -Path "$StartupProject/*.csproj" | Split-Path -Leaf)" 

    switch ($Provider) {
        { $_ -in @($SQLSERVER_PROVIDER, $POSTGRESQL_PROVIDER, $MYSQL_PROVIDER, $ORACLE_PROVIDER) } { 
            $Context = "$($Context)$($Provider)DbContext"
            $outputFile = "$Project/MigrationScripts/$Provider/$Context/Migration_$($context)_$([string]::IsNullOrWhiteSpace($Name) ? "$([DateTime]::Now.ToString("yyyyMMddHHmmssfff"))" : $Name).sql"
            break
        }

        ($ALL_PROVIDER) {
            New-EfCoreMigrationScript -Name $Name -Provider $SQLSERVER_PROVIDER -Project $project -StartupProject $startupProject -Context $Context -Idempotent:$Idempotent
            New-EfCoreMigrationScript -Name $Name -Provider $POSTGRESQL_PROVIDER -Project $project -StartupProject $startupProject -Context $Context -Idempotent:$Idempotent
            New-EfCoreMigrationScript -Name $Name -Provider $MYSQL_PROVIDER -Project $project -StartupProject $startupProject -Context $Context -Idempotent:$Idempotent
            New-EfCoreMigrationScript -Name $Name -Provider $ORACLE_PROVIDER -Project $project -StartupProject $startupProject -Context $Context -Idempotent:$Idempotent
            return
        }

        Default {
            Write-Error "Invalid Provider"
            exit
        }

    }
    Write-Host "█ Creating Sql Script - $context - $outputFile" -ForegroundColor Magenta
    dotnet add "$StartupProject/$startupProjectFile" package "Microsoft.EntityFrameworkCore.Design"
    if ($projectFile -cne $startupProjectFile) {
        dotnet add "$StartupProject/$startupProjectFile" reference "$Project/$projectFile"
    }
    dotnet ef migrations script --output "$outputFile" --context "$context" --project "$project" --startup-project "$startupProject" --verbose ($Idempotent.IsPresent? "--idempotent" : [string]::Empty)
}

function Update-ProjectBuildNumber {
    param (
        [Parameter(Position = 0)]
        [System.String]
        $ProjectFilename = "*.csproj"
    )

    $basePath = "//Project/PropertyGroup"
    $buildNumberLabel = "BuildNumber"

    $ProjectFilename = Get-Item $ProjectFilename
    if (!(Test-Path $ProjectFilename -PathType Leaf) -or (!"$ProjectFilename".EndsWith(".csproj"))) {
        throw "Invalid file `"$ProjectFilename`"."
    }

    [System.Xml.XmlDocument] $doc = [System.Xml.XmlDocument]::new()
    $doc.PreserveWhitespace = $true
    $doc.Load($ProjectFilename)
    $ProjectBuild = $doc.DocumentElement.SelectSingleNode("$basePath/$buildNumberLabel") 

    if ($null -eq $ProjectBuild) {
        [System.Xml.XmlElement]$e = $doc.CreateElement("$buildNumberLabel")
        $e.InnerText = "1"
        $doc.DocumentElement.SelectSingleNode("$basePath").AppendChild($e);
        $doc.Save($ProjectFilename)
        $ProjectBuild = $e
        return $ProjectBuild.InnerText
    }

    if ([String]::IsNullOrWhiteSpace($ProjectBuild.InnerText)) {
        $ProjectBuild.InnerText = "1" 
    }

    $ProjectBuild.InnerText = [int]::Parse($ProjectBuild.InnerText) + 1
    $doc.Save($ProjectFilename)
    return $ProjectBuild.InnerText
}

function Get-NextVersion {
    param (
        [Parameter(Position = 0, ParameterSetName = "Default")]
        [Parameter(Position = 0, ParameterSetName = "Major")]
        [Parameter(Position = 0, ParameterSetName = "Minor")]
        [Parameter(Position = 0, ParameterSetName = "Patch")]
        [System.String]
        $Version = [string]::Empty,

        [Parameter(Mandatory = $True, ParameterSetName = "Major")]
        [Switch]
        $Major,
        
        [Parameter(Mandatory = $True, ParameterSetName = "Minor")]
        [Switch]
        $Minor,

        [Parameter(Mandatory = $True, ParameterSetName = "Patch")]
        [Switch]
        $Patch
    )
    if ([string]::IsNullOrWhiteSpace($Version)) {
        $Version = "0.0.0"
    }
    # check https://semver.org/
    $pattern = "^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$";
    $match = [System.Text.RegularExpressions.Regex]::Match($Version, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline, [System.TimeSpan]::FromSeconds(1))
    if ($match.Success) {
        $majorValue = $match.Groups[1].Value.Trim()
        $minorValue = $match.Groups[2].Value.Trim()
        $patchValue = $match.Groups[3].Value.Trim()
        $OldVersionValue = "$majorValue.$minorValue.$patchValue"
        

        $configured = $false
        if ($Major.IsPresent) {
            $majorValue = "$([Convert]::ToInt32($majorValue, 10) + 1)";
            $minorValue = "0"
            $patchValue = "0"
            $configured = $true
        }
    
        if ($Minor.IsPresent) {
            $minorValue = "$([Convert]::ToInt32($minorValue, 10) + 1)";
            $patchValue = "0"
            $configured = $true
        }
    
        if ($Patch.IsPresent) {
            $patchValue = "$([Convert]::ToInt32($patchValue, 10) + 1)";
            $configured = $true
        }

        if (!$configured) {
            $patchValue = "$([Convert]::ToInt32($patchValue, 10) + 1)";
        }

       
        $NewVersionValue = "$majorValue.$minorValue.$patchValue".Trim()

        return $version.Replace($OldVersionValue, $NewVersionValue)
    }

    throw "Invalid version format. Check format in https://semver.org/"
}

function Update-ProjectVersion {
    param (
        [Parameter(ParameterSetName = "Major")]
        [Parameter(ParameterSetName = "Minor")]
        [Parameter(ParameterSetName = "Patch")]
        [Parameter(ParameterSetName = "MajorR")]
        [Parameter(ParameterSetName = "MinorR")]
        [Parameter(ParameterSetName = "PatchR")]
        [Parameter(ParameterSetName = "MajorP")]
        [Parameter(ParameterSetName = "MinorP")]
        [Parameter(ParameterSetName = "PatchP")]
        [System.String]
        $ProjectFileName = "*.csproj",
    
        [Parameter(ParameterSetName = "Major", Mandatory = $true)]
        [Parameter(ParameterSetName = "MajorR", Mandatory = $true)]
        [Parameter(ParameterSetName = "MajorP", Mandatory = $true)]
        [Switch]
        $Major,
    
        [Parameter(ParameterSetName = "Minor", Mandatory = $true)]
        [Parameter(ParameterSetName = "MinorR", Mandatory = $true)]
        [Parameter(ParameterSetName = "MinorP", Mandatory = $true)]
        [Switch]
        $Minor,
    
        [Parameter(ParameterSetName = "Patch", Mandatory = $true)]
        [Parameter(ParameterSetName = "PatchR", Mandatory = $true)]
        [Parameter(ParameterSetName = "PatchP", Mandatory = $true)]
        [Switch]
        $Patch,
    
        [Parameter(ParameterSetName = "ZeroP", Mandatory = $true)]
        [Parameter(ParameterSetName = "MajorP", Mandatory = $true)]
        [Parameter(ParameterSetName = "MinorP", Mandatory = $true)]
        [Parameter(ParameterSetName = "PatchP", Mandatory = $true)]
        [Switch]
        $IsPrerelease,
        
        [Parameter(ParameterSetName = "ZeroR", Mandatory = $true)]
        [Parameter(ParameterSetName = "MajorR", Mandatory = $true)]
        [Parameter(ParameterSetName = "MinorR", Mandatory = $true)]
        [Parameter(ParameterSetName = "PatchR", Mandatory = $true)]
        [Switch]
        $IsRelease,
    
        [System.String]
        $Prerelease = [string]::Empty,
        
        [System.String]
        $Build = [string]::Empty, 

        [Switch]
        $Force
    )

    if ($PSBoundParameters.ContainsKey("Verbose") -and $PSBoundParameters["Verbose"]) {
        Write-PrettyKeyValue "PSBoundParameters" $PSCmdlet.MyInvocation.InvocationName -NoNewLine
        $PSBoundParameters | Format-Table
    }

    $ProjectFileName = Get-Item $ProjectFileName
    if (($null -eq $ProjectFileName) -or !(Test-Path $ProjectFileName -PathType Leaf) -or (!"$ProjectFileName".EndsWith(".csproj"))) {
        throw "Invalid project filename `"$ProjectFileName`". Not found."
    }

    
    [System.Xml.XmlDocument] $doc = [System.Xml.XmlDocument]::new()
    $doc.PreserveWhitespace = $true
    $doc.Load($ProjectFileName)

    $basePath = "//Project/PropertyGroup"

    $isPrereleaseLabel = "IsPrerelease"
    $prereleaseNameLabel = "PrereleaseName"
    $buildSuffixLabel = "BuildSuffix"
    $buildNumberLabel = "BuildNumber"
    $versionPrefixLabel = "VersionPrefix"
    $versionSuffixLabel = "VersionSuffix"
    $versionLabel = "Version"

    $defaultPrefix = "0.0.0"
    $defaultBuildNumber = "0"
    $defaultPrereleaseName = "Preview"
    $defaultBuildSuffix = "Build"

    $isPrereleaseNode = $doc.DocumentElement.SelectSingleNode("$basePath/$isPrereleaseLabel") 
    $prereleaseNameNode = $doc.DocumentElement.SelectSingleNode("$basePath/$prereleaseNameLabel") 
    $buildSuffixNode = $doc.DocumentElement.SelectSingleNode("$basePath/$buildSuffixLabel") 
    $buildNumberNode = $doc.DocumentElement.SelectSingleNode("$basePath/$buildNumberLabel")
    $versionPrefixNode = $doc.DocumentElement.SelectSingleNode("$basePath/$versionPrefixLabel") 
    $versionSuffixNode = $doc.DocumentElement.SelectSingleNode("$basePath/$versionSuffixLabel") 
    $version = $doc.DocumentElement.SelectSingleNode("$basePath/$versionLabel")

    if ($null -eq $versionSuffixNode) {
        [System.Xml.XmlElement]$versionSuffixNode = $doc.CreateElement($versionSuffixLabel)
        $versionSuffixNode.InnerText = [string]::Empty
        $doc.DocumentElement.SelectSingleNode($basePath).AppendChild($versionSuffixNode);
    }

    if ($null -eq $versionPrefixNode) {
        [System.Xml.XmlElement]$versionPrefixNode = $doc.CreateElement($versionPrefixLabel)
        $versionPrefixNode.InnerText = $defaultPrefix
        $doc.DocumentElement.SelectSingleNode($basePath).AppendChild($versionPrefixNode);
    }
    
    if ($null -eq $buildNumberNode) {
        [System.Xml.XmlElement]$buildNumberNode = $doc.CreateElement($buildNumberLabel)
        $buildNumberNode.InnerText = $defaultBuildNumber
        $doc.DocumentElement.SelectSingleNode($basePath).AppendChild($buildNumberNode);
    }

    if ($null -eq $prereleaseNameNode) {
        [System.Xml.XmlElement]$prereleaseNameNode = $doc.CreateElement($prereleaseNameLabel)
        $prereleaseNameNode.InnerText = $defaultPrereleaseName
        $doc.DocumentElement.SelectSingleNode($basePath).AppendChild($prereleaseNameNode);
    }
    
    if ($null -eq $buildSuffixNode) {
        [System.Xml.XmlElement]$buildSuffixNode = $doc.CreateElement($buildSuffixLabel)
        $buildSuffixNode.InnerText = $defaultBuildSuffix
        $doc.DocumentElement.SelectSingleNode($basePath).AppendChild($buildSuffixNode);
    }

    if ($null -eq $isPrereleaseNode) {
        [System.Xml.XmlElement]$isPrereleaseNode = $doc.CreateElement($isPrereleaseLabel)
        $isPrereleaseNode.InnerText = "false"
        $doc.DocumentElement.SelectSingleNode($basePath).AppendChild($isPrereleaseNode);
    }

    $prereleaseNameNode.InnerText = $(Get-StringCoalesce $Prerelease $(Get-StringCoalesce $prereleaseNameNode.InnerText $defaultPrereleaseName))
    $buildSuffixNode.InnerText = $(Get-StringCoalesce $Build $(Get-StringCoalesce $buildSuffixNode.InnerText $defaultBuildSuffix))

    $isPrereleaseConfirmed = $false
    if ($IsPrerelease.IsPresent) {
        $isPrereleaseNode.InnerText = "true"
        $isPrereleaseConfirmed = $true
    }

    if ($IsRelease.IsPresent) {
        $prereleaseNameNode.InnerText = $defaultPrereleaseName
        $isPrereleaseNode.InnerText = "false"
    }


    if ($null -eq $version) {
        [System.Xml.XmlElement]$version = $doc.CreateElement($versionLabel)
        $version.InnerText = [string]::Empty
        $doc.DocumentElement.SelectSingleNode($basePath).AppendChild($version);
        $doc.Save($ProjectFileName)
    }
    if ($Force.IsPresent -or (!$isPrereleaseConfirmed) ) {
        $configured = $false
        if ($Major.IsPresent -and !$configured) {
            $versionPrefixNode.InnerText = Get-NextVersion -Version $versionPrefixNode.InnerText -Major 
            $configured = $true
        }

        if ($Minor.IsPresent -and !$configured) {
            $versionPrefixNode.InnerText = Get-NextVersion -Version $versionPrefixNode.InnerText -Minor 
            $configured = $true
        }

        if ($Patch.IsPresent -and !$configured) {
            $versionPrefixNode.InnerText = Get-NextVersion -Version $versionPrefixNode.InnerText -Patch
            $configured = $true
        }
        if (!$configured) {
            $versionPrefixNode.InnerText = Get-NextVersion -Version $versionPrefixNode.InnerText -Patch
        }
    }

    $suffix = "$($prereleaseNameNode.InnerText)-$([System.DateTimeOffset]::Now.ToString("yyyyMMddHHmmssfff"))-$($buildSuffixNode.InnerText).$($buildNumberNode.InnerText)"
    $versionSuffixNode.InnerText = $isPrereleaseConfirmed ? $suffix : [string]::Empty
    $version.InnerText = "$($versionPrefixNode.InnerText)$($isPrereleaseConfirmed ? "-$suffix" : [string]::Empty)"
    $doc.Save($ProjectFileName)
    return $version.InnerText
}

function Read-Key {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Prompt = "Press any key to continue",
    
        [Parameter()]
        [bool]
        $Display = $false,

        [Parameter()]
        [bool]
        $Discard = $true
    )
    Write-Host "$Prompt " -NoNewline -ForegroundColor DarkGray
    $key = [Console]::ReadKey(!$Display)
    if (!(($key -eq 13) -or ($key -eq 10))) {
        [Console]::WriteLine()
    }

    if (!$Discard) {
        return $key
    }
}

function Get-VariableName {
    Param(
        [Parameter()]    
        [System.Object]
        $Variable
    )
    $Line = @(Get-PSCallStack)[1].Position.Text
        
    if ($Line -match '(.*)(Get-VariableName)([ ]+)(-Variable[ ]+)*\$(?<varName>([\w]+:)*[\w]*)(.*)') {
        #https://regex101.com/r/Uc6asf/1
        return $Matches['varName'] 
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

function Set-LocalEnvironmentVariable {
    param (
        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Value,

        [Parameter()]
        [Switch]
        $Append
    )

    function Write-MyMessage {
        param(
            [System.String]
            $VarName
        )
        WWrite-Host "Local Environment variable " -ForegroundColor DarkYellow -NoNewline
        Write-Host "`"$VarName`"" -NoNewline -ForegroundColor Yellow
        Write-Host "  ➡  " -ForegroundColor DarkYellow -NoNewline
        Write-Host "`"$((Get-Item env:$VarName).Value)`"" -ForegroundColor Yellow
    }

    if ($Append.IsPresent) {
        if (Test-Path "env:$Name") {
            $Value = (Get-Item "env:$Name").Value + $Value
        }
    }
    Set-Item env:$Name -Value "$value" | Out-Null
    if ($PSBoundParameters.Verbose.IsPresent) {
        Write-MyMessage -VarName $Name
    }
}

function Set-PersistentEnvironmentVariable {
    param (
        [Parameter()]
        [System.String]
        $Name,
    
        [Parameter()]
        [System.String]
        $Value,
    
        [Parameter()]
        [Switch]
        $Append        
    )
    
    function Write-MyMessage {
        param(
            [System.String]
            $VarName
        )
        Write-Host "Persistent Environment variable " -NoNewline -ForegroundColor DarkYellow
        Write-Host "`"$VarName`"" -NoNewline -ForegroundColor Yellow
        Write-Host "  ➡  " -NoNewline -ForegroundColor DarkYellow
        Write-Host "`"$((Get-Item env:$VarName).Value)`"" -ForegroundColor Yellow
    }

    Set-LocalEnvironmentVariable -Name $Name -Value $Value -Append:$Append
    if ($Append.IsPresent) {
        $value = (Get-Item "env:$Name").Value
    }
    if ($IsWindows) {
        setx "$Name" "$Value" | Out-Null
        if ($PSBoundParameters.Verbose.IsPresent) {
            Write-MyMessage -VarName $Name
        }
        return
    }
    $pattern = "\s*export[ \t]+$Name=[\w]*[ \t]*>[ \t]*\/dev\/null[ \t]*;[ \t]*#[ \t]*$Name\s*"
    if ($IsLinux) {
        $file = "~/.bash_profile"
        $content = (Get-Content "$file" -ErrorAction Ignore -Raw) + [System.String]::Empty
        $content = [System.Text.RegularExpressions.Regex]::Replace($content, $pattern, [String]::Empty);
        $content += [System.Environment]::NewLine + [System.Environment]::NewLine + "export $Name=$Value > /dev/null ;  # $Name"
        Set-Content "$file" -Value $content -Force
        if ($PSBoundParameters.Verbose.IsPresent) {
            Write-MyMessage -VarName $Name
        }
        return
    }
    if ($IsMacOS) {
        $file = "~/.zprofile"
        $content = (Get-Content "$file" -ErrorAction Ignore -Raw) + [System.String]::Empty
        $content = [System.Text.RegularExpressions.Regex]::Replace($content, $pattern, [String]::Empty);
        $content += [System.Environment]::NewLine + [System.Environment]::NewLine + "export $Name=$Value > /dev/null ;  # $Name"
        Set-Content "$file" -Value $content -Force
        if ($PSBoundParameters.Verbose.IsPresent) {
            Write-MyMessage -VarName $Name
        }
        return
    }
    throw "Invalid platform."
}

function Get-JsonObject {
    param (
        [String]
        [parameter(Mandatory = $true)]
        $Filename
    )
    
    if (Test-Path $Filename -PathType Leaf) {
        return (Get-Content -Path $Filename | ConvertFrom-Json)
    }
    
    throw "Invalid file `"$Filename`""
}

function Set-JsonObject {
    param (
        [object]
        [parameter(Mandatory = $true, Position = 0)]
        $Value,

        [String]
        [parameter(Mandatory = $true, Position = 1)]
        $Filename
    )
    
    $json = ConvertTo-Json $Value
    Set-Content $Filename -Value $json
}

function Get-ItemTree {
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

function Remove-ItemTree {
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String]
        $Path
    )
    (Get-ItemTree -Path $Path -Force -IncludePath) | ForEach-Object {
        Remove-Item "$($_.PSPath)" -Force
        if ($PSBoundParameters.ContainsKey("Verbose")) {
            Write-InfoYellow -Information "Deleted: $($_.PSPath)"
        }
    }
}

function Test-GitRepository {
    param (
        [Parameter()]
        [System.String]
        $Path
    )
    if (!(Test-Path $Path -PathType Container)) {
        return $false
    }
    try {
        Push-Location $Path
        $result = $(Test-Command "git rev-parse --is-inside-work-tree --quiet")
        return $result
    }
    finally {
        Pop-Location
    }
}

function Set-GitRepository {
    param (
        [Parameter()]
        [System.String]
        $RepositoryUrl,

        [Parameter()]
        [System.String]
        $Path = [System.String]::Empty
    )
    $Path = ([System.String]::IsNullOrWhiteSpace($Path) ? "$X_TEMP_DIR" : $Path)
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

function Get-ProjectSecretsId {
    param (
        [string]
        [Parameter()]
        $Project
    )
    $xml = [System.Xml.Linq.XDocument]::Parse((Get-Content -Path $Project -Raw))
    return $xml.Root.Elements("PropertyGroup").Elements("UserSecretsId").Value;
}

function Get-TextEditor {
    param (
        [string]
        [Parameter()]
        $Editor = "code"
    )

    if (Get-Command $Editor -ErrorAction Ignore) {
        return $Editor
    }

    if (Get-Command "code" -ErrorAction Ignore) {
        return "code"
    }

    if ($IsWindows) {
        return "notepad.exe"
    }
    if ($IsLinux) {
        if (Get-Command "nano" -ErrorAction Ignore) {
            return "nano"
        }

        if (Get-Command "vim" -ErrorAction Ignore) {
            return "vim"
        }

        if (Get-Command "vi" -ErrorAction Ignore) {
            return "vi"
        }
        
    }
    if ($IsMacOS) {
        return "open -e"
    }

    throw "No text editor was found."
}

function Get-ProjectUserSecretsFilename {
    param (
        [string]
        [Parameter()]
        $SecretsId
    )
    return Select-ValueByPlatform -WindowsValue "$($env:APPDATA)\Microsoft\UserSecrets\$SecretsId\secrets.json" -LinuxValue "$(Get-UserHome)/.microsoft/usersecrets/$SecretsId/secrets.json" -MacOSValue "$(Get-UserHome)/.microsoft/usersecrets/$SecretsId/secrets.json"
}

function Edit-ProjectUserSecrets {
    param (
        [string]
        [Parameter()]
        $ProjectFileName = "*.csproj",

        [string]
        [Parameter()]
        $Editor = "code"
    )
    
    $ProjectFileName = (Get-Item -Path $ProjectFileName).FullName
    Write-PrettyKeyValue "██ Opening secrets for project" "`"$projectFilename`"" -LabelForegroudColor Blue
    
    $secretsId = Get-ProjectSecretsId $projectFilename
    if ([string]::IsNullOrWhiteSpace($secretsId)) {
        Write-InfoBlue "█ Initializing secrets"
        dotnet user-secrets init --project $projectFilename
    }
    $secretsId = Get-ProjectSecretsId $projectFilename
    Write-PrettyKeyValue "UserSecretsId" $secretsId -LabelForegroudColor Blue

    $SecretsFilename = (Get-ProjectUserSecretsFilename $secretsId)
    Write-PrettyKeyValue "█ Secrets - Json file" "$SecretsFilename" -LabelForegroudColor Blue
    if (!(Test-Path $SecretsFilename -PathType Leaf)) {
        New-Item $SecretsFilename -Value "{$([System.Environment]::NewLine)   $([System.Environment]::NewLine)}" -Force
    }

    $Editor = Get-TextEditor $Editor
    & $editor $SecretsFileName 
}

function Show-ProjectUserSecrets {
    param (
        [string]
        [Parameter()]
        $ProjectFileName = "*.csproj"
    )
    
    $ProjectFilename = (Get-Item -Path $ProjectFileName).FullName
    Write-PrettyKeyValue "██ Listing secrets for project" "`"$ProjectFilename`"" -LabelForegroudColor Blue
    
    $secretsId = Get-ProjectSecretsId $ProjectFilename
    if ([string]::IsNullOrWhiteSpace($secretsId)) {
        Write-InfoBlue "█ Initializing secrets"
        dotnet user-secrets init --project $ProjectFilename
    }
    $secretsId = Get-ProjectSecretsId $ProjectFilename
    Write-PrettyKeyValue "UserSecretsId" $secretsId -LabelForegroudColor Blue
    
    Write-InfoBlue "█ Secrets in project"
    dotnet user-secrets list --project $ProjectFilename
    $SecretsFilename = (Get-ProjectUserSecretsFilename $secretsId)
    Write-PrettyKeyValue "█ Secrets - Json file" "$SecretsFilename" -LabelForegroudColor Blue
    if (!(Test-Path $SecretsFilename -PathType Leaf)) {
        New-Item $SecretsFilename -Value "{$([System.Environment]::NewLine)   $([System.Environment]::NewLine)}" -Force
    }
    Write-Host (Get-Content -Path (Get-ProjectUserSecretsFilename $secretsId) -Raw)

}

function Test-Command {
    param (
        [string]$Command,

        [switch]
        $NoOutput, 

        [switch]
        $ThrowOnFailure 
    )
    try {
        if($NoOutput.IsPresent)
        {
            Invoke-Expression -Command $Command | Out-Null
        }
        else
        {
            Invoke-Expression -Command $Command | Out-Host
        }
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            if (!($NoOutput.IsPresent)) {
                Write-Host "✅ Command: $Command "
            }
            return $true
        }
        throw
    }
    catch {
        if (!$NoOutput.IsPresent) {
            Write-Host "❌ Command: $Command"
        }
        if($ThrowOnFailure)
        {
            throw "An error occurred while executing the command."
        }
        return $false
    }
}

function Get-HexRandomName {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Prefix = "_",

        [Parameter()]
        [int]
        $BytesSize = 8
    )
    $bytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
    $hexString = -join ($bytes | ForEach-Object { $_.ToString("X2") })
    return "$Prefix$hexString"
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

# █████ Extras █████

class BotanVersionSet : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return @("2.19.3")
    }
}


function Install-BotanLibrary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet([BotanVersionSet], IgnoreCase = $false, ErrorMessage = "Value `"{0}`" is invalid. Try one of: `"{1}`"")]
        [string]
        $Version
    )
    $folder = "Botan-$Version"
    $filename = "$folder.tar.xz"
    $botanUri = "https://botan.randombit.net/releases/$fileName"
    Invoke-WebRequest -Uri "$botanUri" -OutFile $filename -Headers @{"Cache-Control" = "no-cache" } | Out-Null
    Write-Host "$Version"
    #& "$(Select-ValueByPlatform -WindowsValue "tar -xvf $filename" -LinuxValue "" -MacOSValue "")"
}


Set-GlobalConstant -Name "X_TEMP_DIR_NAME" -Value ".PsCoreFxsTemp"
Set-GlobalConstant -Name "X_TEMP_DIR" -Value "$(Get-UserHome)/$X_TEMP_DIR_NAME"

Set-GlobalConstant -Name "SQLSERVER_PROVIDER" -Value "SqlServer"
Set-GlobalConstant -Name "POSTGRESQL_PROVIDER" -Value "PostgreSql"
Set-GlobalConstant -Name "MYSQL_PROVIDER" -Value "MySql"
Set-GlobalConstant -Name "ORACLE_PROVIDER" -Value "Oracle"
Set-GlobalConstant -Name "ALL_PROVIDER" -Value "All"

Set-GlobalConstant -Name "7ZIP_URI" -Value "https://www.7-zip.org/a/7z2201-x64.exe"
Set-GlobalConstant -Name "NUGET_ORG_URI" -Value "https://api.nuget.org/v3/index.json"
