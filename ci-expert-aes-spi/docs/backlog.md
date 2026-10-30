# Backlog — MiniSoC AES

Backlog atualizado conforme o cronograma revisado em 27/10/2026 (13 semanas, entregas às
sextas, encerramento em 29/01/2027, recesso de 21/12 a 03/01). A especificação funcional é o
Block Guide do MiniSoC AES v1.0.0. Atualizado a cada planejamento semanal; itens das semanas
distantes ficam mais abertos e são refinados quando a semana chega.

Legenda: `[ ]` a fazer · `[~]` em andamento (escrito, falta validar) · `[x]` concluído

---

## Fase 1 — Kick-off e ambiente (semana 1)

### Semana 1 — Kick-off, estudo e ambiente
- [x] Estruturar repositório (rtl/, tb/, formal/, syn/, upf/, docs/, scripts/)
- [x] Makefile com alvo único (`make sim`) para o fluxo mínimo
- [x] Exemplo mínimo compilando/simulando (prova de fluxo, não é o IP real)
- [x] Relatório de estudo: AES (FIPS-197) e SPI (modos CPOL/CPHA)
- [x] Estudo da arquitetura do sistema de topo (AES Top-Level System)
- [x] Backlog inicial (este arquivo)
- [x] `make sim` (PASS) e `make lint` (`+lint=all`) validados, inclusive em clone limpo
- [x] Commit, push e tag `w01-setup-v1.0`
- [ ] Confirmar com o instrutor: ferramenta de lint, PDK e especificação funcional

---

## Fase 2 — Desenvolvimento do RTL (semanas 2–7)

### Semana 2 — Desafio: SubBytes e ShiftRows (entrega 30/10)
- [x] `minisoc_aes_sbox`: 8 bits de entrada e de saída, combinacional (`rtl/minisoc_aes/`)
- [x] `minisoc_aes_sub_bytes`: estado de 128 bits com 16 instâncias da S-box
- [x] `minisoc_aes_shift_rows`: estado de 128 bits, só reordenação de fios
- [x] Convenção do estado: byte 0 em `[127:120]`, byte 15 em `[7:0]`
- [x] Testbench autoverificável (`tb/minisoc_aes/`): S-box nas 256 entradas e Apêndice B (rodadas 1 a 10)
- [x] Opcional: InvSubBytes e InvShiftRows, testadas como inversas
- [x] Rodar `make regress` no VCS (`sim_aes` com PASS e `lint_aes` sem erros)
- [x] Versionar `reports/sim_aes.rpt` e `reports/lint_aes.rpt`
- [x] Ler as seções 1 a 3 e 8 do Block Guide e registrar as dúvidas em `docs/reports/semana_02.md`
- [x] Preencher a tabela de resultados do VCS no relatório
- [x] Tag `w02-sbox-shiftrows-v1.0`

Nota: a tag `w02-arch-v1.0` pertence ao cronograma anterior (documentos de arquitetura, agora
rascunho). Não reutilizar.

### Semana 3 — Microarquitetura e transformações de rodada (entrega 06/11)
- [ ] Documento de microarquitetura v1.0 em `docs/architecture/`: diagrama de blocos interno, microarquitetura do AES, FSM do `minisoc_aes_top`
- [ ] Estratégia de CDC entre `spi_sclk` e `clk` por toggle (seção 5.3) e sequência de reset do domínio do sistema (seção 4.2)
- [ ] Revisar o rascunho de `docs/architecture/` contra o Block Guide e aproveitar o que servir
- [ ] MixColumns e AddRoundKey
- [ ] InvSubBytes, InvShiftRows e InvMixColumns (decifragem em ECB, CBC e PCBC)
- [ ] Testes unitários com o Apêndice B (cifragem) e o Apêndice C.1 (cifragem inversa)
- [ ] Lint sem erros
- [ ] Apresentar a microarquitetura ao verificador parceiro
- [ ] Defesa curta com o instrutor
- [ ] Tag da Semana 3

### Semana 4 — Expansão de chave e datapath AES-128 (entrega 13/11)
- [ ] `minisoc_aes_key_exp`: 11 round keys, pré-computada ou on-the-fly, com a escolha justificada (impacto em área e na decifragem)
- [ ] `minisoc_aes_dp`: cifra e cifra inversa de um bloco, com interface de controle (por exemplo, start/done)
- [ ] Testbench nos dois sentidos com os vetores do Apêndice B e do Apêndice C.1
- [ ] Lint sem erros

### Semana 5 — SPI front-end e PLL mock (entrega 20/11)
- [ ] `minisoc_spi` (seção 5): modo 0, MSB primeiro, frame de 40 bits; leitura em duas transações com NOP `0x3F`
- [ ] Recepção serial no domínio de `spi_sclk` e banco de registradores no domínio `clk`, com toggle para o frame completo
- [ ] Banco de registradores (seção 6): KEY, IV, COUNTER, NUM_BLOCKS, AES_CONTROL, AES_STATUS, VERSION, SYSTEM_CONTROL e SYSTEM_STATUS
- [ ] `minisoc_pll_mock` (seção 4.1): enable, `PLL_DIV_SEL` (/1, /2, /4, /8), `locked` após número pseudoaleatório de ciclos
- [ ] Testbench: escrita e leitura de todos os registradores via SPI e PLL até `PLL_LOCKED = 1` (passos 8 e 9 da seção 9)
- [ ] Relatório de lint

