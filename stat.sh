#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║   Stat(e) Network Connection Monitor v2.0.0                               ║
# ║                                                                           ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║   Autor:   Percio Castelo                                                 ║
# ║   Contato: percio@evolya.com.br | contato@perciocastelo.com.br            ║
# ║   Web:     https://perciocastelo.com.br                                   ║
# ║                                                                           ║
# ║   Função:  Lightweight real-time network traffic grouping, TCP state      ║
# ║            distribution & high-volume connection monitoring.              ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

set -uo pipefail

readonly VERSION="2.0.0"
readonly SCRIPT_NAME="stat.sh"

# Default configuration
TOP_N=10
INTERVAL=0
FILTER_PORT=""
FILTER_STATE=""
OUTPUT_FORMAT="table"
SHOW_TALKERS_ONLY=false
QUIET=false
NO_COLOR=false

# System language detection (pt or en)
SYSTEM_LANG="${LANG:-en}"
SYSTEM_LANG="${SYSTEM_LANG:0:2}"

# Internationalization strings
if [[ "$SYSTEM_LANG" == "pt" ]]; then
    MSG_TITLE="STAT(E) — MONITOR DE CONEXÕES DE REDE"
    MSG_DESC="Monitoramento leve em tempo real de tráfego, portas e estados TCP."
    MSG_USAGE="Uso: $SCRIPT_NAME [OPÇÕES]"
    MSG_OPTS_HEADER="Opções:"
    MSG_OPT_TOP="  -t, -n, --top NUM      Número de registros a exibir no ranking (padrão: 10)"
    MSG_OPT_INTERVAL="  -i, --interval SEG     Intervalo de atualização contínua em segundos (ex: 2)"
    MSG_OPT_WATCH="  -w, --watch [SEG]      Ativar modo contínuo interativo (padrão: 2s)"
    MSG_OPT_PORT="  -p, --port PORTA       Filtrar conexões por porta local de destino (ex: 80, 443, 22)"
    MSG_OPT_STATE="  -s, --state ESTADO     Filtrar conexões por estado TCP (ex: ESTAB, TIME-WAIT, SYN-RECV)"
    MSG_OPT_TALKERS="  --top-talkers          Exibir ranking exclusivo de IPs remotos (Top Talkers)"
    MSG_OPT_FORMAT="  -o, --output FORMAT    Formato de saída: table, json, csv (padrão: table)"
    MSG_OPT_QUIET="  -q, --quiet            Modo silencioso (omite banners e cabeçalhos decorativos)"
    MSG_OPT_NO_COLOR="  --no-color             Desabilitar escape de cores ANSI"
    MSG_OPT_VER="  -V, --version          Exibir versão e autor"
    MSG_OPT_HELP="  -h, --help             Exibir esta mensagem de ajuda"
    MSG_ERR_NUM="ERRO: O valor fornecido precisa ser um número inteiro válido maior que zero."
    MSG_ERR_PORT="ERRO: Porta inválida (deve estar entre 1 e 65535)."
    MSG_ERR_DEP="ERRO: Nenhuma ferramenta de rede suportada encontrada (ss ou netstat)."
    MSG_ERR_FMT="ERRO: Formato de saída inválido. Escolha entre: table, json, csv."
    MSG_ROOT_WARN="AVISO: Executando sem privilégios root. Algumas conexões de outros processos podem não ser listadas."
    MSG_NO_CONN="Nenhuma conexão ativa correspondente aos filtros foi encontrada."
    MSG_STATE_HDR="RESUMO DE ESTADOS TCP"
    MSG_PORTS_HDR="TOP %s PORTAS POR VOLUME DE CONEXÃO"
    MSG_TALKERS_HDR="TOP CLIENTES REMOTOS (TOP TALKERS)"
    MSG_PORT_FILTER_HDR="DETALHES DA PORTA LOCAL %s"
    MSG_COL_PORT="PORTA"
    MSG_COL_SERVICE="SERVIÇO"
    MSG_COL_CONN="CONEXÕES"
    MSG_COL_LEVEL="NÍVEL"
    MSG_COL_STATUS="STATUS"
    MSG_COL_REMOTE_IP="IP REMOTO"
    MSG_COL_DEST_PORTS="PORTAS DESTINO"
    MSG_STATUS_NORMAL="NORMAL"
    MSG_STATUS_MODERATE="ELEVADO"
    MSG_STATUS_HIGH="CRÍTICO"
    MSG_WARN_SYN="ALERTA: Alto volume de conexões SYN_RECV detectado (%d). Possível ataque SYN Flood!"
    MSG_WARN_CLOSE="AVISO: Elevado número de conexões CLOSE_WAIT (%d). Possível socket leak na aplicação."
