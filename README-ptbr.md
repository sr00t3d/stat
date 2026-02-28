# Network Connection Monitor (Stat)

Readme: [EN](README.md)

![License](https://img.shields.io/github/license/sr00t3d/stat) ![Shell Script](https://img.shields.io/badge/shell-script-green)

<img width="700" src="stat-cover.webp" />

Um script Bash leve e eficiente para monitorar conexões de rede ativas em tempo real. Ele analisa o tráfego atual, agrupa conexões por porta e fornece feedback visual com código de cores baseado no volume de tráfego.

Ideal para administradores de sistemas identificarem rapidamente picos de tráfego, ataques DDoS ou uso anômalo de portas.

## 🚀 Funcionalidades

- Monitoramento em Tempo Real: Exibe conexões ativas (established) TCP e UDP.
- Top N Portas: Permite definir quantas portas exibir no ranking (padrão: 10).
- Modo Live (Watch): Suporta atualização automática com intervalo definível (como o comando `watch`).
- Alertas Visuais: Coloração dinâmica baseada na carga:
  - Tráfego normal (< 20 conexões)
  - Tráfego moderado (20 - 50 conexões)
  - Tráfego alto (> 50 conexões)
- Leve: Depende apenas de ferramentas nativas (`ss`, `awk`, `sort`, `uniq`).

## 📋 Pré-requisitos

Para executar este script, você precisa de:

- Sistema Operacional Linux/Unix.
- Acesso `Root/Sudo` (necessário para o comando `ss` listar todas as conexões).
- Pacotes padrão (geralmente já instalados): `iproute2` (para o `ss`), `gawk` ou `awk`.

## 📥 Instalação

1. **Baixe o arquivo no servidor:**

```bash
curl -O https://raw.githubusercontent.com/sr00t3d/stat/refs/heads/main/stat.sh
```

2. **Dê permissão de execução:**

```bash
chmod +x stat.sh
```

3. **Execute o script:**

```bash
./stat.sh
```

## ⚙️ Como Usar
O script deve ser executado com privilégios de superusuário.

**Execução Simples**

Mostra as top 10 portas com mais conexões e sai.

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

**Monitoramento Contínuo (Live Mode)**

Atualiza a tela a cada 2 segundos (ideal para deixar rodando em uma tela secundária).

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

**Personalizar Quantidade**

Mostra as top 20 portas.

```bash
./stat.sh -n 20

[root@evy ~]# ./stat.sh -n 20
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

**Combinando Opções**

Mostra as top 5 portas e atualiza a cada 1 segundo.

```bash
sudo ./stat.sh -n 5 -i 1
```

## 📖 Opções de Comando

```bash
Flag         Descrição                                                      Padrão
-n [NUM]     Define o número de portas a serem exibidas no ranking.         10
-i [SEC]     Define o intervalo de atualização em segundos (loop infinito)  0 (Sem refresh)
-h           Exibe o menu de ajuda                                          -
```

## 🎨 Entendendo a Saída
O script classifica o tráfego da seguinte forma:

```bash
Data/Hora: 2026-02-13 14:30:00
Monitorando as TOP 10 portas por volume de conexão
----------------------------------------
Port       Total Connections       
----------------------------------------
443        125                 <-- Alto Tráfego
80         35                  <-- Atenção
22         4                   <-- Normal
----------------------------------------
```

## ⚠️ Aviso Legal

> [!WARNING]
> Este software é fornecido "tal como está". Certifique-se sempre de ter permissão explícita antes de executar. O autor não se responsabiliza por qualquer uso indevido, consequências legais ou impacto nos dados causados ​​por esta ferramenta.

## 📚 Detailed Tutorial

Para um guia completo, passo a passo, confira meu artigo completo:

👉 [**Monitorando Rede com Stat**](https://perciocastelo.com.br/blog/monitor-network-with-stat.html)

## Licença 📄

Este projeto está licenciado sob a **GNU General Public License v3.0**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.