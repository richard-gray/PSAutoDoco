#Requires -Version 3.0
#Requires -Modules AWSPowerShell

#region Script Help

<#
.SYNOPSIS  
    PowerShell Documentation Automation Script.
    This script is used for gathering information from PowerShell Cmdlets for processesing at a later stage
.DESCRIPTION
PowerShell Documentation Automation Script.
    This script is used for gathering information from PowerShell Cmdlets for processesing at a later stage
.NOTES
    Version:        1.0
    Author:         Richard Gray
.LINK
    https://github.com/PSAutoDoco/PSAutoDoco
.EXAMPLE
    Import-Module .\PSDA.Gathering.psm1
    #Run the New-package cmdlet once at the very start of the script body
    New-Package -ScriptName $ScriptName -ClientName $ClientName

    #Run cmdlets and pipe them to Add-Capture for use in the Data-Processing script
    Get-childitem  | Add-Capture -CaptureName "get-childitem"
    Get-process | Add-Capture -CaptureName "get-process"
    Get-Date | Add-Capture -CaptureName "get-date"

    #Run the Submit-Package cmdlet once at the end of the script body to upload to S3 (and in future trigger cloud processing)
    Submit-Package -AccessKey $AccessKey -SecretKey $SecretKey -AWSBucket $AWSBucket
#>

#endregion

#region script changelog

<#
.VERSION 1.0 - 27/05/2016
    Contributors: Richard Gray
    -Initial Build

#>

#endregion

#region Script Cmdlets

#Setup a Package ready for Captures
Function New-Package {
    Param(
        [parameter(Mandatory=$True)][string]$ScriptName,
        [parameter(Mandatory=$True)][string]$ClientName,
        [string]$Offline
    )
    #Set Console Window Title
    $WindowTitle = (Get-Host).UI.RawUI
    $WindowTitle.WindowTitle = "$ScriptName Script"
    Write-Host "$ScriptName Script" -ForegroundColor Magenta
    write-host "https://github.com/PSAutoDoco/PSAutoDoco"
    if($Offline -eq $tue){
        Write-Host "OFFLINE MODE" -ForegroundColor Magenta
    }
    #Check ClientName
    if($ClientName -notmatch "^[a-zA-Z0-9]+$"){
        Write-Host "Invalid Client Name!" -ForegroundColor Red
        Write-Host "Alphanumeric only, no spaces or other characters" 
        do{
            $ClientName = Read-Host "Enter Client Name"
            If($ClientName -notmatch  "^[a-zA-Z0-9]+$"){
                Write-Host "Alphanumeric only, no spaces or other characters"  
            }  
        }until($ClientName -ne $null -and $ClientName -match "^[a-zA-Z0-9]+$")
    }
    Write-Host "Starting New Package..." -NoNewline
    #Get ticks as a time stamp for Package
    $Script:Ticks = (Get-Date).Ticks
    #Create the name of the Package using the Client Name, Script Name, and Ticks
    $Script:PackageName = $ClientName + "-" + $ScriptName + "-" + $Ticks
    $Script:PackageDirectory = (Get-Location).Path + "\$PackageName"
    $Script:PackageZip = $Script:PackageDirectory + ".zip"
    #Create Package Directory
    $Script:Setup = (New-Item $PackageDirectory -ItemType Directory)
    #Mark Setup as complete
    Write-Host "Done" -ForegroundColor Green
}
Export-ModuleMember -Function New-Package

#Add Captures to the Package
Function Add-Capture{
    Param(
        [string]$CaptureName
    )
    #Export CLI XML into Package Directory
    Write-host "Exporting CLI XML for $CaptureName..." -NoNewline
    $input | Export-Clixml -Path "$PackageDirectory\$CaptureName" 
    Write-Host "Done" -ForegroundColor Green
}
Export-ModuleMember -Function Add-Capture

#Submit Packages to S3 for archive/processing
Function Submit-Package {
    Param(
        [string]$AccessKey="",
        [string]$SecretKey="",
        [string]$AWSBucket="",
        [string]$Offline=$false,
        [bool]$RemovePackageDirectory=$false,
        [bool]$RemovePackageZip=$false

    )
    #Zip the Package Directory
    Write-Host "Zipping Package..." -NoNewline
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::CreateFromDirectory($PackageDirectory,$PackageZip)
    Write-Host "Done" -ForegroundColor Green
    #Test Internet Connectivity
    #Test-Connection

    #Upload the Zipped Package to S3
    Write-Host "Uploading to S3..." -NoNewline
    If($offline -eq $false){
        if($AccessKey -eq ""){
            do{
                $AccessKey = Read-host "Enter AWS Access Key"
            }until($AccessKey -ne "")
        }    
        if($SecretKey -eq ""){
            do{
                $SecretKey = Read-host "Enter AWS Secret Key"
           } until($SecretKey -ne "")
        } 
        if($AWSBucket -eq ""){
            do{
                $AWSBucket = Read-host "Enter AWS Bucket Name"
           } until($AWSBucket -ne "")
        } 
        Write-S3Object -BucketName $AWSBucket -File $PackageZip -Key $PackageName -AccessKey $AccessKey -SecretKey $SecretKey
        Write-Host "Done" -ForegroundColor Green
    }else{
        Write-Host "Skipping" -ForegroundColor Yellow
    }
    Write-host "Removing Package Directory..." -NoNewline
    If(($RemovePackageDirectory -eq $true) -or ($Offline -eq $false)){
        Remove-Item $PackageDirectory -Force -Recurse
        Write-host "Done" -ForegroundColor Green
    }else{
        Write-Host "Skipping" -ForegroundColor Yellow
    }    
    Write-host "Removing Zip..." -NoNewline
    If(($RemovePackageZip -eq $true) -or ($Offline -eq $false)){
        Remove-Item $PackageZip
        Write-host "Done" -ForegroundColor Green
    }else{
        Write-Host "Skipping" -ForegroundColor Yellow
    }
    Write-Host "Package Name [ " -NoNewline
    Write-Host $script:PackageName -NoNewline -ForegroundColor Green
    Write-Host " ]"
    Write-Host "Package Submited"
    return $script:PackageName
}
Export-ModuleMember -Function Submit-Package
#endregion