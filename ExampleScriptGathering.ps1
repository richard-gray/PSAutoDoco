Param(
    [string]$ClientName=(Read-Host "Enter Client Name"),
    [string]$Offline=$false,
    [string]$AccessKey="",
    [string]$SecretKey="",
    [string]$AWSBucket=""
)
#Import PSDA.Gathering module
Import-Module .\PSDA.Gathering.psm1

#TEMP Import Saved Creds 
Import-Module C:\temp\AWSCreds.psm1
$AccessKey = Get-AccessKey
$SecretKey = Get-SecretKey
$AWSBucket = Get-AWSBucket

#region Script Body

#Script Name is used to define the product and binds this script to the data-processing script (alpha numeric only, no spaces), eg, VMwareVCenter, EMCUnity, MSExchange, CiscoUCS
$ScriptName = "ExampleScriptGathering"
#Next Script is used to trigger the next script
$NextScript = "ExampleScriptProcessing"

#Run the setup-package function once at the very start of the script body
$PackageName = New-Package -ScriptName $ScriptName -ClientName $ClientName -Offline $Offline

#Run commandlets and pipe them to Add-Capture for use in the Data-Processing script
Get-childitem  | Add-Capture -CaptureName "get-childitem" -Package $PackageName
Get-Date | Add-Capture -CaptureName "get-date"
Get-Process | Add-Capture -CaptureName "get-process"
Get-WmiObject -Class Win32_OperatingSystem | Add-Capture -CaptureName "windows-info"
Get-WmiObject -Class Win32_LogicalDisk | Add-Capture -CaptureName "drive-info"

#Run the Submit-Package fuction once at the end of the script body to upload to S3 (and in future trigger cloud processing)
$Package = Submit-Package -AccessKey $AccessKey -SecretKey $SecretKey -AWSBucket $AWSBucket -Offline $Offline

#Check if Processing Script is local and ask to run it
If((Get-ChildItem "$NextScript.ps1").Exists -eq $true -and (Get-ChildItem "").Exists -eq "$Package.zip"){
    do{
        $y = Read-Host "Run Processing Now?(y/n)[y]"    
    }until($y -eq "y" -or $y -eq "n" -or $y -eq "")
    If($y -eq "y" -or $y -eq ""){
        $Command = ".\$NextScript.ps1 -Package $Package -Offline $Offline -ClientName $ClientName -AccessKey $AccessKey -SecretKey $SecretKey -AWSBucket $AWSBucket"
        Invoke-Expression $Command
    }
}

#endregion