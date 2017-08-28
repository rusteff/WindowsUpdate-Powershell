<#
.SYNOPSIS
  Schedule downtime in nagios and installs updates
.DESCRIPTION

.PARAMETER Verbose
Provides Verbose output which is useful for troubleshooting
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        2.0
  Author:         Rudi Steffensen
  Creation Date:  2015-08-06
  Purpose/Change: Initial script development
#>

$logfile = "c:\dcsto\scripts\WindowsUpdate.log"
$prepatchscript="c:\dcsto\scripts\pre_patch_script.ps1"
$Output = New-object PSObject -Property @{
    StopWatch = [Diagnostics.Stopwatch]::StartNew()
    Duration = ''
    Exitcode = 3
    ReturnString = 'UNKNOWN Please debug the script...'
}

function Get-TimeStamp {
    
    return "{0:yyyy-MM-dd} {0:HH:mm:ss}" -f (Get-Date)    

}

Try {
    Import-Module PSWindowsUpdate
} 
catch {
    $Output.ReturnString = 'UNKNOWN: Unable to import module PSWindowsUpdate'
    $Output.Exitcode = 3
    Write-Output "$Output.Returnstring"
    Exit $Output.ExitCode
}

Write-Output "$(Get-TimeStamp) INFO Scans for new updates" | Out-file -FilePath $logfile -Append
$availableupdates = Get-WUInstall -AcceptAll -ListOnly -WarningVariable wv
$availableupdates | Out-file -FilePath $logfile -Append

if ($wv) {
    $Output.Returnstring = "WARNING $($wv)"
    $output.ExitCode = 1
}

Else{
    # Sleep between 0 and 600 seconds (10 min) to prevent everyone from firing up at the same time
    Start-Sleep -s (Get-Random -Minimum 0 -Maximum 600)

    Try{
        $wc = New-Object system.Net.WebClient;
        $request = $wc.downloadString("http://80.72.15.140:88/downtime.php?user=Puppet&comment=Scheduled host downtime for patching&patch=1")
       
        }

    Catch{
        $_.Exception.Response.StatusCode.Value__
        Write-Output "$(Get-TimeStamp) WARNING Nagios is not reachable, Windows Update failed" | Out-file -FilePath $logfile -Append
        Exit 1
    }
    
    Try{
        If ($request -like '*OK - Scheduled*') {
                Write-Output "$(Get-TimeStamp) INFO Site is OK! Schedule downtime succeeded" | Out-file -FilePath $logfile -Append
        
                If (Test-Path $prepatchscript){
                    Write-Output "$(Get-TimeStamp) INFO Executing pre patch script" | Out-file -FilePath $logfile -Append
                    powershell.exe $prepatchscript
                }Else{
                    Write-Output "$(Get-TimeStamp) INFO Pre patch script does not exist, continuing" | Out-file -FilePath $logfile -Append
                }
                
                  Write-Output "$(Get-TimeStamp) INFO Starting Windows Update" | Out-file -FilePath $logfile -Append
                  $InstallUpdates = Get-WUInstall -AcceptAll -IgnoreReboot
                  $InstallUpdates | Out-file -FilePath $logfile -Append
                  shutdown.exe -t 120 -f -r
                  $Output.returnstring = "INFO Windows Update finished, server will be restarted in 2 minutes"
                  $output.Exitcode = 0
        }
        Else{
            $Output.returnstring = "WARNING Schedule downtime failed, aborting"
            $output.ExitCode = 1
        }
    }
    Catch{
        $_
        $Output.returnstring = "UNKNOWN Please debug the script..."
        $output.ExitCode = 3
    }
} 

if (!$availableupdates) {
    $Output.Returnstring = "INFO Windows Update finished no updates available, server will be restarted in 2 minutes"
    $output.ExitCode = 10
}

$updateresult = $InstallUpdates | Where-Object {$_.Status -eq 'Failed'}

if ($updateresult.Status -eq "Failed") {
    $Output.returnstring = "WARNING Windows Update finished with failures, server will be restarted in 2 minutes"
    $output.Exitcode = 0
    }

$Output.Duration = $Output.StopWatch.Elapsed.TotalMinutes
$Output.ReturnString += " Duration:$($Output.Duration)M"

if ($Output.returnstring) {
Write-Output "$(Get-TimeStamp) $($Output.returnstring)" | Out-File -FilePath $logfile -Append
}

Exit $output.exitcode