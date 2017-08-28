$logfile = "c:\dcsto\scripts\WindowsUpdate.log"
$postpatchscript="c:\dcsto\scripts\post_patch_script.ps1"

function Get-TimeStamp {
    
    return "{0:yyyy-MM-dd} {0:HH:mm:ss}" -f (Get-Date)  

}

If (Test-Path $postpatchscript){
    Write-Output "$(Get-TimeStamp) INFO Creating task for post patch script" | Out-file -FilePath $logfile -Append
    schtasks /create /tn "Post patch script" /sc onstart /delay 0000:30 /rl highest /ru system /tr "c:\windows\system32\WindowsPowershell\v1.0\powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File $postpatchscript" /F
}

### Start of pre patch script
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;
. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
Connect-ExchangeServer -auto

$StartDagServerMaintenance = join-path -path $exscripts -ChildPath StartDagServerMaintenance.ps1

invoke-expression -command "$StartDagServerMaintenance -servername $env:computername"
### End of pre patch script

if ($LASTEXITCODE -eq 0) {Write-Output "$(Get-TimeStamp) INFO Pre patch script successful" | Out-file -FilePath $logfile -Append}

Else {Write-Output "$(Get-TimeStamp) WARNING Pre patch script failed with exitcode ${$LASTEXITCODE}" | Out-file -FilePath $logfile -Append}