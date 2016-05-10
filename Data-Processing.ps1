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
    Twitter:        @goodgigs
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
$ScriptName = "DataGathering"
$AWSBucket = "tddocumentation"

#endregion
$x=0

$Packages=@{}
Get-S3Object -BucketName "tddocumentation" | Where-Object {
    $_.Key.Split("-") -eq $ScriptName
} |  % {
    $x++;
    $Packages.Set_item($x,$_.key)
    write-host "[$x]" ($_.key.split("-")[0]) ([datetime][long]$_.key.split("-")[2]) 
}
$z = Read-Host "Pick a Package Number"

Read-S3Object -BucketName "tddocumentation" -Key $Packages.item([int]$z) -File ($Packages.item([int]$z) + ".zip")


