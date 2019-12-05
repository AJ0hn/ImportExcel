﻿#region import everything we need
$culture= $host.CurrentCulture.Name -replace '-\w*$',''
Import-LocalizedData  -UICulture $culture -BindingVariable Strings -FileName Strings -ErrorAction Ignore
if (-not $Strings) {
    Import-LocalizedData  -UICulture "en" -BindingVariable Strings -FileName Strings -ErrorAction Ignore
}
try   {[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")}
catch {Write-Warning -Message $Strings.SystemDrawingAvaialable}

foreach ($directory in @('Public','Charting','InferData','Pivot')) {
    Get-ChildItem -Path "$PSScriptRoot\$directory\*.ps1" | ForEach-Object {. $_.FullName}
}

. $PSScriptRoot\ArgumentCompletion.ps1

if ($PSVersionTable.PSVersion.Major -ge 5) {
    . $PSScriptRoot\Plot.ps1

    function New-Plot {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingfunctions', '', Justification = 'New-Plot does not change system state')]
        param()

        [PSPlot]::new()
    }

}
else {
    Write-Warning $Strings.PS5NeededForPlot
    Write-Warning $Strings.ModuleReadyExceptPlot
}

#endregion

if (($IsLinux -or $IsMacOS) -or $env:NoAutoSize) {
    $ExcelPackage = [OfficeOpenXml.ExcelPackage]::new()
    $Cells = ($ExcelPackage | Add-Worksheet).Cells['A1']
    $Cells.Value = 'Test'
    try {
        $Cells.AutoFitColumns()
        if ($env:NoAutoSize) { Remove-Item Env:\NoAutoSize }
    }
    catch {
        $env:NoAutoSize = $true
        if ($IsLinux) {
            Write-Warning -Message ('ImportExcel Module Cannot Autosize. Please run the following command to install dependencies:' + [environment]::newline +
                '"sudo apt-get install -y --no-install-recommends libgdiplus libc6-dev"')
        }
        if ($IsMacOS) {
            Write-Warning -Message ('ImportExcel Module Cannot Autosize. Please run the following command to install dependencies:' + [environment]::newline +
                '"brew install mono-libgdiplus"')
        }
    }
    finally {
        $ExcelPackage | Close-ExcelPackage -NoSave
    }
}
