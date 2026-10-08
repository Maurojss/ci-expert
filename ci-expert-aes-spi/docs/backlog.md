# Backlog — Acelerador AES + SPI

Backlog inicial, atualizado a cada planejamento semanal (início da semana,
conforme o ritmo definido no projeto). Itens das semanas distantes ficam
propositalmente mais abertos — são refinados quando a semana chega.

Legenda: `[ ]` a fazer · `[~]` em andamento · `[x]` concluído

---

## Fase 1 — Especificação e arquitetura (semanas 1–2)

### Semana 1 — Kick-off, estudo e ambiente
- [x] Estruturar repositório (rtl/, tb/, formal/, syn/, upf/, docs/, scripts/)
- [x] Makefile com alvo único (`make sim`) para o fluxo mínimo
- [x] Exemplo mínimo compilando/simulando (prova de fluxo, não é o IP real)
- [x] Relatório de estudo: AES (FIPS-197, revisão) e SPI (modos CPOL/CPHA)
- [x] Backlog inicial (este arquivo)
- [x] `make sim` compilando e passando com VCS (PASS no testbench do exemplo)
- [x] `make lint` rodando sem avisos (VCS, `+lint=all`)
- [x] Estrutura achatada (Makefile em `ci-expert-aes-spi/`)
- [x] Commit e push na branch `hands-on`
- [x] Remover a pasta `classes/` da branch
- [x] Atualizar o README com o setup real (branch, subpasta, `source /Tools/synopsys-scripts/snps.sh`)
- [x] Registrar no relatório da semana o diagrama top-level e as dúvidas de arquitetura
- [x] Validar `make sim` em clone limpo
- [x] Tag `w01-setup-v1.0` (criar só depois do clone limpo passar)
- [ ] Confirmar com o instrutor: ferramenta de lint, PDK e especificação funcional detalhada

### Semana 2 — Arquitetura e microarquitetura
- [ ] Diagrama de blocos (RESET, PLL mockado, SPI, AES, memória/data system, banco de registradores se existir, controlador de energia)
- [ ] Definir interfaces entre módulos (sinais, larguras, protocolo interno)
- [ ] Estratégia de clock e reset, incluindo `locked` do PLL e travessia SPI ↔ sistema
- [ ] Escolher microarquitetura do AES (iterativa por rodada vs. alternativa) e justificar
- [ ] Definir interface do núcleo AES isoladamente (chave, dado, start, done, result)
- [ ] Mapa de registradores (endereços, campos de controle/status/chave/dado)
- [ ] Documento de arquitetura v1.0 (docs/architecture/)
- [ ] Apresentar arquitetura ao verificador parceiro
- [ ] Defesa curta com o instrutor

---

## Fase 2 — Desenvolvimento do RTL (semanas 3–6)

### Semana 3 — Datapath das rodadas do AES
- [ ] Implementar SubBytes (S-box)
- [ ] Implementar ShiftRows
- [ ] Implementar MixColumns
- [ ] Implementar AddRoundKey
- [ ] Testes unitários de cada transformação com valores intermediários do FIPS-197

### Semana 4 — Expansão de chave e controle do núcleo
- [ ] Implementar key expansion (key schedule)
- [ ] Implementar FSM de controle do núcleo (sequenciamento de rodadas, start/done)
- [ ] Testbench dirigido com vetores de teste oficiais do FIPS-197
- [ ] Confirmar: cifragem apenas, ou também decifragem (depende da spec do instrutor)

### Semana 5 — SPI e banco de registradores
- [ ] Implementar interface SPI (modo definido na Semana 2)
- [ ] Implementar sincronizador de domínio de clock (SPI → sistema)
- [ ] Implementar banco de registradores
- [ ] Testbench dirigido: escrita/leitura de registradores via SPI
- [ ] Relatório de lint do subsistema

