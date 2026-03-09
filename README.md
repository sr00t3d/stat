# Network Connection Monitor (Stat)

Readme: [BR](README-ptbr.md)

![License](https://img.shields.io/github/license/sr00t3d/stat) ![Shell Script](https://img.shields.io/badge/shell-script-green)

<img width="700" src="stat-cover.webp" />

A lightweight and efficient Bash script to monitor active network connections in real time. It analyzes current traffic, groups connections by port, and provides visual feedback with color coding based on traffic volume.

Ideal for system administrators to quickly identify traffic spikes, DDoS attacks, or anomalous port usage.

## 🚀 Features

- Real-Time Monitoring: Displays active (established) TCP and UDP connections.
- Top N Ports: Allows defining how many ports to display in the ranking (default: 10).
- Live Mode (Watch): Supports automatic refresh with a definable interval (like the `watch` command).
- Visual Alerts: Dynamic coloring based on load:
  - 🟢 Green: Normal traffic (< 20 connections)
  - 🟠 Orange: Moderate traffic (20 - 50 connections)
  - 🔴 Red: High traffic (> 50 connections)
- Lightweight: Depends only on native tools (`ss`, `awk`, `sort`, `uniq`).

## Prerequisites

To run this script, you need:

- Linux/Unix Operating System.
- `Root/Sudo` access (required for the `ss` command to list all connections).
- Standard packages (usually already installed): `iproute2` (for `ss`), `gawk` or `awk`.

Here’s the English translation:

---

## Installation

### Hosted mode

1. **Download the file to the server:**

```bash
curl -O https://raw.githubusercontent.com/sr00t3d/stat/refs/heads/main/stat.sh
```

2. **Give execution permission:**

```bash
chmod +x stat.sh
```

### Direct mode

```bash
bash <(curl -fsSL 'https://raw.githubusercontent.com/sr00t3d/stat/refs/heads/main/stat.sh')
```

## How to Use

The script should be run with superuser privileges.

**Simple Execution**

Displays the top 10 ports with the most connections and exits.

```bash
./stat.sh

Timestamp: 2026-02-27 23:07:08
Monitoring TOP 10 ports by connection count
----------------------------------------
Port       Total Connections   
----------------------------------------
22         2                   
68         1                   
60993      1                   
60972      1                   
60729      1                   
60550      1                   
60402      1                   
59670      1                   
59596      1                   
59442      1                   
----------------------------------------
```

**Continuous Monitoring (Live Mode)**

Refreshes the screen every 2 seconds (ideal for leaving running on a secondary display).

```bash
./stat.sh -i 2

Timestamp: 2026-02-27 23:07:42
Monitoring TOP 10 ports by connection count
----------------------------------------
Port       Total Connections   
----------------------------------------
22         3                   
68         1                   
60993      1                   
60972      1                   
60729      1                   
60550      1                   
60402      1                   
59670      1                   
59596      1                   
59442      1                   
----------------------------------------
```

**Customize Number of Ports**

Displays the top 20 ports.

```bash
./stat.sh -n 20

./stat.sh -n 20
Timestamp: 2026-02-27 23:08:16
Monitoring TOP 20 ports by connection count
----------------------------------------
Port       Total Connections   
----------------------------------------
22         2                   
68         1                   
60993      1                   
60972      1                   
60729      1                   
60550      1                   
60402      1                   
59670      1                   
59596      1                   
59442      1                   
59397      1                   
59210      1                   
58733      1                   
58507      1                   
58489      1                   
58234      1                   
58121      1                   
57184      1                   
57123      1                   
56292      1                   
----------------------------------------
```

## Command Options

```bash
Flag         Description                                                  Default
-n [NUM]     Defines the number of ports to be displayed in the ranking.  10
-i [SEC]     Defines the refresh interval in seconds (infinite loop)      0 (No refresh)
-h           Displays the help menu                                       -
```

## Understanding the Output

The script classifies traffic as follows:

```bash
Date/Time: 2026-02-13 14:30:00
Monitoring the TOP 10 ports by connection volume
----------------------------------------
Port       Total Connections      
----------------------------------------
443        125                 <-- High Traffic
80         35                  <-- Attention
22         4                   <-- Normal
----------------------------------------
```

## Legal Notice

> [!WARNING]
> This software is provided "as is". Always ensure you have explicit permission before running. The author is not responsible for any misuse, legal consequences, or data impact caused by this tool.

## Detailed Tutorial

For a complete, step-by-step guide, check out my full article:

👉 [**Monitoring Network with Stat**](https://perciocastelo.com.br/blog/monitor-network-with-stat.html)

## License

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more details.