### Semana 6 — AES engine e memória compartilhada (entrega 27/11)
- [ ] `minisoc_memory` (seção 7): 1024 × 32 bits, porta única síncrona, sem reset, ownership por `MEM_SEL_AES`
- [ ] `minisoc_aes_top` (seção 8): captura de KEY, IV, COUNTER, MODE, DECRYPT e NUM_BLOCKS no START; quatro palavras por bloco, escrita in-place; BUSY, DONE, ERROR e BLOCKS_DONE
- [ ] Modos ECB, CBC e CTR, em cifragem e decifragem (PCBC, CFB e OFB ficam para a Semana 10; registrar como limitação conhecida)
- [ ] Detecção de configuração inválida (NUM_BLOCKS fora de 1..256 ou MODE reservado)
- [ ] Modelo de referência em software (por exemplo, script em Python) e testbench com 1, 2 e 256 blocos em cada modo

### Semana 7 — Integração do top-level e RTL v1.0 (entrega 04/12)
- [ ] `minisoc_top` com as interfaces de topo CLK, RESET, SPI e MEMORY DATA exatamente como no Block Guide (seção 3)
- [ ] Sequência de reset do domínio do sistema (seção 4.2)
- [ ] Teste de ponta a ponta com os 14 passos do modelo de programação (seção 9)
- [ ] Análise de CDC: `spi_sclk` × `clk`, `clk` × `sys_clk` e `mem_clk` × `sys_clk`
- [ ] Corrigir os problemas encontrados
- [ ] Tag `rtl-v1.0` e entrega ao verificador parceiro

---

## Fase 3 — Síntese inicial (semana 8)

### Semana 8 — Síntese (entrega 11/12)
- [ ] SDC: `clk`, `sys_clk` (gerado pelo PLL), `spi_sclk` e `mem_clk`, com grupos assíncronos declarados
- [ ] Tratar `minisoc_pll_mock` e `minisoc_memory` como caixas-pretas ou macros (conforme o instrutor)
- [ ] Síntese do RTL v1.0 com o PDK
- [ ] Relatório de baseline (área, timing e potência) e identificação de caminhos críticos

---

## Fase 4 — Verificação de equivalência (semana 9)

### Semana 9 — Formality (entrega 18/12)
- [ ] Fluxo no Formality: RTL (referência), netlist (implementação), bibliotecas do PDK e SVF gerado pela síntese
- [ ] PLL mock e memória como caixas-pretas, consistente com a síntese
- [ ] `match` e `verify`; depurar pontos não casados, não verificados ou não equivalentes
- [ ] Exercício de diagnóstico: alteração intencional no RTL ou na netlist
- [ ] Relatório de equivalência entre o RTL v1.0 e a netlist do baseline

Recesso de 21/12/2026 a 03/01/2027, sem entregas.

---

## Fase 5 — Fechamento funcional (semana 10)

### Semana 10 — RTL v1.1 (entrega 08/01)
- [ ] Modos PCBC, CFB e OFB, completando os seis modos da seção 8.2
- [ ] Corrigir os defeitos do verificador parceiro (inclui issues abertas no recesso)
- [ ] Nova síntese e nova equivalência sobre o RTL corrigido
- [ ] Tag `rtl-v1.1` e entrega ao verificador parceiro

---

## Fase 6 — Intenção de potência e baixo consumo (semanas 11–12)

### Semana 11 — Arquitetura de energia e UPF (entrega 15/01)
- [ ] Perfil de atividade, modos de operação, domínios de potência e tabela de estados (SPI, banco de registradores e PLL sempre ligados)
- [ ] Estratégias de isolamento e retenção e sequência de desligamento e religamento
- [ ] UPF, verificação estática e simulação power-aware do domínio do AES
- [ ] Documento de arquitetura de energia e defesa curta

### Semana 12 — Power gating, clock gating e RTL v2.0 (entrega 22/01)
- [ ] Controlador de energia e sequência de power gating, integrado ao banco de registradores
- [ ] Clock gating (ICG) nos pontos identificados e outras técnicas conforme a arquitetura aprovada
- [ ] Testbench das transições entre modos de energia
- [ ] Tag `rtl-v2.0` e entrega ao verificador parceiro (regressão funcional)

---

## Fase 7 — Síntese low power e encerramento (semana 13)

### Semana 13 (entrega 29/01)
- [ ] Síntese do RTL v2.0 com UPF e clock gating
- [ ] Comparação com o baseline: área, timing e potência por modo
- [ ] Equivalência no Formality entre o RTL v2.0 e a netlist low power
- [ ] Consolidar documentação, issues do verificador parceiro e repositório
- [ ] Apresentação final e release

---

## Backlog técnico contínuo

- [ ] Issues do verificador parceiro (classificar: defeito de RTL, defeito do ambiente de verificação ou ambiguidade de especificação)
- [ ] Ambiguidades de especificação a esclarecer (levar ao instrutor):
- [ ] Nomes de porta dos submódulos do datapath e nomes de MixColumns, AddRoundKey e das inversas
- [ ] Semente do PLL mock e como o verificador reproduz o número pseudoaleatório de ciclos
- [ ] Clock da MEMORY DATA IF e troca de ownership da memória
- [ ] Ferramenta de lint definitiva
- [ ] Significado de "reference flow" citado na atividade
- [ ] Existe rubrica de avaliação com pontuação e pesos?
