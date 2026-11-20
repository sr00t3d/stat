# Network Connection Monitor (Stat)

Readme: [English](README.md)

![Licença](https://img.shields.io/badge/licença-Apache--2.0-blue.svg) ![Shell Script](https://img.shields.io/badge/shell-script-green) ![Release](https://img.shields.io/badge/release-v2.0.0-blue)

<img width="700" src="stat-cover.webp" alt="Capa do Network Connection Monitor" />

Script Bash leve e eficiente para monitorar conexões ativas de rede em tempo real em servidores Linux. Analisa sockets ativos TCP e UDP, agrupa conexões por porta local de destino, audita a distribuição de estados TCP (detectando ataques de SYN Flood e vazamento de sockets) e isola os principais endereços IP remotos de clientes (Top Talkers).

## Recursos

- **Agregação de Tráfego em Tempo Real**: Audita sockets TCP/UDP ativos agrupados por porta de destino.
- **Telemetria de Estados TCP**: Contabilização instantânea de `ESTAB`, `SYN_RECV`, `TIME_WAIT`, `CLOSE_WAIT` e `FIN_WAIT`.
- **Alertas Automáticos de Anomalia**: Limiares integrados acionam alertas visuais para suspeita de SYN Flood (`SYN_RECV > 20`) ou exaustão de descritores (`CLOSE_WAIT > 50`).
- **Inspeção de Porta Específica (`-p, --port`)**: Inspecione portas de serviços críticos (80, 443, 22, 3306) para identificar quem está conectado.
- **Isolamento de Top Talkers (`--top-talkers`)**: Agrupa e ranqueia conexões por IP de origem para isolar tráfego abusivo.
- **Modo Watch Contínuo (`-w, --watch`)**: Dashboard interativo de console com atualização em intervalo configurável.
- **Múltiplos Formatos de Saída (`-o table|json|csv`)**: Pronto para diagnóstico interativo no terminal, logs CSV ou pipelines JSON para SIEM.
- **Zero Dependências Pesadas**: Utiliza utilitários nativos do Linux (`ss` do pacote `iproute2` com fallback para `netstat`).

## Instalação

### Execução Direta

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sr00t3d/stat/main/stat.sh)
```

### Clonar ou Baixar

```bash
git clone https://github.com/sr00t3d/stat.git
cd stat
chmod +x stat.sh
sudo ./stat.sh
```

## Uso via Linha de Comando

```text
STAT(E) — MONITOR DE CONEXÕES DE REDE v2.0.0
Monitoramento leve em tempo real de tráfego, portas e estados TCP.

Uso: stat.sh [OPÇÕES]

Opções:
  -t, -n, --top NUM      Número de registros a exibir no ranking (padrão: 10)
  -i, --interval SEG     Intervalo de atualização contínua em segundos (ex: 2)
  -w, --watch [SEG]      Ativar modo contínuo interativo (padrão: 2s)
  -p, --port PORTA       Filtrar conexões por porta local de destino (ex: 80, 443, 22)
  -s, --state ESTADO     Filtrar conexões por estado TCP (ex: ESTAB, TIME-WAIT, SYN-RECV)
  --top-talkers          Exibir ranking exclusivo de IPs remotos (Top Talkers)
  -o, --output FORMAT    Formato de saída: table, json, csv (padrão: table)
  -q, --quiet            Modo silencioso (omite banners e cabeçalhos decorativos)
  --no-color             Desabilitar escape de cores ANSI
  -V, --version          Exibir versão e autor
  -h, --help             Exibir esta mensagem de ajuda
```

## Exemplo de Saída Real

Capturado em execução real em container AlmaLinux 8 de produção (`cpanel-test`):

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

Saída estruturada em JSON (`stat.sh -o json`):

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

## Contribuição

Pull requests e sugestões de otimização são bem-vindos diretamente no repositório.

## Autor e Licença

Desenvolvido por **Percio Castelo** ([perciocastelo.com.br](https://perciocastelo.com.br)).

Licenciado sob a **Apache License 2.0** ([LICENSE](LICENSE)).