else
    MSG_TITLE="STAT(E) — NETWORK CONNECTION MONITOR"
    MSG_DESC="Lightweight real-time network traffic grouping, TCP state & socket monitor."
    MSG_USAGE="Usage: $SCRIPT_NAME [OPTIONS]"
    MSG_OPTS_HEADER="Options:"
    MSG_OPT_TOP="  -t, -n, --top NUM      Number of entries in top ranking (default: 10)"
    MSG_OPT_INTERVAL="  -i, --interval SEC     Continuous refresh interval in seconds (e.g. 2)"
    MSG_OPT_WATCH="  -w, --watch [SEC]      Enable live interactive watch mode (default: 2s)"
    MSG_OPT_PORT="  -p, --port PORT        Filter connections by local destination port (e.g. 80, 443, 22)"
    MSG_OPT_STATE="  -s, --state STATE      Filter connections by TCP state (e.g. ESTAB, TIME-WAIT, SYN-RECV)"
    MSG_OPT_TALKERS="  --top-talkers          Display top remote client IPs ranking only"
    MSG_OPT_FORMAT="  -o, --output FORMAT    Output format: table, json, csv (default: table)"
    MSG_OPT_QUIET="  -q, --quiet            Quiet mode (omit decorative banners/headers)"
    MSG_OPT_NO_COLOR="  --no-color             Disable ANSI color escape sequences"
    MSG_OPT_VER="  -V, --version          Display version and author"
    MSG_OPT_HELP="  -h, --help             Display this help message"
    MSG_ERR_NUM="ERROR: Provided argument must be a valid positive integer."
    MSG_ERR_PORT="ERROR: Invalid port number (must be between 1 and 65535)."
    MSG_ERR_DEP="ERROR: No supported network tool found (requires ss or netstat)."
    MSG_ERR_FMT="ERROR: Invalid output format. Choose from: table, json, csv."
    MSG_ROOT_WARN="WARNING: Running without root privileges. Sockets from other processes might be omitted."
    MSG_NO_CONN="No active connections matching the specified filters were found."
    MSG_STATE_HDR="TCP STATES SUMMARY"
    MSG_PORTS_HDR="TOP %s PORTS BY CONNECTION VOLUME"
    MSG_TALKERS_HDR="TOP REMOTE CLIENTS (TOP TALKERS)"
    MSG_PORT_FILTER_HDR="LOCAL PORT %s DETAILS"
    MSG_COL_PORT="PORT"
    MSG_COL_SERVICE="SERVICE"
    MSG_COL_CONN="CONNECTIONS"
    MSG_COL_LEVEL="LEVEL"
    MSG_COL_STATUS="STATUS"
    MSG_COL_REMOTE_IP="REMOTE IP"
    MSG_COL_DEST_PORTS="DEST PORTS"
    MSG_STATUS_NORMAL="NORMAL"
    MSG_STATUS_MODERATE="MODERATE"
    MSG_STATUS_HIGH="CRITICAL"
    MSG_WARN_SYN="ALERT: High volume of SYN_RECV sockets detected (%d). Potential SYN Flood attack!"
    MSG_WARN_CLOSE="WARNING: High volume of CLOSE_WAIT sockets (%d). Potential application socket leak."
fi

