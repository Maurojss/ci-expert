# Semana 3 — Microarquitetura e transformações de rodada

## O que foi feito

- RTL de MixColumns, AddRoundKey e InvMixColumns em `rtl/minisoc_aes/`: `minisoc_aes_mix_columns`,
  `minisoc_aes_add_round_key` e `minisoc_aes_inv_mix_columns`. InvSubBytes e InvShiftRows já existiam, da
  Semana 2.
- Testbench autoverificável `tb/minisoc_aes/tb_minisoc_aes_round.sv`, com 84 verificações, que inclui o
  **AES-128 completo**: a cifragem do Apêndice B e a decifragem do Apêndice C.1, encadeando os módulos das
  Semanas 2 e 3.
- Gerador `scripts/gen_aes_round_vectors.py`: cria os vetores dos Apêndices B e C.1 a partir do PDF do
  FIPS-197, com conferências antes de gravar.
- Alvos novos no `Makefile`: `make sim_round`, `make lint_round`, e `make regress` atualizado. Os logs vão para
  `reports/` como `.rpt`.
- Rascunho do documento de microarquitetura (`docs/architecture/microarquitetura_v1.0.md`): diagrama de blocos,
  microarquitetura do AES, FSM do `minisoc_aes_top`, CDC e reset. As seções do Block Guide ainda não foram lidas,
  então os pontos que dependem delas estão marcados.

## Transformações implementadas

| Módulo | FIPS-197 | Função | Observação |
| --- | --- | --- | --- |
| `minisoc_aes_mix_columns` | 5.1.3 | Multiplica cada coluna por `(02 03 01 01 / 01 02 03 01 / 01 01 02 03 / 03 01 01 02)` em GF(2^8) | `xtime` e multiplicação por `{03}` |
| `minisoc_aes_inv_mix_columns` | 5.3.3 | Multiplica cada coluna por `(0e 0b 0d 09 / 09 0e 0b 0d / 0d 09 0e 0b / 0b 0d 09 0e)` | Constantes por encadeamento de `xtime` |
| `minisoc_aes_add_round_key` | 5.1.4 e 5.3.4 | XOR do estado com a chave da rodada | É a própria inversa; serve na cifra e na decifra |

Todos são combinacionais, com portas `state_in`, `state_out` e, no AddRoundKey, `round_key`, de 128 bits.

### MixColumns

Cada coluna `(s0, s1, s2, s3)` produz:

| Saída | Expressão |
| --- | --- |
| `s0'` | `2·s0 ^ 3·s1 ^ s2 ^ s3` |
| `s1'` | `s0 ^ 2·s1 ^ 3·s2 ^ s3` |
| `s2'` | `s0 ^ s1 ^ 2·s2 ^ 3·s3` |
| `s3'` | `3·s0 ^ s1 ^ s2 ^ 2·s3` |

A multiplicação por `{02}` é `xtime` (deslocamento à esquerda e XOR condicional com `{1b}`), e por `{03}` é
`xtime(x) ^ x`.

### InvMixColumns

Usa as constantes `{09}`, `{0b}`, `{0d}` e `{0e}`, obtidas por encadeamento de `xtime`:
`{09} = {08}^{01}`, `{0b} = {08}^{02}^{01}`, `{0d} = {08}^{04}^{01}`, `{0e} = {08}^{04}^{02}`.

## Testes

Rodar com `make sim_round`. O testbench verifica:

| Verificação | Quantidade |
| --- | --- |
| MixColumns, Apêndice B, rodadas 1 a 9 | 9 |
| MixColumns, seis colunas clássicas de teste | 6 |
| InvMixColumns, Apêndice B, rodadas 1 a 9 | 9 |
| InvMixColumns, seis colunas clássicas | 6 |
| `InvMixColumns(MixColumns(x)) = x`, rodadas 1 a 10 | 10 |
| InvMixColumns, Apêndice C.1 (`ik_add` → `istart` seguinte), rodadas 1 a 9 | 9 |
| AddRoundKey, cifragem (rodada 0, rodadas 1 a 9 e rodada 10) | 11 |
| AddRoundKey, cifragem inversa do Apêndice C.1 (rodadas 0 a 10) | 11 |
| `AddRoundKey(AddRoundKey(x,k),k) = x`, rodadas 1 a 10 | 10 |
| AES-128 completo: cifragem do Apêndice B | 1 |
| AES-128 completo: decifragem do Apêndice C.1 | 1 |
| Ida e volta: decifrar o resultado da cifragem do Apêndice B | 1 |
| **Total** | **84** |

### Origem dos vetores

