# Network Connection Monitor (Stat)

Readme: [Português](README-ptbr.md)

![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg) ![Shell Script](https://img.shields.io/badge/shell-script-green) ![Release](https://img.shields.io/badge/release-v2.0.0-blue)

<img width="700" src="stat-cover.webp" alt="Network Connection Monitor Cover" />

Lightweight and efficient Bash script to monitor active network connections in real time on Linux servers. Analyzes active TCP and UDP sockets, groups connections by local listening port, audits TCP state distributions (detecting SYN floods and socket leaks), and isolates top remote client IPs (Top Talkers).

## Features

- **Real-Time Traffic Aggregation**: Audits active TCP/UDP sockets grouped by destination port.
- **TCP State Telemetry**: Real-time breakdown of `ESTAB`, `SYN_RECV`, `TIME_WAIT`, `CLOSE_WAIT`, and `FIN_WAIT`.
- **Automated Anomaly Alerts**: Built-in thresholds trigger visual alerts for suspected SYN floods (`SYN_RECV > 20`) or socket exhaustion (`CLOSE_WAIT > 50`).
- **Target Port Inspection (`-p, --port`)**: Inspect a specific service (e.g. 80, 443, 22, 3306) to identify who is connecting.
- **Top Talkers Isolation (`--top-talkers`)**: Aggregate connection counts by remote client IP to isolate abusive traffic.
- **Continuous Watch Mode (`-w, --watch`)**: Interactive live console dashboard refreshing at customizable intervals.
- **Multi-Format Output (`-o table|json|csv`)**: Ready for interactive terminal debugging, CSV logging, or SIEM JSON pipelines.
- **Zero Heavy Dependencies**: Uses Linux native `ss` (from `iproute2`) with automatic fallback to `netstat`.

## Installation

### Direct Execution

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sr00t3d/stat/main/stat.sh)
```

### Clone or Download

```bash
git clone https://github.com/sr00t3d/stat.git
cd stat
chmod +x stat.sh
sudo ./stat.sh
```

## CLI Usage

```text
STAT(E) — NETWORK CONNECTION MONITOR v2.0.0
Lightweight real-time network traffic grouping, TCP state & socket monitor.

Usage: stat.sh [OPTIONS]

Options:
  -t, -n, --top NUM      Number of entries in top ranking (default: 10)
  -i, --interval SEC     Continuous refresh interval in seconds (e.g. 2)
  -w, --watch [SEC]      Enable live interactive watch mode (default: 2s)
  -p, --port PORT        Filter connections by local destination port (e.g. 80, 443, 22)
  -s, --state STATE      Filter connections by TCP state (e.g. ESTAB, TIME-WAIT, SYN-RECV)
  --top-talkers          Display top remote client IPs ranking only
  -o, --output FORMAT    Output format: table, json, csv (default: table)
  -q, --quiet            Quiet mode (omit decorative banners/headers)
  --no-color             Disable ANSI color escape sequences
  -V, --version          Display version and author
  -h, --help             Display this help message
```

## Direct Execution & Windows PowerShell

### Linux / macOS (Direct Execution)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sr00t3d/stat/main/stat.sh)
```

### Windows (PowerShell `stat.ps1`)
Zero external dependencies — works natively on **Windows PowerShell 5.1+** and **PowerShell 7+**:

```powershell
# Direct execution (no clone required)
irm https://raw.githubusercontent.com/sr00t3d/stat/main/stat.ps1 | iex

# Local execution
.\stat.ps1
.\stat.ps1 -Top 15 -Port 443
.\stat.ps1 -State Established -Output json
.\stat.ps1 -Interval 3
```

## Real Output Example

Captured live on AlmaLinux 8 production container (`cpanel-test`):

```text
╔══════════════════════════════════════════════════════════════════════════════╗
║ STAT(E) — NETWORK CONNECTION MONITOR v2.0.0                                ║
╚══════════════════════════════════════════════════════════════════════════════╝
Host: cpanel-test.local | Data/Hora: 2026-11-20 01:39:34 | Motor: ss | Total Ativo: 2

[+] TCP STATES SUMMARY:
  ESTAB: 2  |  SYN_RECV: 0  |  TIME_WAIT: 0  |  CLOSE_WAIT: 0  |  FIN_WAIT: 0  |  OUTROS: 0

[+] TOP 10 PORTS BY CONNECTION VOLUME:
----------------------------------------------------------------------
PORT       SERVICE          CONNECTIONS LEVEL          STATUS    
----------------------------------------------------------------------
22         SSH              2          [==        ]   NORMAL    
----------------------------------------------------------------------

[+] TOP REMOTE CLIENTS (TOP TALKERS) (Top 5):
----------------------------------------------------------------------
REMOTE IP              CONNECTIONS  DEST PORTS                    
----------------------------------------------------------------------
177.180.50.192         2            22                            
----------------------------------------------------------------------
```

Structured JSON output (`stat.sh -o json`):

```json
{
  "timestamp": "2026-11-20T04:39:54Z",
  "host": "cpanel-test.local",
  "engine": "ss",
  "total_active_connections": 2,
  "filter": {
    "port": "all",
    "state": "all"
  },
  "tcp_states": {
    "ESTAB": 2,
    "SYN_RECV": 0,
    "TIME_WAIT": 0,
    "CLOSE_WAIT": 0,
    "FIN_WAIT": 0,
    "OTHER": 0
  },
  "top_ports": [{"port": 22, "service": "SSH", "connections": 2, "status": "NORMAL"}],
  "top_remote_ips": [{"ip": "177.180.50.192", "connections": 2, "target_ports": [22]}]
}
```

## Contributing

Contributions, bug reports, and optimizations are welcome via pull requests or GitHub issues.

## Author & License

Developed by **Percio Castelo** ([perciocastelo.com.br](https://perciocastelo.com.br)).

Licensed under the **Apache License 2.0** ([LICENSE](LICENSE)).