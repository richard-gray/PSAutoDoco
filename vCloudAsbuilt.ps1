Param(
    [string]$ClientName=(Read-Host "Enter Client Name"),
    [string]$Package=(Read-Host "Enter Package Name"),
    [string]$Offline=$false,
    [string]$AccessKey="",
    [string]$SecretKey="",
    [string]$AWSBucket=""
)
#Import PSDA.Gathering module
Import-Module .\PSDA.Processing.psm1

#Import of AWS Keys for Testing
Import-Module C:\temp\AWSCreds.psm1
$AccessKey = Get-AccessKey
$SecretKey = Get-SecretKey
$AWSBucket = Get-AWSBucket


#ScriptName is used to define the product and binds this script to the data-processing script (alpha numeric only, no spaces), eg, VMwareVCenter, EMCUnity, MSExchange, CiscoUCS
$ScriptName = "vCloudAsbuilt"
$PreviousScript = "vCloudGathering"
$NextScript = "PSDA.Presentation"

Get-Package -Package $Package -Offline $Offline -PreviousScript $PreviousScript -ScriptName $ScriptName -AccessKey $AccessKey -SecretKey $SecretKey -AWSBucket $AWSBucket
$Report = New-Report -ScriptName $ScriptName -ClientName $Package.Split("-")[0]
$PackageDirectory = (Get-Location).Path + "\$Package\"

Write-Host "Importing CliXML..." -NoNewline
$Catalog = Import-Clixml -Path ($PackageDirectory + "Get-Catalog")
Write-Host "." -NoNewline
$CINetworkAdapter = Import-Clixml -Path ($PackageDirectory + "Get-CINetworkAdapter")
Write-Host "." -NoNewline
$CIRole = Import-Clixml -Path ($PackageDirectory + "Get-CIRole")
Write-Host "." -NoNewline
$CIUser  = Import-Clixml -Path ($PackageDirectory + "Get-CIUser")
Write-Host "." -NoNewline
$CIVApp = Import-Clixml -Path ($PackageDirectory + "Get-CIVApp")
Write-Host "." -NoNewline
$CIVAppTemplate = Import-Clixml -Path ($PackageDirectory + "Get-CIVAppTemplate")
Write-Host "." -NoNewline
$CIVM = Import-Clixml -Path ($PackageDirectory + "Get-CIVM")
Write-Host "." -NoNewline
$CIVMTemplate = Import-Clixml -Path ($PackageDirectory + "Get-CIVMTemplate")
Write-Host "." -NoNewline
$Media = Import-Clixml -Path ($PackageDirectory + "Get-Media")
Write-Host "." -NoNewline
$Org = Import-Clixml -Path ($PackageDirectory + "Get-Org")
Write-Host "." -NoNewline
$OrgVDC = Import-Clixml -Path ($PackageDirectory + "Get-OrgVDC")
Write-Host "." -NoNewline
$OrgvdcNetwork = Import-Clixml -Path ($PackageDirectory + "Get-OrgvdcNetwork")
Write-Host "Done" -ForegroundColor Green

#Title
$Org.ExtensionData.FullName + " TD Cloud Asbuilt" | Add-Title -Level 1
"Organization" | Add-Title -Level 2

#Org Overview
$OrgTable = @{}
$OrgTable.Add("Full Name",$org.ExtensionData.FullName)
$OrgTable.Add("Short Name",$org.ExtensionData.Name)
$OrgTable.Add("OrgVDC Name",$org.ExtensionData.Vdcs.Vdc.Name)
$OrgTable.Add("CPU Allocation",[string]$Orgvdc.CpuAllocationGhz + " GHz")
$OrgTable.Add("Memory Allocation",[string]$Orgvdc.MemoryAllocationGB + " GB")
$OrgTable.Add("Storage Allocation",[string]$Orgvdc.StorageAllocationGB + " GB")
$OrgTable.Add("CPU Allocation Used",[string]$Orgvdc.CpuUsedGhz + " GHz")
$OrgTable.Add("Memory Allocation Used",[string]$Orgvdc.MemoryUsedGB + " GB")
$OrgTable.Add("Storage Allocation Used",[string]$Orgvdc.StorageUsedGB + " GB")
$OrgTable | Add-VerticalTable -Title "Overview" -Level 3 -Caption "Org Overview"

