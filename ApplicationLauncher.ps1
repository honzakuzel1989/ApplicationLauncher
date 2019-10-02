[CmdletBinding()]
Param(
  [Parameter(HelpMessage="The application name.", Mandatory=$true)]
  [string]$AppName,
  
  [Parameter(HelpMessage="The application name.", Mandatory=$true)]
  [string]$AppPath,
  
  [Parameter(HelpMessage="The connection address.", Mandatory=$true)]
  [string]$ConnectionAddress,
  
  [Parameter(HelpMessage="The maximal connection test count before error is occured. Between each test is one second pause.")]
  [int]$ConnectionTestCount=30,
  
  [Parameter(HelpMessage="The timeout while is application run again after has been ended.")]
  [int]$RerunTimeout=0
)

New-Alias error Write-Error
New-Alias progress Write-Progress

# Promenne pro ping
$cnt = $ConnectionTestCount
$mcm = $ConnectionAddress
$msg = "Waiting for connection to $mcm."
$ping = test-connection -comp $mcm -count 1 -quiet -ea silentlycontinue

# Pokus o ping
for ($i=0; ($i -lt $cnt) -and !($ping); $i++) 
{
    progress $msg -PercentComplete (($i + 1) * 100 / $cnt)
    $ping = test-connection -comp $mcm -count 1 -quiet -ea silentlycontinue
    sleep 1
}

progress "Connected" -Completed

#Ok
if($ping) {
    # Promenne pro MCM
    $appname = $AppName
    $apppath = $AppPath
    $run = $true 
    $runtm = $RerunTimeout
    $runmsg = "The program $appname has been terminated and will be run again."
    
    # MCM jede v nekonecne smycce, pokud nedojde k zavreni (ctrl + c) okna
    while($run) 
    {
        # Completed na potencialni minuly progress a pusteni app
        Start-Process ("$apppath\$appname") -NoNewWindow -Wait
        progress "Run again" -Completed
        
        # Pri spusteni muze cekat pozadovanou dobu, nez spusti znovu, nebo preskoci
        for($i=0; $i -lt $runtm; $i++) 
        {
            progress $runmsg -SecondsRemaining ($runtm - $i)
            sleep 1
        }

        progress $runmsg
    }
}
# Error
else 
{
    [Console]::ForegroundColor = "red"
    [Console]::Error.WriteLine("Cannot reach the connection to $mcm!")
    [Console]::ResetColor()
    
    # End
    echo "Press any key to exit...";
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}