# Print version information
show_version() {
    cat << EOF
Stat(e) Network Connection Monitor v$VERSION
Author: Percio Castelo (https://perciocastelo.com.br)
License: Apache License 2.0 (Apache-2.0)
EOF
    exit 0
}

# Print help message
show_help() {
    cat << EOF
$MSG_TITLE v$VERSION
$MSG_DESC

$MSG_USAGE

$MSG_OPTS_HEADER
$MSG_OPT_TOP
$MSG_OPT_INTERVAL
$MSG_OPT_WATCH
$MSG_OPT_PORT
$MSG_OPT_STATE
$MSG_OPT_TALKERS
$MSG_OPT_FORMAT
$MSG_OPT_QUIET
$MSG_OPT_NO_COLOR
$MSG_OPT_VER
$MSG_OPT_HELP

Examples:
  $SCRIPT_NAME                         # Instant snapshot of Top 10 ports & TCP states
  $SCRIPT_NAME -w 2                    # Live watch mode updating every 2 seconds
  $SCRIPT_NAME -p 443                  # Monitor only HTTPS traffic and top connecting IPs
  $SCRIPT_NAME --top-talkers -t 20     # Show top 20 remote attacking/connecting IPs
  $SCRIPT_NAME -o json                 # Structured JSON snapshot for SIEM/monitoring
  $SCRIPT_NAME -o csv                  # CSV format for logging or metric ingestion
EOF
    exit 0
}

# Parse CLI arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--top|-n)
                shift
                [[ $# -eq 0 ]] && { echo "$MSG_ERR_NUM" >&2; exit 1; }
                [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -gt 0 ]] || { echo "$MSG_ERR_NUM" >&2; exit 1; }
                TOP_N="$1"
                shift
                ;;
            -i|--interval)
                shift
                [[ $# -eq 0 ]] && { echo "$MSG_ERR_NUM" >&2; exit 1; }
                [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -ge 0 ]] || { echo "$MSG_ERR_NUM" >&2; exit 1; }
                INTERVAL="$1"
                shift
                ;;
            -w|--watch)
                if [[ $# -gt 1 ]] && [[ "$2" =~ ^[0-9]+$ ]] && [[ "$2" -gt 0 ]]; then
                    INTERVAL="$2"
                    shift 2
                else
                    INTERVAL=2
                    shift
                fi
                ;;
            -p|--port)
                shift
                [[ $# -eq 0 ]] && { echo "$MSG_ERR_PORT" >&2; exit 1; }
                [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -ge 1 ]] && [[ "$1" -le 65535 ]] || { echo "$MSG_ERR_PORT" >&2; exit 1; }
                FILTER_PORT="$1"
                shift
                ;;
            -s|--state)
                shift
                [[ $# -eq 0 ]] && { echo "$MSG_ERR_FMT" >&2; exit 1; }
                FILTER_STATE="$(echo "$1" | tr '[:lower:]' '[:upper:]')"
                shift
                ;;
            --top-talkers)
                SHOW_TALKERS_ONLY=true
                shift
                ;;
            -o|--output)
                shift
                [[ $# -eq 0 ]] && { echo "$MSG_ERR_FMT" >&2; exit 1; }
                case "$1" in
                    table|json|csv) OUTPUT_FORMAT="$1" ;;
                    *) echo "$MSG_ERR_FMT" >&2; exit 1 ;;
                esac
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            --no-color)
                NO_COLOR=true
                shift
                ;;
            -V|--version)
                show_version
                ;;
            -h|--help)
                show_help
                ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Run '$SCRIPT_NAME --help' for details." >&2
                exit 1
                ;;
        esac
    done
}

parse_args "$@"

# Check tty for colors
if [[ -t 1 ]] && [[ "$NO_COLOR" = false ]]; then
    readonly C_RESET='\033[0m'
    readonly C_BOLD='\033[1m'
    readonly C_DIM='\033[2m'
    readonly C_GREEN='\033[0;32m'
    readonly C_YELLOW='\033[0;33m'
    readonly C_RED='\033[0;31m'
    readonly C_CYAN='\033[0;36m'
    readonly C_BLUE='\033[0;34m'
    readonly C_MAGENTA='\033[0;35m'
else
    readonly C_RESET=''
    readonly C_BOLD=''
    readonly C_DIM=''
    readonly C_GREEN=''
    readonly C_YELLOW=''
    readonly C_RED=''
    readonly C_CYAN=''
    readonly C_BLUE=''
    readonly C_MAGENTA=''
fi

# Detect networking tool (ss preferred over netstat)
NETWORK_ENGINE=""
if command -v ss &>/dev/null; then
    NETWORK_ENGINE="ss"
elif command -v netstat &>/dev/null; then
    NETWORK_ENGINE="netstat"
