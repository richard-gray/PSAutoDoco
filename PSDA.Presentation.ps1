#Requires -Version 3.0
#Requires -Modules AWSPowerShell

#region Script Help

<#
.SYNOPSIS  
    Data Presentation Example Script
.DESCRIPTION
    Data Presentation Example Script
.NOTES
    Version:        1.0
    Author:         Richard Gray
.LINK
    NA
.EXAMPLE
    .\Data-Presentation.ps1
    Runs the data Presentation script
#>

#endregion

#region script changelog

<#
.VERSION 1.0 - 7/05/2016
              
 - Initial script development
 - ToDo
    -Error Checking on Zip
    -Remoe Zip output
    -Add Info on script progress
    -Test AWS credentials at the start of script before processing
    -Better Handleing of files between scripts

-Future
    -automaticly open file
    -upload HTML to S3 for archive
    -add "Vertical Tables" with hash table
#>

#endregion

#region Script Parameters

#endregion

#region AWS Keys
$AccessKey = "AKIAJLHBXAPFEMLOGYQQ"
$SecrectKey = "CYKbGK0B9rcZapHoYWYMDWraiPVy5DJo2NizKWHM"

#endregion


$AWSBucket = "tddocumentation"
#$Report = Read-Host "Enter your Report Name"
$Report = "Richard-ExampleScriptProcessing-636003699946451955"
$Path = (Get-Location).Path 
$ReportDirectory = $Path + "\" + $Report
$ReportZip = $ReportDirectory + ".zip"

#Read-S3Object -BucketName $AWSBucket -Key $Report -File $ReportZip -AccessKey $AccessKey -SecretKey $SecrectKey
#Add-Type -assembly "system.io.compression.filesystem"
#[io.compression.zipfile]::ExtractToDirectory($ReportZip,$ReportDirectory)


$TableNumber = 0
$CodeSnippitNumber = 0
$ReportHead = ""
$ReportBody = ""
$script:ReportTableOfContents = ""
$script:CurrentLevel = 1
$script:PreviousLevel = 1
$script:ReportHead = "<html>
<head>
    <link rel='stylesheet' href='styles/default.css'>
    <script src='highlight.js'></script>
    <script>hljs.initHighlightingOnLoad();</script>
    <style type='text/css'>
         h1 {
            font-family: 'Calibri','sans-serif';
            color: #2E7599;
            font-size: 24.0pt;
            font-weight: normal;
            margin-top: 12.0pt;
            margin-right: 0in;
            margin-bottom: 12.0pt;
            margin-left: 28.9pt;
            text-indent: -28.9pt;
        }
        h2 {
            font-family: 'Calibri','sans-serif';
            color: #2E7599;
            font-size: 20.0pt;
            font-weight: normal;
            margin-top: 12.0pt;
            margin-right: 0in;
            margin-bottom: 12.0pt;
            margin-left: 28.9pt;
            text-indent: -28.9pt;
        }
        h3 {
            font-family: 'Calibri','sans-serif';
            color: #2E7599;
            font-size: 16.0pt;
            font-weight: normal;
            margin-top: 12.0pt;
            margin-right: 0in;
            margin-bottom: 12.0pt;
            margin-left: 28.9pt;
            text-indent: -28.9pt;
        }
        h4 {
            font-family: 'Calibri','sans-serif';
            color: #2E7599;
            font-size: 12.0pt;
            font-weight: normal;
            margin-top: 12.0pt;
            margin-right: 0in;
            margin-bottom: 12.0pt;
            margin-left: 35.45pt;
            text-indent: -35.45pt;
        }       
        h5 {
            font-family: 'Calibri','sans-serif';
            color: #2E7599;
            font-size: 11.0pt;
            font-weight: Bold;
            margin-top: 12.0pt;
            margin-right: 0in;
            margin-bottom: 12.0pt;
            margin-left: 35.45pt;
            text-indent: -35.45pt;
        }
        h6 {
            font-family: 'Calibri','sans-serif';
            color: #2E7599;
            font-size: 10.0pt;
            font-weight: Bold;
            margin-top: 12.0pt;
            margin-right: 0in;
            margin-bottom: 12.0pt;
            margin-left: 35.45pt;
            text-indent: -35.45pt;
        }
        p{
            font-family: 'Calibri','sans-serif';
            font-size: 10.0pt;
            margin-top: 3.0pt;
            margin-right: 0in;
            margin-bottom: 3.0pt;
            margin-left: 0in;
        }
        br{
            font-size: 10.0pt;
        }
        table {
            width: 481.95pt;
            border-collapse: collapse;
            border: none;
            font-family: 'Calibri','sans-serif';
            font-size: 10.0pt;
            text-align: left;
        }
        tr {
            height: 24px;
        }
        th {
            border: solid #969696 1px;
            background: #EFF7FA;
            padding: 0in 5.4pt 0in 5.4pt;
            vertical-align: center;
            padding: 0in 5.4pt 0in 5.4pt;
            text-align:left;
        }
        td {
            padding: 0in 5.4pt 0in 5.4pt;
            border: solid #969696 1px;
        }
        #clean{
            width: 100%;
            border-collapse: collapse;
            border: none;
            font-family: 'Calibri','sans-serif';
            font-size: 10.0pt;
            text-align: left;
            padding: 0px;
            height: 0px;
        }
        #clean td, #clean tr {
            border-collapse: collapse;
            border: none;
            height: 0px;
        }
        .odd {
            background: #F7F7F7;
        }
        .even {

        }
        .caption {
            font-size: 10.0pt;
            font-family: 'Calibri','sans-serif';
            margin-left: 10pt;
            font-style:italic;    
        }
        .btw {
            font-style:italic;
            margin-left: 10pt;
        }
        .col{
            -webkit-column-count: 3; /* Chrome, Safari, Opera */
            -moz-column-count: 3; /* Firefox */
            column-count: 3;
        }
        /*

        Railscasts-like style (c) Visoft, Inc. (Damien White)

        */

        .hljs {
          display: block;
          overflow-x: auto;
          padding: 0.5em;
          background: #232323;
          color: #e6e1dc;
        }

        .hljs-comment,
        .hljs-quote {
          color: #bc9458;
          font-style: italic;
        }

        .hljs-keyword,
        .hljs-selector-tag {
          color: #c26230;
        }

        .hljs-string,
        .hljs-number,
        .hljs-regexp,
        .hljs-variable,
        .hljs-template-variable {
          color: #a5c261;
        }

        .hljs-subst {
          color: #519f50;
        }

        .hljs-tag,
        .hljs-name {
          color: #e8bf6a;
        }

        .hljs-type {
          color: #da4939;
        }


        .hljs-symbol,
        .hljs-bullet,
        .hljs-built_in,
        .hljs-builtin-name,
        .hljs-attr,
        .hljs-link {
          color: #6d9cbe;
        }

        .hljs-params {
          color: #d0d0ff;
        }

        .hljs-attribute {
          color: #cda869;
        }

        .hljs-meta {
          color: #9b859d;
        }

        .hljs-title,
        .hljs-section {
          color: #ffc66d;
        }

        .hljs-addition {
          background-color: #144212;
          color: #e6e1dc;
          display: inline-block;
          width: 100%;
        }

        .hljs-deletion {
          background-color: #600;
          color: #e6e1dc;
          display: inline-block;
          width: 100%;
        }

        .hljs-selector-class {
          color: #9b703f;
        }

        .hljs-selector-id {
          color: #8b98ab;
        }

        .hljs-emphasis {
          font-style: italic;
        }

        .hljs-strong {
          font-weight: bold;
        }

        .hljs-link {
          text-decoration: underline;
        }
    
    </style>
