# Backlog — AES Top-Level System

Backlog atualizado conforme o documento do projeto (versão com equivalência formal no
Formality). Atualizado a cada planejamento semanal; itens das semanas distantes ficam mais
abertos e são refinados quando a semana chega.

Legenda: `[ ]` a fazer · `[~]` em andamento (rascunho a revisar) · `[x]` concluído

---

## Fase 1 — Especificação e arquitetura (semanas 1–2)

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

### Semana 2 — Arquitetura e microarquitetura
- [~] Diagrama de blocos e interfaces internas (`reg_if`, `mem_if`, interface do núcleo AES)
- [~] Interfaces de topo (GLOBAL RESET, clk from OSC, SPI IF, MEMORY DATA IF) — a confirmar com a especificação de topo
- [~] Mapa de registradores (`docs/architecture/mapa_de_registradores.md`)
- [~] Estratégia de clock e reset (RESET, PLL mockado, `locked`, travessia SPI ↔ sistema)
- [~] Interfaces dos modelos do PLL e da memória (`docs/architecture/interfaces_modelos.md`)
- [~] Microarquitetura do AES (escolhida: iterativa, 1 rodada por ciclo, 128 bits)
- [~] Interface do núcleo AES (controle e status, chave, acesso à memória)
- [~] Documento de arquitetura v1.0 (`docs/architecture/arquitetura_v1.0.md`)
- [ ] Tag `w02-arch-v1.0` 

---

## Fase 2 — Desenvolvimento do RTL (semanas 3–6)

### Semana 3 — Datapath das rodadas do AES
- [ ] Implementar SubBytes (S-box), ShiftRows, MixColumns e AddRoundKey
- [ ] Testes unitários com os valores por rodada do Apêndice C.1 do FIPS-197
- [ ] Lint sem erros

### Semana 4 — Expansão de chave e controle do núcleo
- [ ] Implementar a expansão de chave (on-the-fly)
- [ ] Implementar o controle do núcleo, incluindo a porta de memória (`RD`, `RUN`, `WR`)
- [ ] Testbench dirigido com os vetores do FIPS-197, com uma memória simples
- [ ] Lint sem erros

### Semana 5 — SPI, registradores, RESET e modelo do PLL
- [ ] Implementar `spi_slave` e `spi_sync` (travessia `sclk` ↔ `clk_sys`)
- [ ] Implementar o banco de registradores (incluindo `PLL_CFG`)
- [ ] Implementar o `reset_ctrl`
- [ ] Modelo comportamental do PLL em `models/` (configuração padrão, `clk_out`, `locked`, reconfiguração)
- [ ] Testbench: escrita e leitura de todos os registradores via SPI, sequência de reset e travamento do PLL
- [ ] Relatório de lint (sem erros; avisos justificados)

### Semana 6 — MEMORY/DATA System, integração e RTL v1.0
- [ ] Implementar o `mem_data_sys`
- [ ] Modelo comportamental da memória em `models/` e integração
- [ ] Integrar o top-level conforme a arquitetura do sistema de topo
- [ ] Teste de ponta a ponta: configuração via SPI, entrada pela MEMORY DATA IF, AES, saída pela MEMORY DATA IF
- [ ] Análise de CDC (`sclk` e `clk_sys`)
- [ ] Corrigir problemas da integração
- [ ] Tag `w06-rtl-v1.0` e entrega ao verificador parceiro

---

## Fase 3 — Síntese inicial (semana 7)

### Semana 7
- [ ] SDC: clock do PLL e `sclk` assíncronos entre si, entradas, saídas e caminhos de sincronização
- [ ] Tratar PLL e memória como caixas-pretas ou macros (conforme o instrutor)
- [ ] Síntese do RTL v1.0 com o PDK
- [ ] Relatório de área, timing e potência (baseline)
- [ ] Identificar caminhos críticos e construções não sintetizáveis

---

## Fase 4 — Verificação de equivalência (semanas 8–9)

### Semana 8 — RTL × netlist no Formality
- [ ] Gerar o SVF na síntese (`set_svf` antes do `compile_ultra`)
- [ ] Script do Formality: bibliotecas, RTL (referência), netlist (implementação) e SVF
- [ ] Tratar PLL e memória como caixas-pretas, consistente com a síntese
- [ ] `match` e `verify`; analisar pontos não casados, não verificados e não equivalentes
- [ ] Relatório de equivalência do baseline

### Semana 9 — Depuração e fechamento
- [ ] Depurar não equivalências e pontos não verificados
- [ ] Exercício de diagnóstico: inserir uma alteração no RTL ou na netlist e ver como o Formality aponta
- [ ] Corrigir defeitos, incluindo issues do verificador parceiro; nova síntese e nova equivalência
- [ ] Relatório consolidado de equivalência
- [ ] Tag `w09-rtl-v1.1`

---

## Fase 5 — Intenção de potência (semanas 10–11)

### Semana 10 — Arquitetura de energia
- [ ] Perfil de atividade (blocos ociosos e quando)
- [ ] Modos de operação (ativo, ocioso, desligado)
- [ ] Domínios de potência e power state table (RESET, PLL e SPI sempre ligados)
- [ ] Estratégia de isolamento e retenção
- [ ] Sequência de desligamento e religamento
- [ ] Documento de arquitetura de energia e defesa

### Semana 11 — UPF
- [ ] Escrever o UPF
- [ ] Verificação estática do UPF
- [ ] Simulação power-aware dos modos

---

## Fase 6 — Baixo consumo (semanas 12–14)

### Semana 12 — Power gating
- [ ] Controlador de energia e sequência de power gating
- [ ] Integração com o banco de registradores
- [ ] Testbench das transições entre modos

### Semana 13 — Clock gating e demais técnicas
- [ ] Clock gating (ICG) nos pontos identificados
- [ ] Outras técnicas (isolamento de operandos, redução de chaveamento)
- [ ] Tag `w13-rtl-v2.0` e entrega ao verificador parceiro (regressão funcional)

### Semana 14 — Síntese low power e comparação
- [ ] Síntese do RTL v2.0 com UPF e clock gating
- [ ] Comparação com o baseline: área, timing e potência por modo
- [ ] Equivalência no Formality entre o RTL v2.0 e a netlist low power, considerando UPF e clock gating

---

## Fase 7 — Encerramento (semana 15)

### Semana 15
- [ ] Consolidar a documentação técnica
- [ ] Consolidar issues do verificador parceiro e estado final
- [ ] Apresentação final
- [ ] Artigo técnico ou científico
- [ ] Organizar o release final do repositório

---

## Backlog técnico contínuo

- [ ] Issues do verificador parceiro (classificar: defeito de RTL, defeito do ambiente de verificação ou ambiguidade de especificação)
- [ ] Ambiguidades de especificação a esclarecer:
  - [ ] Protocolo e clock da MEMORY DATA IF
  - [ ] Nomes de portas e protocolos de topo (conforme o RTL de referência da verificação)
  - [ ] Interfaces dos modelos do PLL e da memória iguais às da verificação
  - [ ] Modo SPI e nomes dos sinais da SPI IF
  - [ ] Escopo do AES: cifragem apenas, ECB, 128 bits
  - [ ] Frequências alvo de `clk_sys` e `sclk`
  - [ ] Significado de "reference flow" citado na atividade
  - [ ] Existe rubrica de avaliação com pontuação e pesos?