#Networks
$OrgvdcNetwork | Select-Object @{Name='Name'; Expression={$_.Name}},
@{Name='Network Type'; Expression={$_.NetworkType}},
@{Name='Subnet Mask'; Expression={$_.Netmask}},
@{Name='Primary DNS'; Expression={$_.PrimaryDNS}},
@{Name='Secondary DNS'; Expression={$_.SecondaryDNS}},
@{Name='Static IP Pool'; Expression={$_.StaticIPPool}} | 
Add-Table -Title "Networks" -Caption "Org Networks" -Level 3

#VApps
$CIVApp | Select-Object @{Name='Name'; Expression={$_.Name}},
@{Name='Status'; Expression={$_.Status}},
@{Name='vCPUs'; Expression={$_.CpuCount}},
@{Name='vRAM'; Expression={[string]$_.MemoryAllocationGB + " GB"}},
@{Name='Storage Allocated'; Expression={[string]$_.SizeGB + " GB"}},
@{Name='Owner'; Expression={$_.Owner}},
@{Name='VMs'; Expression={$_.ExtensionData.Children.VM | % { return $_.Name + " "}}} | 
Add-Table -Title "VApps" -Caption "vApps" -Level 3

#VM Hardware
#To do add NIC, MAC address
$CIVM | Select-Object @{Name='Name'; Expression={$_.Name}},
@{Name='Status'; Expression={$_.Status}},
@{Name='vCPUs'; Expression={$_.CpuCount}},
@{Name='vRAM'; Expression={[string]$_.MemoryGB + " GB"}},
@{Name='Storage Tier'; Expression={$_.ExtensionData.StorageProfile.Name}} | 
Add-Table -Title "Virtual Machine Hardware" -Caption "Virtual Machine Hardware" -Level 3
#@{Name='Storage Allocated'; Expression={[string]$_.SizeGB + " GB"}},

#VM Details
$CIVM | Select-Object @{Name='Name'; Expression={$_.Name}},
@{Name='VApp'; Expression={$_.VApp}},
@{Name='VM Version'; Expression={$_.VMVersion}},
@{Name='Guest Operating System'; Expression={$_.GuestOsFullName}},
@{Name='Memory Hot Add Enabled'; Expression={[String]$_.ExtensionData.VmCapabilities.MemoryHotAddEnabled}},
@{Name='CPU Hot Add Enabled'; Expression={[String]$_.ExtensionData.VmCapabilities.CpuHotAddEnabled}} | 
Add-Table -Title "Virtual Machine Additional Information" -Caption "Virtual Machine Additional Information" -Level 3

#VM Templates
#$OrgCatalogs = $Catalog | Where-Object { $_.Org.Name -eq $org.Name}
#$OrgCatalogs | % {
#    $_.ExtensionData.CatalogItems.CatalogItem | Select-Object @{Name='Name'; Expression={$_.Name}},
#}
#Media


#Administration Section
"Administration" | Add-Title -Level 2

#Users
$CIUser | Select-Object @{Name='Name'; Expression={$_.FullName}},
@{Name='Username'; Expression={$_.Name}},
@{Name='Email Address'; Expression={$_.Email}},
@{Name='Phone'; Expression={$_.Phone}},
@{Name='Enabled'; Expression={$_.Enabled}},
@{Name='Locked'; Expression={$_.Locked}},
@{Name='Role'; Expression={$_.ExtensionData.Role.Name}} | 
Add-Table -Title "Users" -Caption "Org Users" -Level 3

#Roles
"User Roles" | Add-Title -Level 3

#Table for each role
$CIRole | % {
    $RoleName = $_.Name 
    $RoleDescription = $_.Description 
    $_.Rights | Select-Object @{Name='Category'; Expression={$_.Category}},
    @{Name='Right'; Expression={$_.Name}},
    @{Name='Description'; Expression={$_.Description}} | Add-Table -Title "$RoleName" -Caption "$RoleName Rights" -Level 4 -Description $RoleDescription
}

#Run the Submit-Report fuction once at the end of the script body to upload to S3 (and in future trigger cloud processing)
Submit-Report -Report $Report -Package $Package -AccessKey $AccessKey -SecretKey $SecretKey -AWSBucket $AWSBucket -Offline $Offline -RemoveDirectory $false

#Check if Presentation Script is local and ask to run it
If(Test-Path -path "$NextScript.ps1"){
    do{
        $y = Read-Host "Run Presentation Now?([y]/n)"    
    }until($y -eq "y" -or $y -eq "n" -or $y -eq "")
    If($y -eq "y" -or $y -eq ""){
        $Command = ".\$NextScript.ps1 -Report $Report -Offline $Offline -ClientName $ClientName -AccessKey $AccessKey -SecretKey $SecretKey -AWSBucket $AWSBucket"
        Invoke-Expression $Command
    }
}