else
    echo "$MSG_ERR_DEP" >&2
    exit 1
fi

# Map well-known port to service name
get_service_name() {
    local port="$1"
    case "$port" in
        20) echo "FTP-Data" ;;
        21) echo "FTP" ;;
        22) echo "SSH" ;;
        25) echo "SMTP" ;;
        53) echo "DNS" ;;
        80) echo "HTTP" ;;
        110) echo "POP3" ;;
        143) echo "IMAP" ;;
        443) echo "HTTPS" ;;
        465) echo "SMTPS" ;;
        587) echo "Submission" ;;
        993) echo "IMAPS" ;;
        995) echo "POP3S" ;;
        2082) echo "cPanel" ;;
        2083) echo "cPanel-SSL" ;;
        2086) echo "WHM" ;;
        2087) echo "WHM-SSL" ;;
        2095) echo "Webmail" ;;
        2096) echo "Webmail-SSL" ;;
        3306) echo "MySQL" ;;
        5432) echo "PostgreSQL" ;;
        6379) echo "Redis" ;;
        8080) echo "HTTP-Alt" ;;
        8088) echo "NEXUS-Dev" ;;
        8089) echo "PercioSite" ;;
        8443) echo "HTTPS-Alt" ;;
        *)
            # Fallback to /etc/services if available
            local svc=""
            if [[ -f /etc/services ]]; then
                svc=$(awk -v p="$port" '$2 ~ "^" p "/(tcp|udp)$" {print $1; exit}' /etc/services 2>/dev/null)
            fi
            if [[ -n "$svc" ]]; then
                echo "$svc"
            else
                echo "-"
            fi
            ;;
    esac
}

# Determine status and visual load bar based on connection count
get_load_meta() {
    local count="$1"
    local color=""
    local status=""
    local bar=""

    if [[ "$count" -lt 20 ]]; then
        color="$C_GREEN"
        status="$MSG_STATUS_NORMAL"
        bar="[==        ]"
    elif [[ "$count" -le 50 ]]; then
        color="$C_YELLOW"
        status="$MSG_STATUS_MODERATE"
        bar="[======    ]"
    else
        color="$C_RED"
        status="$MSG_STATUS_HIGH"
        bar="[==========]"
    fi

    echo "$color|$status|$bar"
}

# Collect raw active connection records
# Returns space-separated stream: PROTO STATE LOCAL_IP LOCAL_PORT PEER_IP PEER_PORT
collect_sockets() {
    if [[ "$NETWORK_ENGINE" == "ss" ]]; then
        # ss -ntu outputs:
        # Netid State Recv-Q Send-Q Local Address:Port Peer Address:Port
        ss -ntu 2>/dev/null | awk 'NR>1 {
            proto = $1
            state = $2
            loc = $5
            peer = $6

            # Parse Local IP and Port
            split(loc, loc_parts, ":")
            loc_port = loc_parts[length(loc_parts)]
            loc_ip = ""
            for (i=1; i<length(loc_parts); i++) {
                loc_ip = (loc_ip == "") ? loc_parts[i] : loc_ip ":" loc_parts[i]
            }
            # Clean IPv6 bracket notation
            gsub(/[\[\]]/, "", loc_ip)

            # Parse Peer IP and Port
            split(peer, peer_parts, ":")
            peer_port = peer_parts[length(peer_parts)]
            peer_ip = ""
            for (i=1; i<length(peer_parts); i++) {
                peer_ip = (peer_ip == "") ? peer_parts[i] : peer_ip ":" peer_parts[i]
            }
            gsub(/[\[\]]/, "", peer_ip)

            if (peer_ip == "*" || peer_ip == "") peer_ip = "0.0.0.0"

            print proto, state, loc_ip, loc_port, peer_ip, peer_port
        }'
    else
        # netstat -ntu fallback outputs:
        # Proto Recv-Q Send-Q Local Address Foreign Address State
        netstat -ntu 2>/dev/null | awk 'NR>2 {
            proto = $1
            loc = $4
            peer = $5
            state = ($6 != "") ? $6 : "UNKNOWN"

            split(loc, loc_parts, ":")
            loc_port = loc_parts[length(loc_parts)]
            loc_ip = ""
            for (i=1; i<length(loc_parts); i++) {
                loc_ip = (loc_ip == "") ? loc_parts[i] : loc_ip ":" loc_parts[i]
            }

            split(peer, peer_parts, ":")
            peer_port = peer_parts[length(peer_parts)]
            peer_ip = ""
            for (i=1; i<length(peer_parts); i++) {
                peer_ip = (peer_ip == "") ? peer_parts[i] : peer_ip ":" peer_parts[i]
            }

            if (peer_ip == "*" || peer_ip == "") peer_ip = "0.0.0.0"

            print proto, state, loc_ip, loc_port, peer_ip, peer_port
        }'
    fi
}