Os valores vêm de `tb/minisoc_aes/minisoc_aes_round_vectors.svh`, gerado por `scripts/gen_aes_round_vectors.py`.
O script aborta se qualquer conferência falhar:

1. O modelo AES-128 em Python cifra o exemplo do Apêndice B e obtém o texto cifrado do padrão
   (`3925841d02dc09fbdc118597196a0b32`). Os estados `start`, `s_box`, `s_row`, `m_col` e as 11 chaves de
   rodada conferem com as matrizes impressas no PDF.
2. O modelo de cifragem inversa reproduz as 10 rodadas do Apêndice C.1 lidas do PDF (`istart`, `is_row`,
   `is_box`, `ik_sch`, `ik_add`) e termina no texto claro `00112233445566778899aabbccddeeff`.
3. Seis colunas clássicas do MixColumns (por exemplo `db135345` → `8e4da1bc`) coincidem com o modelo.

## Resultados

### Conferência prévia (Verilator 5.020)

| Item | Resultado |
| --- | --- |
| Lint com `-Wall` nos três módulos novos | Sem avisos |
| Simulação do testbench | `PASS: 84 checks de MixColumns, AddRoundKey e AES-128 completo passaram` |
| Testbench da Semana 2 após as mudanças | Continua com `PASS: 832 checks` |
| Defeitos injetados (xtime sem redução, `mul3` sem XOR, constante `0d` trocada, OR no lugar de XOR, bytes trocados no InvMixColumns) | Os cinco foram detectados, com 22, 26, 36, 34 e 34 falhas |

### Fluxo oficial (VCS)

Execução realizada no servidor com o comando `make regress`:

| Alvo | Comando | Checks | Erros | Tempo (s) | Status |
| --- | --- | --- | --- | --- | --- |
| `sim_round` | VCS X-2025.06-SP2 (`-sverilog -timescale=1ns/1ps -kdb`) | 84 | 0 | 0.390 | PASS |
| `lint_round` (`mix_columns`) | VCS `+lint=all,noVCDE` | N/A | 0 | 0.659 | PASS (sem latches) |
| `lint_round` (`inv_mix_columns`) | VCS `+lint=all,noVCDE` | N/A | 0 | 0.685 | PASS (sem latches) |
| `lint_round` (`add_round_key`) | VCS `+lint=all,noVCDE` | N/A | 0 | 0.614 | PASS (sem latches) |

Logs arquivados em `reports/sim_round.rpt` e `reports/lint_round.rpt`.

## Microarquitetura (resumo)

- **AES iterativo**, uma rodada por ciclo, estado de 128 bits (cerca de 11 ciclos por bloco).
- **Cifra inversa direta** na decifra, reaproveitando os módulos testados, com as chaves de rodada em ordem inversa.
- **Expansão de chave pré-computada** (decisão tentativa; fica para a Semana 4 com a área medida): a chave é usada em
  até 256 blocos por START e a decifra a consome ao contrário.
- **FSM do `minisoc_aes_top`**: `IDLE`, `CHECK`, `KEYEXP`, `RD`, `RUN`, `POST`, `WR`, `DONE` e `ERR`.
- **CDC por toggle e hold** entre `spi_sclk` e `clk`; BLOCKS_DONE em código Gray de `sys_clk` para `clk`.
- **Cuidado do CBC em decifra *in-place***: guardar o bloco cifrado antes de sobrescrevê-lo.
- **CTR usa só a cifragem**, inclusive quando DECRYPT = 1.

O detalhe está em `docs/architecture/microarquitetura_v1.0.md`.

## Dúvidas

- A FSM e a ordem dos estados do `minisoc_aes_top` já são fixadas pela seção 8 do Block Guide, ou ficam livres?
- Como o COUNTER é incrementado no modo CTR (largura e propagação entre `COUNTER_HI` e `COUNTER_LO`)?
- Como o Block Guide trata a troca do clock da memória na mudança de ownership, sem glitch?
- Qual é o valor de N ciclos de `sys_clk` da sequência de reset (seção 4.2)?
- Os nomes de porta dos submódulos do datapath e das inversas são fixados pelo Block Guide?

## Entrega ao verificador parceiro

- [ ] Enviar o documento de microarquitetura (depois de conferido com o Block Guide).
- [ ] Alinhar as dúvidas e ambiguidades do Block Guide e registrá-las como *issues*.

## Próximos passos

- Fechar a Semana 3: rodar `make regress` no VCS, preencher os resultados, versionar os `.rpt`, ler o Block Guide
  e ajustar a microarquitetura; depois, defesa e tag `w03-microarch-v1.0`.