### Semana 6 — Integração e RTL v1.0
- [ ] Integrar top-level: SPI ↔ registradores ↔ AES
- [ ] Teste ponta a ponta (carregar chave/dado via SPI, disparar, ler resultado)
- [ ] Análise de CDC completa
- [ ] Corrigir problemas encontrados na integração
- [ ] Tag `w06-rtl-v1.0`
- [ ] Entregar ao verificador parceiro

---

## Fase 3 — Síntese inicial (semana 7)

### Semana 7
- [ ] Escrever SDC (clocks, I/O, relações entre domínios)
- [ ] Síntese do RTL v1.0 com a biblioteca do PDK
- [ ] Relatório de área, timing e potência (baseline)
- [ ] Identificar caminhos críticos e construções não sintetizáveis

---

## Fase 4 — Verificação formal (semanas 8–9)

### Semana 8 — Propriedades
- [ ] Plano de propriedades (o que provar e por quê)
- [ ] Assertions SVA: protocolo SPI, acesso a registradores, FSMs, handshakes
- [ ] Rodar verificação formal, analisar contraexemplos

### Semana 9 — Fechamento e equivalência
- [ ] Corrigir defeitos da semana 8 e issues do verificador parceiro
- [ ] Ampliar propriedades e cobertura (covers)
- [ ] Equivalência lógica (LEC) RTL × netlist
- [ ] Tag `w09-rtl-v1.1`

---

## Fase 5 — Intenção de potência (semanas 10–11)

### Semana 10 — Arquitetura de energia
- [ ] Mapear perfil de atividade (blocos ociosos e quando)
- [ ] Definir modos de operação (ativo/ocioso/desligado)
- [ ] Domínios de potência e power state table
- [ ] Estratégia de isolamento e retenção
- [ ] Sequência de desligamento/religamento
- [ ] Documento de arquitetura de energia + defesa

### Semana 11 — UPF
- [ ] Escrever UPF (domínios, redes, power switches, isolamento, retenção, level shifters se necessário)
- [ ] Verificação estática do UPF
- [ ] Simulação power-aware dos modos

---

## Fase 6 — Baixo consumo (semanas 12–14)

### Semana 12 — Power gating
- [ ] Controlador de energia + sequência de power gating
- [ ] Integrar controlador com banco de registradores
- [ ] Testbench para transições entre modos

### Semana 13 — Clock gating e demais técnicas
- [ ] Clock gating (ICG) nos pontos identificados
- [ ] Outras técnicas (isolamento de operandos, redução de chaveamento)
- [ ] Atualizar propriedades formais para novos modos
- [ ] Tag `w13-rtl-v2.0`
- [ ] Entregar ao verificador parceiro (regressão)

### Semana 14 — Síntese low power e comparação
- [ ] Síntese do RTL v2.0 com UPF (incluindo clock gating automático)
- [ ] Comparar com baseline (semana 7): área, timing, potência por modo
- [ ] Reexecutar verificação formal e equivalência com UPF

---

## Fase 7 — Encerramento (semana 15)

### Semana 15
- [ ] Consolidar documentação técnica
- [ ] Consolidar issues do verificador parceiro e estado final
- [ ] Apresentação final
- [ ] Artigo técnico/científico
- [ ] Organizar release final do repositório

---

## Backlog técnico contínuo (não datado, surge ao longo do projeto)

- [ ] Issues reportadas pelo verificador parceiro (classificar: defeito de RTL / defeito do ambiente de verificação / ambiguidade de spec)
- [ ] Ambiguidades de especificação a esclarecer com o instrutor:
  - [ ] Chave e dado de entrada vêm pelo SPI ou pela memória?
  - [ ] Existe banco de registradores entre o SPI e o AES, ou o SPI é a interface de controle direta?
  - [ ] O PLL mockado é fornecido pelo instrutor ou precisa ser modelado?
  - [ ] Qual é o protocolo da interface de memória (Memory Data IF)?
  - [ ] Existe rubrica de avaliação com pontuação e pesos?