# Render Table output
render_table() {
    local raw_data="$1"
    local hostname_str
    hostname_str="$(hostname -f 2>/dev/null || hostname)"
    local now_str
    now_str="$(date '+%Y-%m-%d %H:%M:%S')"

    # Calculate total and filter by state/port if set
    local filtered_data="$raw_data"
    if [[ -n "$FILTER_PORT" ]]; then
        filtered_data=$(echo "$filtered_data" | awk -v p="$FILTER_PORT" '$4 == p')
    fi
    if [[ -n "$FILTER_STATE" ]]; then
        filtered_data=$(echo "$filtered_data" | awk -v s="$FILTER_STATE" 'toupper($2) == s || toupper($2) ~ s')
    fi

    local total_conns=0
    if [[ -n "$filtered_data" ]]; then
        total_conns=$(echo "$filtered_data" | grep -c . || true)
    fi

    # TCP States Summary (from raw_data)
    local count_estab count_timewait count_closewait count_synrecv count_finwait count_other
    count_estab=$(echo "$raw_data" | awk 'toupper($2) ~ /^ESTAB/ {c++} END {print c+0}')
    count_timewait=$(echo "$raw_data" | awk 'toupper($2) ~ /TIME/ {c++} END {print c+0}')
    count_closewait=$(echo "$raw_data" | awk 'toupper($2) ~ /CLOSE/ {c++} END {print c+0}')
    count_synrecv=$(echo "$raw_data" | awk 'toupper($2) ~ /SYN/ {c++} END {print c+0}')
    count_finwait=$(echo "$raw_data" | awk 'toupper($2) ~ /FIN/ {c++} END {print c+0}')
    count_other=$(echo "$raw_data" | awk 'toupper($2) !~ /ESTAB|TIME|CLOSE|SYN|FIN/ {c++} END {print c+0}')

    if [[ "$QUIET" = false ]]; then
        echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
        printf "${C_CYAN}║${C_RESET} ${C_BOLD}%-76s${C_RESET} ${C_CYAN}║${C_RESET}\n" "$MSG_TITLE v$VERSION"
        echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${C_RESET}"
        printf "${C_DIM}Host: %s | Data/Hora: %s | Motor: %s | Total Ativo: %d${C_RESET}\n" "$hostname_str" "$now_str" "$NETWORK_ENGINE" "$total_conns"
        echo ""

        # States Bar
        echo -e "${C_BOLD}[+] $MSG_STATE_HDR:${C_RESET}"
        printf "  ESTAB: ${C_GREEN}%d${C_RESET}  |  SYN_RECV: " "$count_estab"
        if [[ $count_synrecv -gt 20 ]]; then
            printf "${C_RED}${C_BOLD}%d${C_RESET}" "$count_synrecv"
        else
            printf "${C_GREEN}%d${C_RESET}" "$count_synrecv"
        fi
        printf "  |  TIME_WAIT: ${C_CYAN}%d${C_RESET}  |  CLOSE_WAIT: " "$count_timewait"
        if [[ $count_closewait -gt 50 ]]; then
            printf "${C_RED}${C_BOLD}%d${C_RESET}" "$count_closewait"
        else
            printf "${C_YELLOW}%d${C_RESET}" "$count_closewait"
        fi
        printf "  |  FIN_WAIT: %d  |  OUTROS: %d\n" "$count_finwait" "$count_other"
        echo ""

        # Alerts if thresholds exceeded
        if [[ $count_synrecv -gt 20 ]]; then
            printf "${C_RED}${C_BOLD}[!] $MSG_WARN_SYN${C_RESET}\n\n" "$count_synrecv"
        fi
        if [[ $count_closewait -gt 50 ]]; then
            printf "${C_YELLOW}${C_BOLD}[!] $MSG_WARN_CLOSE${C_RESET}\n\n" "$count_closewait"
        fi
    fi

    if [[ "$total_conns" -eq 0 ]]; then
        echo -e "${C_YELLOW}$MSG_NO_CONN${C_RESET}"
        return 0
    fi

    # If Port Filter was specified
    if [[ -n "$FILTER_PORT" ]]; then
        local svc
        svc=$(get_service_name "$FILTER_PORT")
        printf "${C_BOLD}[+] $MSG_PORT_FILTER_HDR (%s) - %d conexões ativas:${C_RESET}\n" "$FILTER_PORT" "$svc" "$total_conns"
        echo "----------------------------------------------------------------------"
        printf "${C_BOLD}%-22s %-12s %-15s${C_RESET}\n" "$MSG_COL_REMOTE_IP" "$MSG_COL_CONN" "$MSG_COL_STATUS"
        echo "----------------------------------------------------------------------"

        echo "$filtered_data" | awk '{print $5}' | grep -v "^0.0.0.0$" | sort | uniq -c | sort -rn | head -n "$TOP_N" | while read -r count rip; do
            [[ -z "$count" ]] && continue
            IFS='|' read -r col status bar < <(get_load_meta "$count")
            printf "%-22s ${col}%-12s %-15s${C_RESET}\n" "$rip" "$count" "$status"
        done
        echo "----------------------------------------------------------------------"
        return 0
    fi

    # If Talkers Only was requested
    if [[ "$SHOW_TALKERS_ONLY" = true ]]; then
        echo -e "${C_BOLD}[+] $MSG_TALKERS_HDR (Top $TOP_N):${C_RESET}"
        echo "----------------------------------------------------------------------"
        printf "${C_BOLD}%-22s %-12s %-30s${C_RESET}\n" "$MSG_COL_REMOTE_IP" "$MSG_COL_CONN" "$MSG_COL_DEST_PORTS"
        echo "----------------------------------------------------------------------"

        # Group by remote IP and aggregate destination ports
        echo "$filtered_data" | awk '{
            rip = $5
            port = $4
            if (rip != "0.0.0.0" && rip != "") {
                counts[rip]++
                if (ports[rip] !~ ("(^|,)" port "(,|$)")) {
                    ports[rip] = (ports[rip] == "") ? port : ports[rip] "," port
                }
            }
        }
        END {
            for (ip in counts) {
                print counts[ip], ip, ports[ip]
            }
        }' | sort -rn | head -n "$TOP_N" | while read -r count rip dports; do
            [[ -z "$count" ]] && continue
            IFS='|' read -r col status bar < <(get_load_meta "$count")
            printf "%-22s ${col}%-12s${C_RESET} %-30s\n" "$rip" "$count" "$dports"
        done
        echo "----------------------------------------------------------------------"
        return 0
    fi

    # Default View: Top Ports ranking + Top Remote Talkers
    printf "${C_BOLD}[+] $MSG_PORTS_HDR:${C_RESET}\n" "$TOP_N"
    echo "----------------------------------------------------------------------"
    printf "${C_BOLD}%-10s %-16s %-10s %-14s %-10s${C_RESET}\n" "$MSG_COL_PORT" "$MSG_COL_SERVICE" "$MSG_COL_CONN" "$MSG_COL_LEVEL" "$MSG_COL_STATUS"
    echo "----------------------------------------------------------------------"

    echo "$filtered_data" | awk '{print $4}' | sort -n | uniq -c | sort -rn | head -n "$TOP_N" | while read -r count port; do
        [[ -z "$count" ]] && continue
        local svc
        svc=$(get_service_name "$port")
        IFS='|' read -r col status bar < <(get_load_meta "$count")
        printf "%-10s %-16s ${col}%-10s %-14s %-10s${C_RESET}\n" "$port" "$svc" "$count" "$bar" "$status"
    done
    echo "----------------------------------------------------------------------"

    # Top Remote Clients subsection
    echo ""
    echo -e "${C_BOLD}[+] $MSG_TALKERS_HDR (Top 5):${C_RESET}"
    echo "----------------------------------------------------------------------"
    printf "${C_BOLD}%-22s %-12s %-30s${C_RESET}\n" "$MSG_COL_REMOTE_IP" "$MSG_COL_CONN" "$MSG_COL_DEST_PORTS"
    echo "----------------------------------------------------------------------"

    echo "$filtered_data" | awk '{
        rip = $5
        port = $4
        if (rip != "0.0.0.0" && rip != "") {
            counts[rip]++
            if (ports[rip] !~ ("(^|,)" port "(,|$)")) {
                ports[rip] = (ports[rip] == "") ? port : ports[rip] "," port
            }
        }
    }
    END {
        for (ip in counts) {
            print counts[ip], ip, ports[ip]
        }
    }' | sort -rn | head -n 5 | while read -r count rip dports; do
        [[ -z "$count" ]] && continue
        IFS='|' read -r col status bar < <(get_load_meta "$count")
        printf "%-22s ${col}%-12s${C_RESET} %-30s\n" "$rip" "$count" "$dports"
    done
    echo "----------------------------------------------------------------------"
}

