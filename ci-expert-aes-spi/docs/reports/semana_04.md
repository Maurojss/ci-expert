# Semana 4 — Expansão de chave e datapath AES-128

## O que foi feito

- Implementação de `minisoc_aes_key_exp` (`rtl/minisoc_aes/minisoc_aes_key_exp.sv`): expansão de chave pré-computada iterativa que gera e armazena as 11 subchaves de 128 bits (`round_key` de 0 a 10) em 10 ciclos após o pulso de `start`, utilizando 4 instâncias de `minisoc_aes_sbox`.
- Implementação de `minisoc_aes_dp` (`rtl/minisoc_aes/minisoc_aes_dp.sv`): datapath iterativo de 128 bits (1 rodada por ciclo, 11 ciclos por bloco), suportando cifragem (`decrypt = 0`) e decifragem pela cifra inversa direta (`decrypt = 1`), integrando os blocos combinacionais das Semanas 2 e 3.
- Arquitetura de **testbenches modulares** conforme orientação de boas práticas de debug:
  - `tb/minisoc_aes/tb_minisoc_aes_key_exp.sv`: verifica isoladamente `minisoc_aes_key_exp` (33 verificações).
  - `tb/minisoc_aes/tb_minisoc_aes_dp.sv`: verifica isoladamente `minisoc_aes_dp` ciclo a ciclo nos dois sentidos (24 verificações).
  - `tb/minisoc_aes/tb_minisoc_aes_w04.sv`: topo integrador que instancia `u_tb_key_exp` e `u_tb_dp` (`STANDALONE = 0`) e roda os 57 checks em sequência.
- Novos alvos no `Makefile`: `make sim_key_exp`, `make sim_dp_unit`, `make sim_dp`, `make lint_dp` e atualização de `make regress`.
- Relatórios versionados em `reports/sim_dp.rpt` e `reports/lint_dp.rpt`.

## Justificativa de Arquitetura: Expansão de Chave Pré-computada

| Critério | Pré-computada (Escolhida) | On-the-fly (Descartada) |
| --- | --- | --- |
| **Armazenamento** | 11 × 128 bits = 1408 flip-flops | 1 × 128 bits = 128 flip-flops |
| **Suporte à Decifragem** | Leitura imediata de `rk_mem[10]` até `rk_mem[0]` por `round_idx` | Exige pré-avançar até a rodada 10 e implementar lógica reversa de KeySchedule |
| **Múltiplos Blocos (até 256)** | Calcula uma única vez no estado `KEYEXP` da FSM; amortiza 10 ciclos em até 256 blocos | Repete os cálculos e o chaveamento das S-boxes em todos os blocos |

## Testes Modulares e Cobertura

| Testbench | Escopo | Checks |
| --- | --- | --- |
| `tb_minisoc_aes_key_exp` | 11 subchaves do Apêndice B (leitura direta 0..10 e inversa 10..0) + 11 subchaves do Apêndice C.1 | 33 |
| `tb_minisoc_aes_dp` | Cifra do Apêndice B (10 estados intermediários + saída final + ida e volta) + Decifra do Apêndice C.1 (10 estados intermediários + saída final + ida e volta) | 24 |
| `tb_minisoc_aes_w04` | Execução hierárquica integrada (`u_tb_key_exp` + `u_tb_dp`) | **57** |

## Resultados no VCS

| Alvo | Comando | Checks | Erros | Tempo (s) | Status |
| --- | --- | --- | --- | --- | --- |
| `sim_dp` | VCS X-2025.06-SP2 (`tb_minisoc_aes_w04`) | 57 | 0 | 0.410 | PASS |
| `lint_dp` (`minisoc_aes_key_exp`) | VCS `+lint=all,noVCDE` | N/A | 0 | < 0.1 | PASS (sem latches) |
| `lint_dp` (`minisoc_aes_dp`) | VCS `+lint=all,noVCDE` | N/A | 0 | < 0.1 | PASS (sem latches) |

## Próximos Passos

- **Semana 5 (entrega 20/11):** implementar o front-end SPI (`rtl/minisoc_spi/minisoc_spi.sv`, Mode 0, MSB-first, frame de 40 bits e CDC por toggle) e o modelo RTL do PLL (`rtl/minisoc_pll/minisoc_pll_mock.sv`).
