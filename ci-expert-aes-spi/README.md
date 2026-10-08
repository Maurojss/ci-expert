# Acelerador AES com interface SPI e baixo consumo

Projeto hands-on da trilha RTL Design — CIExpert.

## Setup rápido

No servidor, carregue as ferramentas Synopsys e rode a simulação:

```bash
git clone -b hands-on https://github.com/Maurojss/ci-expert.git
cd ci-expert/ci-expert-aes-spi
source /Tools/synopsys-scripts/snps.sh
make sim
```

O resultado esperado é `PASS: todos os checks do exemplo minimo passaram`.
A simulação compila e roda o exemplo mínimo (`rtl/example/counter.sv`), que existe
apenas para validar o fluxo do repositório nesta fase inicial. O IP real
(AES + SPI) começa a partir da Semana 3.

Alvos disponíveis:

| Comando | O que faz |
| --- | --- |
| `make sim` | Compila e simula o exemplo mínimo (VCS) |
| `make lint` | Roda o lint do VCS (`+lint=all`) no exemplo mínimo |
| `make clean` | Remove os artefatos gerados (`build/`) |
| `make help` | Lista os alvos |

## Estrutura

```
.
├── docs/
│   ├── spec/            # especificação funcional (fornecida pelo instrutor)
│   ├── architecture/     # arquitetura e arquitetura de energia
│   └── reports/          # relatórios semanais (semana_XX.md)
├── rtl/                  # código RTL
├── tb/                   # testbenches
├── formal/                # propriedades SVA e scripts de formal
├── syn/                   # SDC, scripts e relatórios de síntese
├── upf/                   # arquivos UPF e relatórios
└── scripts/                # automação do fluxo
```

## Requisitos de ferramenta

- Synopsys VCS (simulação)
- Lint do VCS (`+lint=all`); ferramenta de lint definitiva a confirmar com o instrutor

## Status

- [x] Semana 1 — ambiente mínimo executando (`make sim` e `make lint`); falta clone limpo e tag `w01-env-v1.0`
- [ ] Semana 2 — arquitetura e microarquitetura

Backlog completo em [`docs/backlog.md`](docs/backlog.md).