# Render JSON output
render_json() {
    local raw_data="$1"
    local hostname_str
    hostname_str="$(hostname -f 2>/dev/null || hostname)"
    local iso_timestamp
    iso_timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    local filtered_data="$raw_data"
    if [[ -n "$FILTER_PORT" ]]; then
        filtered_data=$(echo "$filtered_data" | awk -v p="$FILTER_PORT" '$4 == p')
    fi
    if [[ -n "$FILTER_STATE" ]]; then
        filtered_data=$(echo "$filtered_data" | awk -v s="$FILTER_STATE" 'toupper($2) == s || toupper($2) ~ s')
    fi

    local total_conns=0
    if [[ -n "$filtered_data" ]]; then
        total_conns=$(echo "$filtered_data" | grep -c . || true)
    fi

    # TCP States Summary
    local count_estab count_timewait count_closewait count_synrecv count_finwait count_other
    count_estab=$(echo "$raw_data" | awk 'toupper($2) ~ /^ESTAB/ {c++} END {print c+0}')
    count_timewait=$(echo "$raw_data" | awk 'toupper($2) ~ /TIME/ {c++} END {print c+0}')
    count_closewait=$(echo "$raw_data" | awk 'toupper($2) ~ /CLOSE/ {c++} END {print c+0}')
    count_synrecv=$(echo "$raw_data" | awk 'toupper($2) ~ /SYN/ {c++} END {print c+0}')
    count_finwait=$(echo "$raw_data" | awk 'toupper($2) ~ /FIN/ {c++} END {print c+0}')
    count_other=$(echo "$raw_data" | awk 'toupper($2) !~ /ESTAB|TIME|CLOSE|SYN|FIN/ {c++} END {print c+0}')

    # Generate Top Ports JSON array
    local ports_json="[]"
    if [[ -n "$filtered_data" ]]; then
        local ports_items=""
        while read -r count port; do
            [[ -z "$count" ]] && continue
            local svc
            svc=$(get_service_name "$port")
            local st="NORMAL"
            [[ $count -ge 20 ]] && st="MODERATE"
            [[ $count -gt 50 ]] && st="CRITICAL"
            
            local item="{\"port\": $port, \"service\": \"$svc\", \"connections\": $count, \"status\": \"$st\"}"
            if [[ -z "$ports_items" ]]; then
                ports_items="$item"
            else
                ports_items="$ports_items, $item"
            fi
        done < <(echo "$filtered_data" | awk '{print $4}' | sort -n | uniq -c | sort -rn | head -n "$TOP_N")
        ports_json="[$ports_items]"
    fi

    # Generate Top Talkers JSON array
    local talkers_json="[]"
    if [[ -n "$filtered_data" ]]; then
        local talkers_items=""
        while read -r count rip dports; do
            [[ -z "$count" ]] && continue
            # Convert comma separated ports to json array
            local ports_arr
            ports_arr=$(echo "$dports" | awk -F',' '{for(i=1;i<=NF;i++) printf "%s%s", (i>1?", ":""), $i}')
            local item="{\"ip\": \"$rip\", \"connections\": $count, \"target_ports\": [$ports_arr]}"
            if [[ -z "$talkers_items" ]]; then
                talkers_items="$item"
            else
                talkers_items="$talkers_items, $item"
            fi
        done < <(echo "$filtered_data" | awk '{
            rip = $5
            port = $4
            if (rip != "0.0.0.0" && rip != "") {
                counts[rip]++
                if (ports[rip] !~ ("(^|,)" port "(,|$)")) {
                    ports[rip] = (ports[rip] == "") ? port : ports[rip] "," port
                }
            }
        }
        END {
            for (ip in counts) {
                print counts[ip], ip, ports[ip]
            }
        }' | sort -rn | head -n "$TOP_N")
        talkers_json="[$talkers_items]"
    fi

    cat << EOF
{
  "timestamp": "$iso_timestamp",
  "host": "$hostname_str",
  "engine": "$NETWORK_ENGINE",
  "total_active_connections": $total_conns,
  "filter": {
    "port": "${FILTER_PORT:-all}",
    "state": "${FILTER_STATE:-all}"
  },
  "tcp_states": {
    "ESTAB": $count_estab,
    "SYN_RECV": $count_synrecv,
    "TIME_WAIT": $count_timewait,
    "CLOSE_WAIT": $count_closewait,
    "FIN_WAIT": $count_finwait,
    "OTHER": $count_other
  },
  "top_ports": $ports_json,
  "top_remote_ips": $talkers_json
}
EOF
}

