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
apenas para validar o fluxo do repositório. O IP do MiniSoC AES começa na Semana 2, com a
S-box, o SubBytes e o ShiftRows em `rtl/minisoc_aes/` e o testbench em `tb/minisoc_aes/`
(`make sim_aes`).

Alvos disponíveis:

| Comando | O que faz |
| --- | --- |
| `make sim` | Compila e simula o exemplo mínimo (VCS) |
| `make lint` | Roda o lint do VCS (`+lint=all`) no exemplo mínimo |
| `make sim_aes` | Testbench de S-box, SubBytes e ShiftRows contra os vetores do FIPS-197 (VCS) |
| `make lint_aes` | Lint (`+lint=all`) de cada transformação do AES (VCS) |
| `make regress` | Roda `sim`, `lint`, `sim_aes` e `lint_aes` |
| `make clean` | Remove os artefatos gerados (`build/`) |
| `make help` | Lista os alvos |

## Estrutura

```
.
├── docs/
│   ├── spec/               # Block Guide do MiniSoC AES (fornecido)
│   ├── architecture/       # microarquitetura e arquitetura de energia
│   └── reports/            # relatórios semanais (semana_XX.md)
├── rtl/
│   ├── minisoc_aes/        # transformações do AES e, depois, datapath e engine
│   ├── minisoc_mem/        # memória (Semana 6)
│   ├── minisoc_pll/        # PLL mock (Semana 5)
│   ├── minisoc_spi/        # SPI (Semana 5)
│   └── minisoc_top.sv      # top-level (Semana 7)
├── tb/                     # testbenches e modelo de referência
├── reports/                # relatórios de simulação e lint (.rpt), versionados
├── formal/                 # scripts e relatórios do Formality
├── syn/                    # SDC, scripts e relatórios de síntese
├── upf/                    # arquivos UPF e relatórios
└── scripts/                # automação (gen_aes_vectors.py gera a S-box e os vetores do FIPS-197)
```

## Requisitos de ferramenta

- Synopsys VCS (simulação)
- Lint do VCS (`+lint=all`); ferramenta de lint definitiva a confirmar com o instrutor

## Status

- [x] Semana 1 — ambiente mínimo executando (`make sim` e `make lint`); tag `w01-setup-v1.0`
- [~] Semana 2 — desafio S-box, SubBytes e ShiftRows (`make sim_aes` e `make lint_aes`)

Backlog completo em [`docs/backlog.md`](docs/backlog.md).