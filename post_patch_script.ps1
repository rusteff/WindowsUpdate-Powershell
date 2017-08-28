$logfile = "c:\dcsto\scripts\WindowsUpdate.log"

function Get-TimeStamp {
    
    return "{0:yyyy-MM-dd} {0:HH:mm:ss}" -f (Get-Date)   

}

### Start of post patch script
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;
. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
Connect-ExchangeServer -auto

$dag = Get-DatabaseAvailabilityGroup
$StopDagServerMaintenance = join-path -path $exscripts -ChildPath StopDagServerMaintenance.ps1
$RedistributeActiveDatabases = join-path -path $exscripts -ChildPath RedistributeActiveDatabases.ps1

invoke-expression -command "$StopDagServerMaintenance -servername $env:computername"

invoke-expression -command "$RedistributeActiveDatabases -dagname $dag.Name -BalanceDbsByActivationPreference -Confirm:$False"
### End of post patch script

schtasks /delete /tn "Post patch script" /F

if ($LASTEXITCODE -eq 0) {Write-Output "$(Get-TimeStamp) INFO Post patch script successful, deleting task" | Out-file -FilePath $logfile -Append}

Else {Write-Output "$(Get-TimeStamp) WARNING Post patch script failed with exitcode ${$LASTEXITCODE}, deleting task" | Out-file -FilePath $logfile -Append}