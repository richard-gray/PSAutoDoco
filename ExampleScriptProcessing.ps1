Param(
    [string]$Package=(Read-Host "Enter Package Name"),
    [string]$Offline=$false,
    [string]$AccessKey="",
    [string]$SecretKey="",
    [string]$AWSBucket=""
)
#Import PSDA.Gathering module
Import-Module .\PSDA.Processing.psm1

#ScriptName is used to define the product and binds this script to the data-processing script (alpha numeric only, no spaces), eg, VMwareVCenter, EMCUnity, MSExchange, CiscoUCS
$ScriptName = "ExampleScriptProcessing"
$PreviousScript = "ExampleScriptGathering"


Get-Package -Package $Package -Offline $Offline -PreviousScript $PreviousScript -ScriptName $ScriptName -AccessKey $AccessKey -SecretKey $SecretKey -AWSBucket $AWSBucket
New-Report -ScriptName $ScriptName -ClientName $ClientName
$PackageDirectory = (Get-Location).Path + "\$Package\"

#Run commandlets and pipe them to Add-<content type> for use in the Data-Presentation script
"Documentation Demo 1" | Add-Title -Level 1
"Overview 2" | Add-Title -Level 2
"Tims Asbuilt 3" | Add-Title -Level 3
"Heading 1" | Add-Title -Level 1
"Heading 2" | Add-Title -Level 2
"Secondy Heading 2" | Add-Title -Level 2
"Heading 3" | Add-Title -Level 3
"Secondy Heading 3" | Add-Title -Level 3
"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer nec odio. Praesent libero. Sed cursus ante 
dapibus diam. Sed nisi. Nulla quis sem at nibh elementum imperdiet. Duis sagittis ipsum. Praesent mauris. Fusce
nec tellus sed augue semper porta. Mauris massa. Vestibulum lacinia arcu eget nulla. Class aptent taciti sociosqu
ad litora torquent per conubia nostra, per inceptos himenaeos.
 " | Add-Paragraph -Title "Paragraph Demo"-Level 2

#Using a normal Table
Import-Clixml -Path ($PackageDirectory + "get-process") | Select ProcessName, Handles, PM`(K`), CPU`(s`), Id -first 5| Add-Table -Title "Processes Listing" -Caption "Processes Listing Example" -Level 2 -Description "This is a table showing a list of the running processes"
Import-Clixml -Path ($PackageDirectory + "get-childitem") | Select Name, Mode -first 5 | Add-Table -Title "Directory Listing" -Caption "Directory Listing Example" -Level 2 -Description "This is a table showing the files in a directory"
#Using a Vertical Table
$windows = Import-Clixml -Path ($PackageDirectory + "windows-info")
$windowsvtable = @{}
$windowsvtable.Add("Operating System Version",$windows.Version)
$windowsvtable.Add("Build Number",$windows.BuildNumber)
$windowsvtable.Add("Serial Number",$windows.SerialNumber)
$windowsvtable | Add-VerticalTable -Title "Windows Information" -Level 1 -Caption "Windows Information" -Description "The following table details the operating systems information"

$drives = Import-Clixml -Path ($PackageDirectory + "drive-info")
$drives | % {
    $drivesvtable = @{}
    $drivesvtable.Add("Drive",$_.DeviceId)
    $drivesvtable.Add("Free Space (GB)",([int64]$_.FreeSpace/1GB))
    $drivesvtable.Add("Drive Size (MB)",([int64]$_.Size/1GB))
    $drivesvtable | Add-VerticalTable -Title ($_.DeviceId + " Drive Information") -Level 2 -Caption ($_.DeviceId + " Information") -Description ("The following table details the " + $_.DeviceId + " drive  information")
}

"Code" | Add-Title -Level 2
 '<html>
    <head>
        <title>Demo Title</title>
    </head>
	<body>
		<h1>Heading 1</h1>
		<p>This is a Paragraph</p>
	</body>
</html>' | Add-Code -Title "HTML" -Level 3 -Caption "HTML Example" -Description "The following code is a snippit of HTML." -Language "HTML"

'{"menu": {
  "id": "file",
  "value": "File",
  "popup": {
    "menuitem": [
      {"value": "New", "onclick": "CreateNewDoc()"},
      {"value": "Open", "onclick": "OpenDoc()"},
      {"value": "Close", "onclick": "CloseDoc()"}
    ]
  }
}}
'| Add-Code -Title "Json" -Level 3 -Caption "Json Example" -Description "The following code is a snippit of Json code "

$states = @{"Victoria" = "Melbourne"; "New South Wales" = "Sydney"; "Western Australia" = "Perth"}
$states.Add("South Australia", "Adelaide")
$states | Add-VerticalTable -Title "States and Capital Cities" -Level 2 -Caption "Capitals" -Description "The following table maps States and their Capitals"


#Run the Submit-Report fuction once at the end of the script body to upload to S3 (and in future trigger cloud processing)
$ReportName = Submit-Report -AccessKey $AccessKey -SecretKey $SecretKey -AWSBucket $AWSBucket -Offline $Offline -RemoveDirectory $false