# Render CSV output
render_csv() {
    local raw_data="$1"
    local now_str
    now_str="$(date '+%Y-%m-%d %H:%M:%S')"

    local filtered_data="$raw_data"
    if [[ -n "$FILTER_PORT" ]]; then
        filtered_data=$(echo "$filtered_data" | awk -v p="$FILTER_PORT" '$4 == p')
    fi
    if [[ -n "$FILTER_STATE" ]]; then
        filtered_data=$(echo "$filtered_data" | awk -v s="$FILTER_STATE" 'toupper($2) == s || toupper($2) ~ s')
    fi

    if [[ "$SHOW_TALKERS_ONLY" = true ]] || [[ -n "$FILTER_PORT" ]]; then
        echo "timestamp,remote_ip,connections,target_ports"
        echo "$filtered_data" | awk '{
            rip = $5
            port = $4
            if (rip != "0.0.0.0" && rip != "") {
                counts[rip]++
                if (ports[rip] !~ ("(^|,)" port "(,|$)")) {
                    ports[rip] = (ports[rip] == "") ? port : ports[rip] ";" port
                }
            }
        }
        END {
            for (ip in counts) {
                print counts[ip], ip, ports[ip]
            }
        }' | sort -rn | head -n "$TOP_N" | while read -r count rip dports; do
            [[ -z "$count" ]] && continue
            echo "$now_str,$rip,$count,\"$dports\""
        done
    else
        echo "timestamp,port,service,connections,status"
        echo "$filtered_data" | awk '{print $4}' | sort -n | uniq -c | sort -rn | head -n "$TOP_N" | while read -r count port; do
            [[ -z "$count" ]] && continue
            local svc
            svc=$(get_service_name "$port")
            local st="NORMAL"
            [[ $count -ge 20 ]] && st="MODERATE"
            [[ $count -gt 50 ]] && st="CRITICAL"
            echo "$now_str,$port,$svc,$count,$st"
        done
    fi
}

# Execution driver (Snapshot or Watch loop)
run_iteration() {
    local sockets
    sockets=$(collect_sockets)

    case "$OUTPUT_FORMAT" in
        table) render_table "$sockets" ;;
        json)  render_json "$sockets" ;;
        csv)   render_csv "$sockets" ;;
    esac
}

# Root privilege advisory check
if [[ $EUID -ne 0 ]] && [[ "$QUIET" = false ]] && [[ "$OUTPUT_FORMAT" == "table" ]]; then
    echo -e "${C_YELLOW}$MSG_ROOT_WARN${C_RESET}" >&2
fi

# Main execution loop
if [[ "$INTERVAL" -gt 0 ]]; then
    while true; do
        if [[ "$OUTPUT_FORMAT" == "table" ]]; then
            clear
        fi
        run_iteration
        sleep "$INTERVAL"
    done
else
    run_iteration
fi

exit 0
