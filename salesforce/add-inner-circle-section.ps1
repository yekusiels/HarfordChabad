# Adds an "Inner Circle" section to every Contact page layout in the org.
# Retrieves the current layouts, inserts the section after the first existing
# section, and deploys them back. Dry run by default; pass -Deploy to save.
#
#   powershell -ExecutionPolicy Bypass -File add-inner-circle-section.ps1
#   powershell -ExecutionPolicy Bypass -File add-inner-circle-section.ps1 -Deploy

param(
    [string]$Org = "harford",
    [switch]$Deploy
)

$ErrorActionPreference = "Stop"
$work = Join-Path $PWD "inner-circle-layouts"

$section = @"
    <layoutSections>
        <customLabel>true</customLabel>
        <detailHeading>true</detailHeading>
        <editHeading>true</editHeading>
        <label>Inner Circle</label>
        <layoutColumns>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>Inner_Circle_Tier__c</field>
            </layoutItems>
            <layoutItems>
                <behavior>Readonly</behavior>
                <field>Suggested_Tier__c</field>
            </layoutItems>
            <layoutItems>
                <behavior>Readonly</behavior>
                <field>Touch_Overdue__c</field>
            </layoutItems>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>Next_Step__c</field>
            </layoutItems>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>Next_Step_Date__c</field>
            </layoutItems>
        </layoutColumns>
        <layoutColumns>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>Estimated_Net_Worth__c</field>
            </layoutItems>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>Largest_Known_Outside_Gift__c</field>
            </layoutItems>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>Mission_Alignment__c</field>
            </layoutItems>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>Relationship_Depth__c</field>
            </layoutItems>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>Alignment_Notes__c</field>
            </layoutItems>
        </layoutColumns>
        <style>TwoColumnsTopToBottom</style>
    </layoutSections>
"@

Write-Host "Finding Contact page layouts..."
$all = (sf org list metadata --metadata-type Layout --target-org $Org --json | ConvertFrom-Json).result
$names = @($all | Where-Object { $_.fullName -like "Contact-*" } | ForEach-Object { $_.fullName })
if ($names.Count -eq 0) { throw "No Contact layouts found." }
$names | ForEach-Object { Write-Host "  $_" }

Write-Host "Retrieving layouts..."
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
$metadataArgs = @()
foreach ($n in $names) { $metadataArgs += "--metadata"; $metadataArgs += "Layout:$n" }
sf project retrieve start @metadataArgs --target-metadata-dir $work --unzip --target-org $Org | Out-Host

$pkg = Get-ChildItem $work -Recurse -Filter package.xml | Select-Object -First 1
if (-not $pkg) { throw "Retrieve failed: no package.xml under $work" }
$root = $pkg.DirectoryName

$utf8 = New-Object System.Text.UTF8Encoding $false
$changed = 0
foreach ($file in Get-ChildItem $root -Recurse -Filter *.layout) {
    $xml = [IO.File]::ReadAllText($file.FullName)
    if ($xml -match "Inner_Circle_Tier__c") {
        Write-Host "  skip (already has the fields): $($file.Name)"
        continue
    }
    $marker = "</layoutSections>"
    $i = $xml.IndexOf($marker)
    if ($i -lt 0) { Write-Host "  skip (no sections): $($file.Name)"; continue }
    $i += $marker.Length
    $xml = $xml.Insert($i, "`n" + $section.TrimEnd())
    [IO.File]::WriteAllText($file.FullName, $xml, $utf8)
    Write-Host "  added section: $($file.Name)"
    $changed++
}
if ($changed -eq 0) { Write-Host "Nothing to deploy."; exit 0 }

$deployArgs = @("project", "deploy", "start", "--metadata-dir", $root, "--single-package", "--target-org", $Org)
if (-not $Deploy) { $deployArgs += "--dry-run"; Write-Host "Dry run (nothing will be saved)..." }
else { Write-Host "Deploying..." }
sf @deployArgs | Out-Host
