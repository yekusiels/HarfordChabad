# Moves donations on Household Accounts to the household's primary contact.
#
# For every Opportunity on a Household Account whose Primary Contact is not the
# account's Primary Contact (npe01__One2OneContact__c), sets the Opportunity's
# npsp__Primary_Contact__c to the account's Primary Contact. NPSP then moves the
# primary (hard credit) contact role to that contact.
#
# Preview (default): writes a preview CSV and a backup CSV, changes nothing.
#   powershell -ExecutionPolicy Bypass -File move-gifts-to-household-primary.ps1
# Only accounts named in a text file (one account name per line):
#   powershell -ExecutionPolicy Bypass -File move-gifts-to-household-primary.ps1 -AccountListFile accounts.txt
# Apply to the first 5 only (to test), then to all:
#   powershell -ExecutionPolicy Bypass -File move-gifts-to-household-primary.ps1 -Apply -Limit 5
#   powershell -ExecutionPolicy Bypass -File move-gifts-to-household-primary.ps1 -Apply
# Undo, using the backup written by the preview:
#   sf data update bulk --sobject Opportunity --file gift-move\backup-<timestamp>.csv --wait 30 --target-org harford

param(
    [string]$Org = "harford",
    [string]$AccountListFile,
    [int]$Limit = 0,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$utf8 = New-Object System.Text.UTF8Encoding $false
$dir = Join-Path $PWD "gift-move"
New-Item -ItemType Directory -Force $dir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

$query = "SELECT Id, Name, Amount, CloseDate, StageName, Account.Name, " +
         "npsp__Primary_Contact__c, npsp__Primary_Contact__r.Name, " +
         "Account.npe01__One2OneContact__c, Account.npe01__One2OneContact__r.Name " +
         "FROM Opportunity " +
         "WHERE Account.npe01__SYSTEM_AccountType__c = 'Household Account' " +
         "AND Account.npe01__One2OneContact__c != null"

Write-Host "Exporting donations on household accounts..."
$export = Join-Path $dir "export-$stamp.csv"
sf data export bulk --query $query --output-file $export --result-format csv --wait 15 --target-org $Org | Out-Host
$rows = Import-Csv $export

$names = $null
if ($AccountListFile) {
    $names = @(Get-Content $AccountListFile | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    Write-Host "Limiting to $($names.Count) account names from $AccountListFile"
}

$moves = @($rows | Where-Object {
    $_.'npsp__Primary_Contact__c' -ne $_.'Account.npe01__One2OneContact__c' -and
    (-not $names -or $names -contains $_.'Account.Name')
})
if ($Limit -gt 0) { $moves = @($moves | Select-Object -First $Limit) }

Write-Host "$($rows.Count) donations on household accounts; $($moves.Count) to move."
if ($moves.Count -eq 0) { exit 0 }

$preview = Join-Path $dir "preview-$stamp.csv"
$moves | Select-Object `
    @{n = "Opportunity Id"; e = { $_.Id } },
    @{n = "Opportunity"; e = { $_.Name } },
    @{n = "Amount"; e = { $_.Amount } },
    @{n = "Close Date"; e = { $_.CloseDate } },
    @{n = "Stage"; e = { $_.StageName } },
    @{n = "Account"; e = { $_.'Account.Name' } },
    @{n = "Current Contact"; e = { $_.'npsp__Primary_Contact__r.Name' } },
    @{n = "New Contact"; e = { $_.'Account.npe01__One2OneContact__r.Name' } } |
    Export-Csv $preview -NoTypeInformation -Encoding UTF8

# Backup holds the current values so the change can be reversed.
$backup = Join-Path $dir "backup-$stamp.csv"
# "#N/A" tells the Bulk API to blank the field when there was no contact before.
$lines = @("Id,npsp__Primary_Contact__c") + ($moves | ForEach-Object {
    $old = $_.'npsp__Primary_Contact__c'; if (-not $old) { $old = "#N/A" }
    "$($_.Id),$old" })
[IO.File]::WriteAllText($backup, ($lines -join "`n") + "`n", $utf8)

Write-Host "Preview: $preview"
Write-Host "Backup:  $backup"

if (-not $Apply) {
    Write-Host "Preview only. Nothing was changed. Review the preview, then re-run with -Apply."
    exit 0
}

$update = Join-Path $dir "update-$stamp.csv"
$lines = @("Id,npsp__Primary_Contact__c") + ($moves | ForEach-Object { "$($_.Id),$($_.'Account.npe01__One2OneContact__c')" })
[IO.File]::WriteAllText($update, ($lines -join "`n") + "`n", $utf8)

Write-Host "Updating $($moves.Count) donations..."
sf data update bulk --sobject Opportunity --file $update --wait 30 --target-org $Org | Out-Host
Write-Host "Done. To undo: sf data update bulk --sobject Opportunity --file `"$backup`" --wait 30 --target-org $Org"
