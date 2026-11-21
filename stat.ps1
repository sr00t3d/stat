<#
.SYNOPSIS
    stat.ps1 — Network Connection Monitor & TCP State Auditor (PowerShell)

.DESCRIPTION
    Lightweight real-time TCP network connection monitor for Windows Server/Desktop
    (native Get-NetTCPConnection) and PowerShell 7+ cross-platform (.NET
    IPGlobalProperties fallback). Displays TCP state distribution, top remote
    talkers, port/state filters, watch mode, and table/json/csv outputs.

    Author  : Percio Castelo <percio@perciocastelo.com.br>
    Website : https://perciocastelo.com.br
    Project : https://perciocastelo.com.br/projetos/en/network-connection-monitor.html
    Repo    : https://github.com/sr00t3d/stat
    License : Apache-2.0
    Version : 2.1.0

.EXAMPLE
    .\stat.ps1
    .\stat.ps1 -Top 15 -Port 443
    .\stat.ps1 -State Established -Output json
    .\stat.ps1 -Interval 3
#>

[CmdletBinding()]
param(
    [Alias('n')]
    [int]$Top = 10,

    [Alias('i')]
    [int]$Interval = 0,

    [Alias('p')]
    [int]$Port = 0,

    [Alias('s')]
    [string]$State = '',

    [switch]$TalkersOnly,

    [Alias('o')]
    [ValidateSet('table', 'json', 'csv')]
    [string]$Output = 'table',

    [Alias('q')]
    [switch]$Quiet,

    [switch]$NoColor,

    [Alias('V')]
    [switch]$Version,

    [Alias('h')]
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptName = 'stat.ps1'
$ScriptVersion = '2.1.0'
$HasNetTcp = [bool](Get-Command -Name Get-NetTCPConnection -ErrorAction SilentlyContinue)

function Show-Help {
@"
$ScriptName v$ScriptVersion — Network Connection Monitor (PowerShell)

Usage:
  .\stat.ps1 [options]

Options:
  -Top, -n <num>             Number of top remote talkers to display (default: 10)
  -Interval, -i <sec>        Refresh interval in seconds (watch mode; 0 = single snapshot)
  -Port, -p <num>            Filter by local or remote TCP port
  -State, -s <state>         Filter by TCP state (e.g. Established, Listen, TimeWait)
  -TalkersOnly               Show only the top remote IP talkers section
  -Output, -o <fmt>          Output format: table (default), json, csv
  -Quiet, -q                 Suppress banner header
  -NoColor                   Disable colored output
  -Version, -V               Show version and exit
  -Help, -h                  Show this help and exit
"@ | Write-Output
}

function Write-ColorLine {
    param([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::Gray)
    if ($NoColor -or $env:NO_COLOR -or $Output -ne 'table') { Write-Output $Text }
    else { Write-Host $Text -ForegroundColor $Color }
}

function Get-TcpSnapshot {
    $rows = New-Object System.Collections.Generic.List[object]
    if ($HasNetTcp) {
        foreach ($c in (Get-NetTCPConnection -ErrorAction SilentlyContinue)) {
            $rows.Add([PSCustomObject]@{
                local_ip    = [string]$c.LocalAddress
                local_port  = [int]$c.LocalPort
                remote_ip   = [string]$c.RemoteAddress
                remote_port = [int]$c.RemotePort
                state       = [string]$c.State
            })
        }
    } else {
        $props = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
        foreach ($c in ($props.GetActiveTcpConnections())) {
            $rows.Add([PSCustomObject]@{
                local_ip    = $c.LocalEndPoint.Address.ToString()
                local_port  = [int]$c.LocalEndPoint.Port
                remote_ip   = $c.RemoteEndPoint.Address.ToString()
                remote_port = [int]$c.RemoteEndPoint.Port
                state       = [string]$c.State
            })
        }
        foreach ($l in ($props.GetActiveTcpListeners())) {
            $rows.Add([PSCustomObject]@{
                local_ip    = $l.Address.ToString()
                local_port  = [int]$l.Port
                remote_ip   = '0.0.0.0'
                remote_port = 0
                state       = 'Listen'
            })
        }
    }

    if ($Port -gt 0) {
        $rows = [System.Collections.Generic.List[object]]@($rows | Where-Object { $_.local_port -eq $Port -or $_.remote_port -eq $Port })
    }
    if ($State) {
        $rows = [System.Collections.Generic.List[object]]@($rows | Where-Object { $_.state -ieq $State })
    }
    return $rows
}

function Invoke-RenderSnapshot {
    $ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $conns = @(Get-TcpSnapshot)
    $stateGroups = @($conns | Group-Object -Property state | Sort-Object -Property Count -Descending | ForEach-Object {
        [PSCustomObject]@{ state = $_.Name; count = $_.Count }
    })
    $talkers = @($conns | Where-Object { $_.remote_ip -notin @('0.0.0.0', '::', '127.0.0.1', '::1', '') } |
        Group-Object -Property remote_ip | Sort-Object -Property Count -Descending | Select-Object -First $Top | ForEach-Object {
            [PSCustomObject]@{ remote_ip = $_.Name; connections = $_.Count }
        })

    switch ($Output) {
        'json' {
            [PSCustomObject]@{
                tool              = $ScriptName
                version           = $ScriptVersion
                timestamp         = $ts
                total_connections = $conns.Count
                states            = $stateGroups
                top_talkers       = $talkers
            } | ConvertTo-Json -Depth 5 | Write-Output
        }
        'csv' {
            Write-Output 'section,key,count'
            foreach ($s in $stateGroups) { Write-Output "`"state`",`"$($s.state)`",$($s.count)" }
            foreach ($t in $talkers)     { Write-Output "`"talker`",`"$($t.remote_ip)`",$($t.connections)" }
        }
        default {
            if (-not $Quiet) {
                Write-ColorLine ('=' * 74) ([ConsoleColor]::Cyan)
                Write-Output (" {0} v{1} | TCP Network Connection Monitor | {2}" -f $ScriptName, $ScriptVersion, $ts)
                Write-ColorLine ('=' * 74) ([ConsoleColor]::Cyan)
                Write-Output (" Total TCP connections: {0}" -f $conns.Count)
                Write-Output ''
            }
            if (-not $TalkersOnly) {
                Write-ColorLine '[TCP STATE DISTRIBUTION]' ([ConsoleColor]::Cyan)
                if ($stateGroups.Count -eq 0) {
                    Write-Output '  (no matching connections)'
                } else {
                    foreach ($s in $stateGroups) {
                        Write-Output ("  {0,-18} : {1,6}" -f $s.state, $s.count)
                    }
                }
                Write-Output ''
            }
            Write-ColorLine ("[TOP {0} REMOTE TALKERS]" -f $Top) ([ConsoleColor]::Cyan)
            if ($talkers.Count -eq 0) {
                Write-Output '  (no remote peers)'
            } else {
                foreach ($t in $talkers) {
                    Write-Output ("  {0,-38} : {1,6}" -f $t.remote_ip, $t.connections)
                }
            }
        }
    }
}

if ($Help) { Show-Help; exit 0 }
if ($Version) { Write-Output "$ScriptName $ScriptVersion"; exit 0 }

if ($Interval -gt 0 -and $Output -eq 'table') {
    while ($true) {
        Clear-Host
        Invoke-RenderSnapshot
        Start-Sleep -Seconds $Interval
    }
} else {
    Invoke-RenderSnapshot
}
exit 0
