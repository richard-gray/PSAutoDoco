#Requires -Version 3.0
#Requires -Modules AWSPowerShell

#region Script Help

<#
.SYNOPSIS  
    Data Processing Example Script
.DESCRIPTION
    Data Processing Example Script
.NOTES
    Version:        1.0
    Author:         Richard Gray
.LINK
    NA
.EXAMPLE
    .\Data-Gathering.ps1
    Runs the data Gathing script and uploads to S3
#>

#endregion

#region script changelog

<#
.VERSION 1.0 - 7/05/2016
              
 - Initial script development
#>

#endregion

#region Script Parameters

#endregion


#region Set and Forget Variables

$AccessKey = ""
$SecrectKey = ""
$ScriptName = "DataProcessing"
$AWSBucket = "tddocumentation"

#endregion


#region Script Functions

#Add Title to the Report
Function Add-Title{
    Param(
        [string]$Title
    )
    #Add Title
}

#Adds a Paragrah to the Report
Function Add-Paragraph{
    Param(
        [string]$Body
    )
    #Add Paragraph
}

#Adds a Table to the Report
Function Add-Table{
    Param(
        [string]$Title,
        [string]$Caption
    )
    $Input | Export-Csv
    
    $Title
    $Caption
}

#endregion


$x=0
$Packages=@{}
Get-S3Object -BucketName $AWSBucket -AccessKey $AccessKey -SecretKey $SecretKey  | Where-Object {
    $_.Key.Split("-") -eq $ScriptName
} |  % {
    $x++;
    $Packages.Set_item($x,$_.key)
    write-host "[$x]" ($_.key.split("-")[0]) ([datetime][long]$_.key.split("-")[2]) 
}
$z = Read-Host "Pick a Package Number"

$Path = (Get-Location).Path 
$ClientName = ($_.key.split("-")[0])
$Package = $Packages.item([int]$z)
$PackageDirectory = $Path + "\" + $Package
$PackageZip = $Package + ".zip"
$PackageZipDirectory = $Path + "\" + $PackageZip

$Ticks = (Get-Date).Ticks
$Report = $ClientName + "-" + $ScriptName + "-" + $Ticks
$ReportDirectory = $Path + "\" + $Report
$ReportZip = $ReportDirectory + ".zip"


Read-S3Object -BucketName $AWSBucket -Key $Package -File $PackageZip -AccessKey $AccessKey -SecretKey $SecretKey
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::ExtractToDirectory($PackageZipDirectory,$PackageDirectory)

Add-Title -Title (Import-Clixml -Path ($PackageDirectory + "\" + "Get-Date.xml")).Year
Import-Clixml -Path ($PackageDirectory + "\" + "Get-ChildItem.xml") | Select Name, Mode, LastWriteTime | Add-Table -Title "Directory Listing" -Caption "Directory Listing"
Import-Clixml -Path ($PackageDirectory + "\" + "Get-Process.xml") | Select ProcessName, Handles, "CPU(s)" | Add-Table -Title "Process Listing" -Caption "Process Listing"
