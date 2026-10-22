# Interfaces dos Modelos Comportamentais — PLL e Memória (v1.0)

Documento de apoio ao [`arquitetura_v1.0.md`](arquitetura_v1.0.md).

Os modelos ficam em `models/`, fora do RTL sintetizável, e são usados nos testes iniciais.
Na segunda etapa da verificação, eles são substituídos pelos modelos da trilha de verificação,
que têm a **mesma interface**. Esta definição é uma **proposta**: nomes, portas, larguras e
parâmetros devem ser conferidos com o verificador parceiro (premissa A9) antes de serem
considerados finais.

---

## 1. Modelo do PLL

**Módulo:** `pll_model`

| Parâmetro | Padrão | Descrição |
| --- | --- | --- |
| `CFG_W` | 8 | Largura do barramento de configuração |
| `LOCK_CYCLES` | 16 | Ciclos de `clk_osc` até `locked` subir depois de um reset ou de uma reconfiguração |

| Porta | Direção | Largura | Descrição |
| --- | --- | --- | --- |
| `clk_osc` | entrada | 1 | Clock do oscilador (referência) |
| `rst_n` | entrada | 1 | Reset global, assíncrono, ativo baixo |
| `cfg` | entrada | `CFG_W` | Bits de configuração, vindos do `regbank` |
| `clk_out` | saída | 1 | Clock do sistema (`clk_sys`) |
| `locked` | saída | 1 | 1 = PLL travado na configuração atual |

### Bits de configuração (`cfg`)

| Bits | Campo | Significado |
| --- | --- | --- |
| 1:0 | `MULT` | `00` = ×1 (padrão), `01` = ×2, `10` = ×4, `11` = reservado (tratado como ×1) |
| 7:2 | — | Reservados. O modelo ignora; escreva 0 |

### Comportamento

1. Com `rst_n=0`: `locked=0` e a configuração volta ao padrão (`cfg` efetivo = `0x00`, ×1).
2. `clk_out` oscila **continuamente** na frequência da configuração vigente (premissa A5).
   O modelo mede o período de `clk_osc` para derivar `clk_out`.
3. Depois de `rst_n=1`, `locked` sobe `LOCK_CYCLES` ciclos de `clk_osc` depois.
4. Quando `cfg` muda: `locked` cai imediatamente; `LOCK_CYCLES` ciclos de `clk_osc` depois,
   `clk_out` passa para a nova frequência e `locked` sobe.
5. Modelo comportamental, não sintetizável. Na síntese e no Formality é tratado como caixa-preta.

---

## 2. Modelo da memória

**Módulo:** `mem_model` (dual-port, premissa A2)

| Parâmetro | Padrão | Descrição |
| --- | --- | --- |
| `ADDR_W` | 10 | Largura do endereço (profundidade `2**ADDR_W` palavras) |
| `DATA_W` | 128 | Largura da palavra (um bloco AES) |
| `LATENCY` | 1 | Ciclos entre a primeira borda com `req=1` e o `ack` (≥ 1) |

| Porta | Direção | Largura | Descrição |
| --- | --- | --- | --- |
| `clk` | entrada | 1 | `clk_sys` |
| `rst_n` | entrada | 1 | Reset, ativo baixo (o conteúdo não é apagado) |
| `a_req`, `a_we` | entrada | 1 | Porta A (núcleo AES): requisição e escrita |
| `a_addr` | entrada | `ADDR_W` | Porta A: endereço |
| `a_wdata` | entrada | `DATA_W` | Porta A: dado de escrita |
| `a_rdata` | saída | `DATA_W` | Porta A: dado de leitura |
| `a_ack` | saída | 1 | Porta A: acesso concluído |
| `b_req`, `b_we` | entrada | 1 | Porta B (MEMORY/DATA System): requisição e escrita |
| `b_addr` | entrada | `ADDR_W` | Porta B: endereço |
| `b_wdata` | entrada | `DATA_W` | Porta B: dado de escrita |
| `b_rdata` | saída | `DATA_W` | Porta B: dado de leitura |
| `b_ack` | saída | 1 | Porta B: acesso concluído |

### Comportamento

1. Protocolo de cada porta: o mestre mantém `req`, `we`, `addr` e `wdata` até amostrar
   `ack=1`. O `ack` dura um ciclo e ocorre `LATENCY` ciclos depois da primeira borda com
   `req=1`. Na leitura, `rdata` é válido no ciclo do `ack`. A escrita é efetivada na borda em
   que o `ack` é amostrado.
2. Conteúdo inicial: zero em todas as posições.
3. Escrita simultânea no mesmo endereço pelas duas portas: a porta A tem prioridade e o modelo
   emite um aviso.
4. Leitura numa porta com escrita simultânea no mesmo endereço pela outra: retorna o valor
   anterior à escrita.
5. Modelo comportamental, não sintetizável. Na síntese e no Formality é tratado como caixa-preta.

---

## 3. Pontos a alinhar com o verificador parceiro

| Ponto | Proposta | A conferir |
| --- | --- | --- |
| Nomes dos módulos | `pll_model`, `mem_model` | Nomes usados pelos modelos da verificação |
| Nomes e larguras das portas | Tabelas acima | Portas e larguras dos modelos da verificação |
| Significado de `cfg` | `MULT` em `[1:0]` | Codificação real do PLL da verificação |
| `LOCK_CYCLES` | 16 | Valor usado nos modelos da verificação |
| Memória | Dual-port, 128 bits, `LATENCY=1` | Número de portas, largura e latência |
| Reset da memória | Não apaga o conteúdo | Comportamento dos modelos da verificação |
