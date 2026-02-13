#!/bin/bash
################################################################################
#                                                                              #
#   PROJECT: Network Connection Monitor (Stat)                                 #
#   VERSION: 2.0.0                                                             #
#                                                                              #
#   AUTHOR:  Percio Andrade                                                    #
#   CONTACT: percio@zendev.com.br | contato@perciocastelo.com.br               #
#   WEB:     https://zendev.com.br                                             #
#                                                                              #
#   INFO:                                                                      #
#   Monitor active network connections by port with traffic color coding.      #
#                                                                              #
################################################################################

# --- CONFIGURATION ---
DEFAULT_TOP_N=10
DEFAULT_INTERVAL=0
# ---------------------

# Detect System Language
SYSTEM_LANG="${LANG:0:2}"

if [[ "$SYSTEM_LANG" == "pt" ]]; then
    # Portuguese Strings
    MSG_USAGE="Uso: $0 [OPÇÕES]"
    MSG_ERR_ROOT="ERRO: Este script precisa ser executado como root."
    MSG_ERR_CMD="ERRO: Comando necessário não encontrado:"
    MSG_ERR_NUM="ERRO: A opção requer um número válido."
    MSG_HEADER="Monitorando as TOP %s portas por volume de conexão"
    MSG_COL_PORT="Porta"
    MSG_COL_CONN="Total Conexões"
    MSG_TIMESTAMP="Data/Hora:"
    MSG_NO_CONN="Nenhuma conexão ativa encontrada."
    MSG_HELP_OPTS="Opções:"
    MSG_HELP_N="  -n NUMERO    Mostrar top N portas (padrão: 10)"
    MSG_HELP_I="  -i INTERVALO Intervalo de atualização em segundos (padrão: sem refresh)"
    MSG_HELP_H="  -h           Mostrar esta ajuda"
else
    # English Strings (Default)
    MSG_USAGE="Usage: $0 [OPTIONS]"
    MSG_ERR_ROOT="ERROR: This script must be run as root/superuser."
    MSG_ERR_CMD="ERROR: Required command not found:"
    MSG_ERR_NUM="ERROR: Option requires a valid number."
    MSG_HEADER="Monitoring TOP %s ports by connection count"
    MSG_COL_PORT="Port"
    MSG_COL_CONN="Total Connections"
    MSG_TIMESTAMP="Timestamp:"
    MSG_NO_CONN="No active connections found."
    MSG_HELP_OPTS="Options:"
    MSG_HELP_N="  -n NUMBER    Show top N ports (default: 10)"
    MSG_HELP_I="  -i INTERVAL  Refresh interval in seconds (default: no refresh)"
    MSG_HELP_H="  -h           Show this help message"
fi

# ANSI Colors
readonly GREEN='\033[0;32m'
readonly ORANGE='\033[0;33m'
readonly RED='\033[0;31m'
readonly RESET='\033[0m'
readonly BOLD='\033[1m'

# Default values
TOP_N=$DEFAULT_TOP_N
INTERVAL=$DEFAULT_INTERVAL

# Help Function
usage() {
    echo "$MSG_USAGE"
    echo "$MSG_HELP_OPTS"
    echo "$MSG_HELP_N"
    echo "$MSG_HELP_I"
    echo "$MSG_HELP_H"
    exit 1
}

# Check Root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}$MSG_ERR_ROOT${RESET}" >&2
    exit 1
fi

# Parse Options
while getopts "n:i:h" opt; do
    case $opt in
        n) 
            TOP_N="$OPTARG"
            [[ "$TOP_N" =~ ^[0-9]+$ ]] || { echo "$MSG_ERR_NUM"; exit 1; }
            ;;
        i) 
            INTERVAL="$OPTARG"
            [[ "$INTERVAL" =~ ^[0-9]+$ ]] || { echo "$MSG_ERR_NUM"; exit 1; }
            ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check Dependencies
for cmd in ss awk sort uniq; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "$MSG_ERR_CMD $cmd" >&2
        exit 1
    fi
done

# Logic to determine color
get_color() {
    local total=$1
    if [[ "$total" -lt 20 ]]; then
        echo -ne "$GREEN"
    elif [[ "$total" -ge 20 && "$total" -le 50 ]]; then
        echo -ne "$ORANGE"
    else
        echo -ne "$RED"
    fi
}

# Main Stats Function
display_stats() {
    # Clear screen if interval mode is active
    [[ $INTERVAL -gt 0 ]] && clear

    echo -e "${BOLD}$MSG_TIMESTAMP${RESET} $(date '+%Y-%m-%d %H:%M:%S')"
    printf "$MSG_HEADER\n" "$TOP_N"
    echo "----------------------------------------"
    printf "${BOLD}%-10s %-20s${RESET}\n" "$MSG_COL_PORT" "$MSG_COL_CONN"
    echo "----------------------------------------"

    # Capture Data
    # Changed from -tuln (listening) to -ntu state established (active connections)
    # This makes the count meaningful.
    # Logic:
    # 1. ss -ntu state established: Get TCP/UDP established connections without resolving names
    # 2. awk: Extract Local Address:Port (Column 4). 
    # 3. awk/split: Extract just the Port (everything after the last colon)
    
    local raw_data
    raw_data=$(ss -ntu state established 2>/dev/null | awk 'NR>1 {print $4}')

    if [[ -z "$raw_data" ]]; then
        echo "$MSG_NO_CONN"
    else
        # Process ports
        # Extract port number handling IPv4 (x.x.x.x:80) and IPv6 ([::]:80)
        local processed_data
        processed_data=$(echo "$raw_data" | \
            awk -F':' '{print $NF}' | \
            sort | \
            uniq -c | \
            sort -rn | \
            head -n "$TOP_N")

        while read -r line; do
            [[ -z "$line" ]] && continue
            
            local count port
            count=$(echo "$line" | awk '{print $1}')
            port=$(echo "$line" | awk '{print $2}')
            
            local color
            color=$(get_color "$count")
            
            # Print Formatted Row
            printf "${color}%-10s %-20s${RESET}\n" "$port" "$count"
            
        done <<< "$processed_data"
    fi
    echo "----------------------------------------"
}

# Loop or Single Run
while true; do
    display_stats
    [[ $INTERVAL -eq 0 ]] && break
    sleep "$INTERVAL"
done
