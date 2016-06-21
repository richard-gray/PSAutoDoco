#Requires -Version 3.0
#Requires -Modules AWSPowerShell

#region Script Help

<#
.SYNOPSIS  
    PowerShell Documentation Automation Script.
    These cmdlets is used for Processing information from a previously ran PSDA Gathering Script, once processed the output is sent for presentation
.DESCRIPTION
    PowerShell Documentation Automation Script.
    These cmdlets is used for Processing information from a previously ran PSDA Gathering Script, once processed the output is sent for presentation
.NOTES
    Version:        1.0
    Author:         Richard Gray
.LINK
    https://github.com/PSAutoDoco/PSAutoDoco
.EXAMPLE
 


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

#New-Report Creates a new report ready to take input
Function New-Report {
    Param(
        [parameter(Mandatory=$True)][string]$ScriptName,
        [parameter(Mandatory=$True)][string]$ClientName
    )
    #Get ClientName if not set
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
    Write-Host "Setting Up Report..." -NoNewline
    #Get ticks as a time stamp for Package
    $Ticks = (Get-Date).Ticks
    #Create the name of the Package using the Client Name, Script Name, and Ticks
    $script:ReportName = $ClientName + "-" + $ScriptName + "-" + $Ticks
    $script:ReportDirectory = (Get-Location).Path + "\$script:ReportName"
    $script:ReportZip = $Script:ReportDirectory + ".zip"
    #Create Package Directory
    $Setup = (New-Item $script:ReportDirectory -ItemType Directory)
    "File, Type, Title, Description, Caption, CustomCSS, Level, Language" | Out-file -FilePath "$script:ReportDirectory\0.csv"
    Write-Host "Done" -ForegroundColor Green
    Write-host $script:ReportName
    return $script:ReportName
}
Export-ModuleMember -Function New-Report

#Submit Report to S3 for archive/processing
Function Submit-Report {
    Param(
        [string]$AccessKey="",
        [string]$SecretKey="",
        [string]$AWSBucket="",
        [string]$Package="",
        [string]$Report="",
        [string]$Offline=$false,
        [bool]$RemoveDirectory=$true,
        [bool]$RemoveZip=$true

    )
    $script:Path = (Get-Location).Path + "\"
    $script:PackageDirectory = $script:Path + $Package
    $script:PackageZip = $script:PackageDirectory + ".zip"
    $script:ReportDirectory = $script:Path + $Report
    $script:ReportZip = $script:ReportDirectory + ".zip"    
    #Zip the Package Directory
    Write-Host "Zipping Report..." -NoNewline
    Add-Type -assembly "system.io.compression.filesystem"
    $Extract = [io.compression.zipfile]::CreateFromDirectory($script:ReportDirectory,$script:ReportZip)
    Write-Host "Done" -ForegroundColor Green
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
        Write-S3Object -BucketName $AWSBucket -File $script:ReportZip -Key $Report -AccessKey $AccessKey -SecretKey $SecretKey
        Write-Host "Done" -ForegroundColor Green   
    }else{
        Write-Host "Skipping" -ForegroundColor Yellow
    }
    Write-host "Removing Directories..." -NoNewline
    If(($script:RemovePackageDirectory -eq $true) -or ($Offline -eq $false)){
        Remove-Item $script:PackageDirectory -Force -Recurse
        Remove-Item $script:ReportDirectory -Force -Recurse
        Write-host "Done" -ForegroundColor Green
    }else{
        Write-Host "Skipping" -ForegroundColor Yellow
    }    
    Write-host "Removing Zip files..." -NoNewline
    If(($script:RemovePackageZip -eq $true) -or ($Offline -eq $false)){
        Remove-Item $script:PackageZip
        Remove-Item $script:ReportZip
        Write-host "Done" -ForegroundColor Green
    }else{
        Write-Host "Skipping" -ForegroundColor Yellow
    }    
    Write-Host "Report Name [ " -NoNewline
    Write-Host $Report -NoNewline -ForegroundColor Yellow
    Write-Host " ]"
    Write-Host "Script Complete"
}
Export-ModuleMember -Function Submit-Report

#Add Metadata to the Report, do not export this cmdlet
Function Add-Metadata{
    Param(
        [string]$File,
        [string]$Type,
        [string]$Title="",
        [string]$Description="",
        [string]$Caption="",
        [string]$CustomCSS="",
        [string]$Level="",
        [string]$Language=""
    )
    "$File, $Type, $Title, $Description, $Caption, $CustomCSS, $Level, $Language" | Out-File -FilePath "$ReportDirectory\0.csv" -Append
    Write-Host "." -NoNewline
}

#Add Title to the Report
Function Add-Title{
    Param(
        [parameter(ValueFromPipeline=$true)] $Title,
        [string]$Level=1,
        [string]$CustomCSS=""
    )
    $script:index++
    Write-Host "[$script:index]Adding Title..." -NoNewline
    Add-Metadata -File "$index.txt" -Type "Title" -CustomCSS $CustomCSS -Level $Level
    $Title | Out-File -FilePath "$script:ReportDirectory\$index.txt"
    Write-Host "Done" -ForegroundColor Green
}
Export-ModuleMember -Function Add-Title

