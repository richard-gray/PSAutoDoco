Param(
    [string]$ClientName=(Read-Host "Enter Client Name"),
    [string]$Org=(Read-Host "Enter vDC Org Name"),
    [string]$vCDServer=(Read-Host "Enter vDC Site URL"),
    [string]$Offline=$false,
    [string]$AccessKey="",
    [string]$SecretKey="",
    [string]$AWSBucket=""
)
#Import PSDA.Gathering module
Import-Module .\PSDA.Gathering.psm1
Import-Module VMware.VimAutomation.Cloud

#Import of AWS Keys for Testing
Import-Module C:\temp\AWSCreds.psm1
$AccessKey = Get-AccessKey
$SecretKey = Get-SecretKey
$AWSBucket = Get-AWSBucket

#region Script Body


$ScriptName = "vCloudGathering"
$NextScript = "vCloudAsbuilt"

#Start Package with input from paramters
$PackageName = New-Package -ScriptName $ScriptName -ClientName $ClientName -Offline $Offline

#Connect to vCD
Write-host "Connecting to [ " -NoNewline
Write-host $vCDServer -NoNewline -ForegroundColor Yellow
Write-Host " ]..." -NoNewline
If(Connect-CIServer -Server $vCDServer -Org $Org){
    Write-Host "Done" -ForegroundColor Green

    #Run all of the Get cmdlets for vCD even if not initially used in asbuilt, they may be used at a later date. 
    Get-Catalog | Add-Capture -CaptureName "Get-Catalog"
    Get-CINetworkAdapter | Add-Capture -CaptureName "Get-CINetworkAdapter"
    Get-CIRole | Add-Capture -CaptureName "Get-CIRole"
    Get-CIUser | Add-Capture -CaptureName "Get-CIUser"
    Get-CIVApp | Add-Capture -CaptureName "Get-CIVApp"
    Get-CIVAppTemplate | Add-Capture -CaptureName "Get-CIVAppTemplate"
    Get-CIVM | Add-Capture -CaptureName "Get-CIVM"
    Get-CIVMTemplate | Add-Capture -CaptureName "Get-CIVMTemplate"
    Get-Media | Add-Capture -CaptureName "Get-Media"
    Get-Org | Add-Capture -CaptureName "Get-Org"
    Get-OrgVDC | Add-Capture -CaptureName "Get-OrgVDC"
    Get-OrgvdcNetwork | Add-Capture -CaptureName "Get-OrgvdcNetwork"

    #Disconnect from vCD
    Disconnect-CIServer -Server $vCDServer -Confirm:$false

    #Upload the package to S3 or save it locally in offline mode
    $Package = Submit-Package -AccessKey $AccessKey -SecretKey $SecretKey -AWSBucket $AWSBucket -Offline $Offline

    #Check if Processing Script is local and ask to run it
    If(Test-Path -path "$NextScript.ps1"){
        do{
            $y = Read-Host "Run Processing Now?([y]/n)"    
        }until($y -eq "y" -or $y -eq "n" -or $y -eq "")
        If($y -eq "y" -or $y -eq ""){
            $Command = ".\$NextScript.ps1 -Package $Package -Offline $Offline -ClientName $ClientName -AccessKey $AccessKey -SecretKey $SecretKey -AWSBucket $AWSBucket"
            Invoke-Expression $Command
        }
    }
}else{
    Write-Host "Failed" -ForegroundColor Red
    Write-Host "Could not connect to vCloud Director"
}
#endregion