</head>
<body>
"

$script:ReportTableOfContents += "
<h1>Table of Contents</h1>
<ul>"

function Add-TitleTableofContents(){
    Param(
        [string]$Title,
        [int]$Level,
        $Finish=$false
    )
    Write-host "AddTOC"
    if($Finish -eq $true){
        $Level = 1
        do{
            $script:ReportTableOfContents += "</ul></li>"
            $Level++
        }until($Level -eq $CurrentLevel)
        $script:ReportTableOfContents += "</ul><br>"
        Write-host "ExitLoop"
    }else{
        $TargetLevel = $Level
        Write-Host "Start" $script:PreviousLevel,$script:CurrentLevel, $TargetLevel 
        If($TargetLevel -eq $script:CurrentLevel){
           # if($script:PreviousLevel -gt $TargetLevel){
           #     $script:ReportTableOfContents += "<li>"
           # }
            $script:ReportTableOfContents += "<li><a href='#" + $Title + "'>" + $Title + "</a>"
        }
        If($TargetLevel -gt $script:CurrentLevel){
            do{
                $script:ReportTableOfContents += "<ul>"
                $TargetLevel--
            }until($TargetLevel -eq $script:CurrentLevel) 
            $script:ReportTableOfContents += "<li><a href='#" + $Title + "'>" + $Title + "</a></li>"
        }
        If($TargetLevel -lt $script:CurrentLevel){
            do{
                $script:ReportTableOfContents += "</ul></li>"
                $TargetLevel++
            }until($TargetLevel -eq $script:CurrentLevel)
            $script:ReportTableOfContents += "<li><a href='#" + $Title + "'>" + $Title + "</a>"
        }
        $script:PreviousLevel = $script:CurrentLevel
        $script:CurrentLevel = $TargetLevel
    }
}



