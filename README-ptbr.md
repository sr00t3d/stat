# Network Connection Monitor (Stat)

Readme: [English](README.md)

![License](https://img.shields.io/github/license/sr00t3d/stat)
![Shell Script](https://img.shields.io/badge/shell-script-green)

<img width="700" src="stat-cover.webp" />

Um script Bash leve e eficiente para monitorar conexões de rede ativas em tempo real. Ele analisa o tráfego atual, agrupa conexões por porta e fornece feedback visual com código de cores baseado no volume de tráfego.

Ideal para administradores de sistemas identificarem rapidamente picos de tráfego, ataques DDoS ou uso anômalo de portas.

## 🚀 Funcionalidades

- Monitoramento em Tempo Real: Exibe conexões ativas (established) TCP e UDP.
- Top N Portas: Permite definir quantas portas exibir no ranking (padrão: 10).
- Modo Live (Watch): Suporta atualização automática com intervalo definível (como o comando `watch`).
- Alertas Visuais: Coloração dinâmica baseada na carga:
  - 🟢 Verde: Tráfego normal (< 20 conexões)
  - 🟠 Laranja: Tráfego moderado (20 - 50 conexões)
  - 🔴 Vermelho: Tráfego alto (> 50 conexões)
- Leve: Depende apenas de ferramentas nativas (`ss`, `awk`, `sort`, `uniq`).

## 📋 Pré-requisitos

Para executar este script, você precisa de:

- Sistema Operacional Linux/Unix.
- Acesso `Root/Sudo` (necessário para o comando `ss` listar todas as conexões).
- Pacotes padrão (geralmente já instalados): `iproute2` (para o `ss`), `gawk` ou `awk`.

## 📥 Instalação

Você pode baixar o script diretamente para o seu servidor:

```bash
wget https://raw.githubusercontent.com/percioandrade/netmonitor/main/stat.sh
chmod +x stat.sh
```

## ⚙️ Como Usar
O script deve ser executado com privilégios de superusuário.

**Execução Simples**

Mostra as top 10 portas com mais conexões e sai.

```bash
./stat.sh
```

**Monitoramento Contínuo (Live Mode)**
Atualiza a tela a cada 2 segundos (ideal para deixar rodando em uma tela secundária).

```bash
./stat.sh -i 2
```

**Personalizar Quantidade**
Mostra as top 20 portas.

```bash
./stat.sh -n 20
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
Porta      Total Conexões      
----------------------------------------
443        125                 <-- Vermelho (Alto Tráfego)
80         35                  <-- Laranja (Atenção)
22         4                   <-- Verde (Normal)
----------------------------------------
```

## ⚠️ Aviso Legal

> [!WARNING]
> Este software é fornecido "como está". Certifique-se sempre de testar primeiro em um ambiente de desenvolvimento. O autor não se responsabiliza por qualquer uso indevido, consequências legais ou impacto em dados causado por esta ferramenta.

## 📚 Tutorial Detalhado

Para um guia completo, passo a passo, sobre como importar arquivos gerados para o Thunderbird e solucionar problemas comuns de migração, confira meu artigo completo:

👉 [**Monitorando Rede com Stat**](https://perciocastelo.com.br/blog/monitor-network-with-stat.html)

## Licença 📄

Este projeto está licenciado sob a **GNU General Public License v3.0**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
