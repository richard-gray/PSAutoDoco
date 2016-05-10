#Requires -Version 3.0
#Requires -Modules AWSPowerShell

#region Script Help

<#
.SYNOPSIS  
    Data Gathering Example Script
.DESCRIPTION
    Data Gathering Example Script
.NOTES
    Version:        1.0
    Author:         Richard Gray
.LINK
    https://github.com/PSAutoDoco/PSAutoDoco
.EXAMPLE
    .\Data-Gathering.ps1
#>

#endregion


#region script changelog

<#
.VERSION 1.0 - 7/05/2016
              
- Initial script development
- ToDo
    -Add Files Directly into Zip file rather than zipping a directory at the end. This reduces the clutter created in script directories
    -Error Checking on Zip
    -Add Optional Paramater of ClientName and validate input
    -Test AWS credentials at the start of script before processing

-Future
    -Add Cloud Processing Trigger to script

#>

#endregion


#region Set and Forget Variables

#AWS Access Key, see richard for account
$AccessKey = ""
#AWS SecretKey Key, see richard for account
$SecretKey = ""
#ScriptName is used to define the product and binds this script to the data-processing script (alpha numeric only, no spaces), eg, VMwareVCenter, EMCUnity, MSExchange, CiscoUCS
$ScriptName = "DataGathering"
#AWSBucket is used to define the AWS target bucket
$AWSBucket = "tddocumentation"

#endregion


#region Script Functions

#Setup a Package ready for Captures
Function Setup-Package {
    #Set Console Window Title
    $WindowTitle = (Get-Host).UI.RawUI
    $WindowTitle.WindowTitle = "$ScriptName Script"
    Write-Host "$ScriptName Script"
    write-host "https://github.com/PSAutoDoco/PSAutoDoco"
    #Get ClientName if not set
    if(!$ClientName){
        do{
            $ClientName = Read-Host "Enter Client Name"
            If($ClientName -notmatch  "^[a-zA-Z0-9]+$"){
                Write-Host "Alphanumeric only, no spaces or other characters"  
            }  
        }until($ClientName -ne $null -and $ClientName -match "^[a-zA-Z0-9]+$")
    }
    Write-Host "Setting Up Package..." -NoNewline
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

#Add Captures to the Package
Function Add-Capture{
    Param(
        [string]$CaptureName
    )
    #Export CLI XML into Package Directory
    Write-host "Exporting CLI XML for $CaptureName..." -NoNewline
    $Input | Export-Clixml -Path "$PackageDirectory\$CaptureName.xml" 
    Write-Host "Done" -ForegroundColor Green
}

#Submit Packages to S3 for archive/processing
Function Submit-Package {
    #Zip the Package Directory
    Write-Host "Zipping Package..." -NoNewline
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::CreateFromDirectory($PackageDirectory,$PackageZip)
    Write-Host "Done" -ForegroundColor Green
    #Upload the Zipped Package to S3
    Write-Host "Uploading to S3..." -NoNewline
    Write-S3Object -BucketName $AWSBucket -File $PackageZip -Key $PackageName -AccessKey $AccessKey -SecretKey $SecretKey
    Write-Host "Done" -ForegroundColor Green
    Write-Host "Script Complete"
}

#endregion


#region Script Body

#Run the setup-package function once at the very start of the script body
Setup-Package

#Run commandlets and pipe them to Add-Capture for use in the Data-Processing script
Get-Date | Add-Capture -CaptureName "Get-Date"
Get-Process | Add-Capture -CaptureName "Get-Process"
Get-ChildItem | Add-Capture -CaptureName "Get-ChildItem"

#Run the Submit-Package fuction once at the end of the script body to upload to S3 (and in future trigger cloud processing)
Submit-Package

#endregion