Get-Content "$ReportDirectory\0.csv" | ConvertFrom-Csv | % {
    # Process Title
    If($_.Type -eq "Title"){
        $Title = get-content ($ReportDirectory + "\" + $_.File)
        $ReportBody += "<a name='" + $Title + "'></a>"
        $ReportBody += "<h" + $_.Level + ">" + $Title + "</h" + $_.Level + ">"
       # Add-TitleTableofContents -Title $Title -Level $_.Level
    }

    # Process Paragraph
    If($_.Type -eq "Paragraph"){
        $Paragraph = get-content ($ReportDirectory + "\" + $_.File)
        If($_.Title -ne ""){
            $ReportBody += "<a name='" + $_.Title + "'></a>"
            $ReportBody += "<h" + $_.Level + ">" + $_.Title + "</h" + $_.Level + ">"
           # Add-TitleTableofContents -Title $Title -Level $_.Level
        }
        $ReportBody += "<p>" + $Paragraph + "</p>"
    }

    # Process Table 
    If($_.Type -eq "Table"){
        #Print Title
        If($_.Title -ne ""){
            $ReportBody += "<a name='" + $_.Title + "'></a>"
            $ReportBody += "<h" + $_.Level + ">" + $_.Title + "</h" + $_.Level + ">"
           # Add-TitleTableofContents -Title $_.Title -Level $_.Level
        }        
        If($_.Description -ne ""){
            $ReportBody += "<p>" + $_.Description + "</p>"
        }        
        $Table = get-content ($ReportDirectory + "\" + $_.File)
        $TableNumber++
        $LineNumber = 0
        $ReportBody += "<table>"
        $Table | % {
            $LineNumber++
            $LineSplit = $_.Split(',')
            If($LineNumber -eq 1){
                $cell = "<th>","</th>"
            }else{
                If($LineNumber % 2 -eq 0){
                    $cell = "<td class='even'>","</td>"
                }else{
                    $cell = "<td class='odd'>","</td>"
                }
            }
            $ReportBody += "<tr>"
            $LineSplit | % {
                $ReportBody += $cell[0] + $_.Replace('"',"") + $cell[1] 
            }
            $ReportBody += "</tr>"
        }
        $ReportBody += "</table>"
        #Print Caption
        If($_.Caption -ne ""){
            $ReportBody  += "<div class='caption'>Table " + $TableNumber + " - " + $_.Caption + "</div>" 
        }           
    }
    
    # Process Vertical Table 
    If($_.Type -eq "VerticalTable"){
        #Print Title
        If($_.Title -ne ""){
            $ReportBody += "<a name='" + $_.Title + "'></a>"
            $ReportBody += "<h" + $_.Level + ">" + $_.Title + "</h" + $_.Level + ">"
            #Add-TitleTableofContents -Title $_.Title -Level $_.Level
        }  
        If($_.Description -ne ""){
            $ReportBody += "<p>" + $_.Description + "</p>"
        }  
        $Table = get-content ($ReportDirectory + "\" + $_.File)
        $TableNumber++
        $ReportBody += "<table>"
        $LineNumber = 0
        $Table | % {
            $LineNumber++
            if($LineNumber -ne 1){
                $LineSplit = $_.Split(',')
                $ReportBody += "<tr><th>" + $LineSplit[0].Replace('"',"") + "</th><td>" + $LineSplit[1].Replace('"',"") + "</td></tr>"
            }
        }
        $ReportBody += "</table>"
        #Print Caption
        If($_.Caption -ne ""){
            $ReportBody  += "<div class='caption'>Table " + $TableNumber + " - " + $_.Caption + "</div>" 
        }           
    }

    #Process Code
    If($_.Type -eq "Code"){
        #Print Title
        If($_.Title -ne ""){
            $ReportBody += "<a name='" + $_.Title + "'></a>"
            $ReportBody += "<h" + $_.Level + ">" + $_.Title + "</h" + $_.Level + ">"
            #Add-TitleTableofContents -Title $_.Title -Level $_.Level
        }
        If($_.Description -ne ""){
            $ReportBody += "<p>" + $_.Description + "</p>"
        }
        $Code = get-content ($ReportDirectory + "\" + $_.File)
        $CodeSnippitNumber++
        $ReportBody += "<pre><code>"
        $Code | % {
            $ReportBody += $_.Replace("<","&lt;").Replace(">","&gt;") + "`n"
        }
        $ReportBody += "</code></pre>"
        #Print Caption
        If($_.Caption -ne ""){
            $ReportBody += "<div class='caption'>Code Snippit " + $CodeSnippitNumber + " - " + $_.Caption + "</div>"
        }
    }
}
$ReportBody += "
</body>
</html>"

#Add-TitleTableofContents -Finish $true

#Remove Local Files
Write-Host "Removing Local Files..." -NoNewline
#Remove-Item $ReportDirectory -Force -Recurse
#Remove-Item $ReportZip
Write-Host "Done" -ForegroundColor Green

#Combine Sections and Save
Write-Host "Saving Report..." -NoNewline
$ReportHead + $ReportTableOfContents + $ReportBody | Out-File "$Report.html"
Write-Host "Done" -ForegroundColor Green
Write-Host "Report Name [ " -NoNewline
Write-Host "$Report.html" -NoNewline -ForegroundColor Green
Write-Host " ]"
Write-Host "Script complete"