#Adds a Paragrah to the Report
Function Add-Paragraph{
    Param(
        [parameter(ValueFromPipeline=$true)] $Paragraph,
        [string]$Title="",
        [string]$Level=1,
        [string]$CustomCSS=""
    )
    $script:index++
    Write-Host "[$script:index]Adding Paragraph..." -NoNewline
    Add-Metadata -File "$index.txt" -Type "Paragraph" -CustomCSS $CustomCSS -Level $Level -Title $Title
    $Paragraph | Out-File -FilePath "$script:ReportDirectory\$index.txt"
    Write-Host "Done" -ForegroundColor Green
}
Export-ModuleMember -Function Add-Paragraph

#Adds a Table to the Report
Function Add-Table{
    Param(
        [parameter(ValueFromPipeline=$true)]$Table,
        [string]$Title="",
        [string]$Level=1,
        [string]$Description="",
        [string]$Caption="",
        [string]$CustomCSS=""
    )    
    Begin {
        $script:index++
        Write-Host "[$script:index]Adding Table..." -NoNewline
        $container = @()
    }
    Process {
        $container += $Table
    }
    End{
        Add-Metadata -File "$index.csv" -Type "Table" -Title $Title -Caption $Caption -CustomCSS $CustomCSS -Level $Level -Description $Description
        $container | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath "$script:ReportDirectory\$index.csv"
        Write-Host "Done" -ForegroundColor Green
    }
}
Export-ModuleMember -Function Add-Table

#Add a Virtical Table to the Report
Function Add-VerticalTable{
    Param(
        [hashtable][parameter(ValueFromPipeline=$true)] $HashTable,
        [string]$Title="",
        [string]$Level=1,
        [string]$Description="",
        [string]$Caption="",
        [string]$CustomCSS=""
    )    
    $script:index++
    Write-Host "[$script:index]Adding Vertial Table..." -NoNewline
    $Table =  $HashTable.getEnumerator() | foreach { new-object -typename psobject -property @{Item = $_.name ; Configuration = $_.value } } | Select Item, Configuration 
    Add-Metadata -File "$index.csv" -Type "VerticalTable" -Title $Title -Caption $Caption -CustomCSS $CustomCSS -Level $Level -Description $Description
    $Table | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath "$script:ReportDirectory\$index.csv"
    Write-Host "Done" -ForegroundColor Green
}
Export-ModuleMember -Function Add-VerticalTable

#Adds a code snippit to the Report
Function Add-Code{
    Param(
        [parameter(ValueFromPipeline=$true)] $Code,
        [string]$Title="",
        [string]$Level=1,
        [string]$Description="",
        [string]$Caption="",
        [string]$Language="",
        [string]$CustomCSS=""
    ) 
    $script:index++   
    Write-Host "[$script:index]Adding Code..." -NoNewline
    Add-Metadata -File "$index.txt" -Type "Code" -Title $Title -Level $Level -Caption $Caption -CustomCSS $CustomCSS -Language $Language -Description $Description
    $Code | Out-File -FilePath "$ReportDirectory\$index.txt"
    Write-Host "Done" -ForegroundColor Green
}
Export-ModuleMember -Function Add-Code

#This section needs to be cleaned up
function Get-Package{
    Param(
        [string]$Package="",   
        [string]$AccessKey="",
        [string]$SecretKey="",
        [string]$AWSBucket="",
        [parameter(Mandatory=$True)][string]$ScriptName="",
        [string]$PreviousScript="",
        [string]$Offline=$false
    )  
    #Set Console Window Title
    $WindowTitle = (Get-Host).UI.RawUI
    $WindowTitle.WindowTitle = "$ScriptName Script" 
    Write-Host "$ScriptName-Procesing Script" -ForegroundColor Magenta
    write-host "https://github.com/PSAutoDoco/PSAutoDoco" 
    $Path = (Get-Location).Path 
    $Ticks = (Get-Date).Ticks
    If($Offline -eq $false){
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
        If($Package -eq ""){
            $x=0
            $Packages=@{}
            Get-S3Object -BucketName $AWSBucket -AccessKey $AccessKey -SecretKey $SecretKey  | Where-Object {
                $_.Key.Split("-")[1] -eq $ChildScript
            } |  % {
                $x++;
                $Packages.Set_item($x,$_.key)
                write-host "[$x]" ($_.key.split("-")[0]) ([datetime][long]$_.key.split("-")[2]) $_.key.split("-")[2]
            }
            $z = Read-Host "Pick a Package Number"
            $Package = $Packages.item([int]$z)
        }
        $PackageDirectory = $Path + "\" + $Package
        $PackageZip = $Package + ".zip"
        $PackageZipDirectory = $Path + "\" + $PackageZip
        $Report = $ClientName + "-" + $ScriptName + "-" + $Ticks
        $ReportDirectory = $Path + "\" + $Report
        $ReportZip = $ReportDirectory + ".zip"
        Read-S3Object -BucketName $AWSBucket -Key $Package -File $PackageZip -AccessKey $AccessKey -SecretKey $SecretKey
        Add-Type -assembly "system.io.compression.filesystem"
        $Extract = [io.compression.zipfile]::ExtractToDirectory($PackageZipDirectory,$PackageDirectory)
    }else{
        Write-Host "OFFLINE MODE" -ForegroundColor Magenta
        #offline testing
        $PackageDirectory = $Path + "\" + $Package
        $PackageZip = $Package + ".zip"
        $PackageZipDirectory = $Path + "\" + $PackageZip
        $Script:ClientName = ($Package.split("-")[0])
        $Report = $ClientName + "-" + $ScriptName + "-" + $Ticks
        $ReportDirectory = $Path + "\" + $Report
        $ReportZip = $ReportDirectory + ".zip"
    }
}
Export-ModuleMember -Function Get-Package

#endregion
