<#PSScriptInfo
.VERSION 1.0.1
.GUID 2d80b74b-905a-4d91-97af-35f0d3fe56e7
.AUTHOR Michael Niehaus
.COMPANYNAME
.COPYRIGHT
.TAGS Windows
.LICENSEURI https://github.com/mtniehaus/PS7Bootstrap/LICENSE
.PROJECTURI https://github.com/mtniehaus/PS7Bootstrap
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
v1.0 - Initial version
#>

<#
.SYNOPSIS
This script will ensure that a current PowerShell 7 version is installed, and will re-run the script using that instead of PowerShell 5.1.

.DESCRIPTION
This script will ensure that a current PowerShell 7 version is installed, and will re-run the script using that instead of PowerShell 5.1.  
If the needed version of PowerShell 7 is not found, it will be installed using WinGet.  To make sure that WinGet is up to date (and working),
the Update-InboxApp script will ensure that the Desktop App Installer app (which contains WinGet) is also up to date.

.EXAMPLE
# Relaunch as PowerShell 7 if necessary
if ($PSVersionTable.PSVersion.Major -ne 7) {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    Install-Script PS7Bootstrap -Force -ErrorAction Ignore
    PS7Bootstrap.ps1 $PSCommandPath
    Exit $LASTEXITCODE
}
Write-Host "In PowerShell 7!"

.NOTES
See https://oofhours.com for more information.
 
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $False, Position = 0)] [String] $Script = "",
    [Parameter(Mandatory = $False)] [String] $MinimumVersion = "7.4.3"
)

# Check the current installed PowerShell version
if (Test-Path "HKLM:\Software\Microsoft\PowerShellCore\InstalledVersions") {
    $version = Get-ChildItem "HKLM:\Software\Microsoft\PowerShellCore\InstalledVersions" | Get-ItemPropertyValue -Name SemanticVersion | Measure-Object -Maximum
    $currentVersion = $version.Maximum
    Write-Host "Current PowerShell version = $currentVersion"
} else {
    Write-Host "No PowerShell LTS version found."
    $currentVersion = "0.0.0"
}
Write-Host "Minimum PowerShell version = $MinimumVersion"

# Install or upgrade as needed
if ($currentVersion -lt $MinimumVersion) {

    Write-Host "Installing PowerShell LTS"
    Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI"

    # Make sure we have the current path (including pwsh.exe).  Note that this will drop any user path entries.
    $newPath = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH).Path
    $env:Path = $newPath
}

# If a script was specified, run it using the installed PowerShell LTS version from the path
if ($Script -ne "") {
    Try {
        & pwsh.exe -ExecutionPolicy bypass -File $Script
    }
    Catch {
        Throw "Failed to start $PSCOMMANDPATH"
    }    
}
