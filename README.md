# Network Connection Monitor (Stat)

Readme: [Português](README-ptbr.md)

![License](https://img.shields.io/github/license/sr00t3d/stat)
![Shell Script](https://img.shields.io/badge/shell-script-green)

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

## 📋 Prerequisites

To run this script, you need:

- Linux/Unix Operating System.
- `Root/Sudo` access (required for the `ss` command to list all connections).
- Standard packages (usually already installed): `iproute2` (for `ss`), `gawk` or `awk`.

## 📥 Installation

You can download the script directly to your server:

```bash
wget https://raw.githubusercontent.com/sr00t3d/stat/refs/heads/main/stat.sh
chmod +x stat.sh
```

## ⚙️ How to Use
The script must be executed with superuser privileges.

**Simple Execution**

Shows the top 10 ports with the most connections and exits.

```bash
./stat.sh
```

**Continuous Monitoring (Live Mode)**
Refreshes the screen every 2 seconds (ideal for running on a secondary screen).

```bash
./stat.sh -i 2
```

**Customize Quantity**
Shows the top 20 ports.

```bash
./stat.sh -n 20
```

**Combining Options**
Shows the top 5 ports and refreshes every 1 second.

```bash
sudo ./stat.sh -n 5 -i 1
```

## 📖 Command Options

```bash
Flag         Description                                                  Default
-n [NUM]     Defines the number of ports to be displayed in the ranking.  10
-i [SEC]     Defines the refresh interval in seconds (infinite loop)      0 (No refresh)
-h           Displays the help menu                                       -
```

## 🎨 Understanding the Output
The script classifies traffic as follows:

```bash
Date/Time: 2026-02-13 14:30:00
Monitoring the TOP 10 ports by connection volume
----------------------------------------
Port       Total Connections      
----------------------------------------
443        125                 <-- Red (High Traffic)
80         35                  <-- Orange (Attention)
22         4                   <-- Green (Normal)
----------------------------------------
```

## ⚠️ Legal Notice

> [!WARNING]
> This software is provided "as is". Always make sure to test first in a development environment. The author is not responsible for any misuse, legal consequences, or data impact caused by this tool.

## 📚 Detailed Tutorial

For a complete, step-by-step guide on how to import generated files into Thunderbird and troubleshoot common migration issues, check out my full article:

👉 [**Monitoring Network with Stat**](https://perciocastelo.com.br/blog/monitor-network-with-stat.html)

## License 📄

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more details.
