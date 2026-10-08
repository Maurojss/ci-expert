# Acelerador AES com interface SPI e baixo consumo

Projeto hands-on da trilha RTL Design — CIExpert.

## Setup rápido

```bash
git clone <url-do-repo>
cd <repo>
make sim
```

Isso compila e simula o exemplo mínimo (`rtl/example/counter.sv`), que existe
apenas para validar o fluxo do repositório nesta fase inicial. O IP real
(AES + SPI) começa a partir da Semana 3.

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
- Lint (ferramenta a definir conforme disponibilizado pelo instrutor)

## Status

- [x] Semana 1 — ambiente mínimo executando (`make sim`)
- [ ] Semana 2 — arquitetura e microarquitetura

Backlog completo em [`docs/backlog.md`](docs/backlog.md).
