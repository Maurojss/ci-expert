# Semana 2 — Desafio: S-box, SubBytes e ShiftRows

## O que foi feito

- RTL das três transformações pedidas, em `rtl/minisoc_aes/`: `minisoc_aes_sbox`,
  `minisoc_aes_sub_bytes` e `minisoc_aes_shift_rows`.
- Opcional: `minisoc_aes_inv_sbox`, `minisoc_aes_inv_sub_bytes` e `minisoc_aes_inv_shift_rows`,
  que a decifragem vai usar a partir da Semana 3. Os nomes das inversas seguem o padrão dos
  nomes obrigatórios e precisam ser conferidos com o Block Guide.
- Testbench autoverificável em `tb/minisoc_aes/tb_minisoc_aes_sub_shift.sv`, com 832 verificações.
- Gerador `scripts/gen_aes_vectors.py`: cria a S-box e os vetores de referência a partir do
  PDF do FIPS-197, com conferências antes de gravar os arquivos.
- Alvos novos no `Makefile`: `make sim_aes` (o único comando do desafio), `make lint_aes` e
  `make regress`. Os logs vão para `reports/` como `.rpt`, para serem versionados.
- Replanejamento: o cronograma foi revisado em 27/10 e a especificação passou a ser o Block Guide
  do MiniSoC AES. Os documentos de arquitetura escritos antes disso ficam como rascunho
  (histórico da tag `w02-arch-v1.0`) e serão refeitos na Semana 3.

## Convenção do estado

O estado tem 128 bits. O byte 0 fica em `state[127:120]` e o byte 15 em `state[7:0]`, na mesma
ordem do Block Guide (a Word 0 de um bloco é `[127:96]`). O byte `n` corresponde a `s[r][c]`,
com `r = n mod 4` e `c = n div 4`, e ocupa `state[127-8n -: 8]` (FIPS-197, seção 3.4).

## Módulos implementados

| Módulo | FIPS-197 | Função | Observação |
| --- | --- | --- | --- |
| `minisoc_aes_sbox` | 5.1.1, Figura 7 | Substitui um byte | Tabela de 256 entradas (`case`), gerada por script |
| `minisoc_aes_sub_bytes` | 5.1.1 | S-box nos 16 bytes do estado | 16 instâncias da S-box |
| `minisoc_aes_shift_rows` | 5.1.2 | Linha `r` deslocada de `r` posições à esquerda | Só reordenação de fios |
| `minisoc_aes_inv_sbox` | 5.3.2, Figura 14 | Substitui um byte pela S-box inversa | Opcional |
| `minisoc_aes_inv_sub_bytes` | 5.3.2 | S-box inversa nos 16 bytes | Opcional |
| `minisoc_aes_inv_shift_rows` | 5.3.1 | Linha `r` deslocada de `r` posições à direita | Opcional |

Todos são puramente combinacionais, com portas `state_in` e `state_out` de 128 bits (e `a` e `y`
de 8 bits na S-box).

### S-box

A tabela foi lida da Figura 7 do PDF e comparada com o cálculo direto (inverso em GF(2^8)
seguido da transformação afim), e as duas coincidem nas 256 entradas. Exemplos do enunciado:
`sbox(00) = 63` e `sbox(53) = ed`.

### ShiftRows

Pela equação (5.3), `s'[r,c] = s[r, (c + r) mod 4]`. O módulo liga o byte `r + 4*((c + r) % 4)`
da entrada ao byte `r + 4c` da saída. Na rodada 1 do Apêndice B, o estado depois do SubBytes,
`d42711aee0bf98f1b8b45de51e415230`, vira `d4bf5d30e0b452aeb84111f11e2798e5`.

## Testes

Rodar com `make sim_aes`. O testbench verifica:

| Verificação | Quantidade |
| --- | --- |
| S-box: as 256 entradas contra a Figura 7 | 256 |
| `sbox(00)` e `sbox(53)`, valores do enunciado | 2 |
| SubBytes, rodadas 1 a 10 do Apêndice B (`Start of Round` → `After SubBytes`) | 10 |
| ShiftRows, rodadas 1 a 10 (`After SubBytes` → `After ShiftRows`) | 10 |
| Cadeia SubBytes seguida de ShiftRows, rodadas 1 a 10 | 10 |
| Valores literais da rodada 1 do enunciado (SubBytes e ShiftRows) | 2 |
| Opcional: S-box inversa contra a Figura 14 | 256 |
| Opcional: `InvSubBytes(SubBytes(x)) = x` para os 256 bytes | 256 |
| Opcional: InvShiftRows, InvSubBytes e a cadeia inversa, rodadas 1 a 10 | 30 |
| **Total** | **832** |

O desafio pede pelo menos as rodadas 1 e 10. O testbench cobre as 10.

### Origem dos vetores

Os valores vêm de `tb/minisoc_aes/minisoc_aes_vectors.svh`, gerado por `scripts/gen_aes_vectors.py`.
Para não depender de digitação, o script confere os dados em três etapas e aborta se alguma falhar:

1. As S-boxes lidas do PDF são comparadas com o cálculo direto.
2. Um modelo AES-128 em Python é validado contra as 10 rodadas do Apêndice C.1 lidas do PDF.
3. O mesmo modelo gera as rodadas do Apêndice B, conferidas com o texto cifrado final do padrão
   (`3925841d02dc09fbdc118597196a0b32`), com os valores da rodada 1 e com as 30 matrizes impressas
   no Apêndice B do PDF.

## Resultados

### Conferência prévia (Verilator 5.020)

| Item | Resultado |
| --- | --- |
| Lint com `-Wall` nos quatro módulos de topo | Sem avisos |
| Simulação do testbench | `PASS: 832 checks de S-box, SubBytes e ShiftRows passaram` |
| Defeitos injetados (ShiftRows errado, uma entrada da S-box, InvShiftRows invertido, bytes do SubBytes trocados) | Os quatro foram detectados, com 21, 3, 20 e 21 falhas |

### Fluxo oficial (VCS)

### Fluxo oficial (VCS)

Execução realizada no servidor com o comando `make regress`:

| Alvo | Comando | Checks | Erros | Tempo (s) | Status |
| --- | --- | --- | --- | --- | --- |
| `sim_aes` | VCS X-2025.06-SP2 (`-sverilog -timescale=1ns/1ps -kdb`) | 832 | 0 | 0.390 | PASS |
| `lint_aes` (`minisoc_aes_sub_bytes`) | VCS `+lint=all,noVCDE` | N/A | 0 | 0.699 | PASS (sem latches) |
| `lint_aes` (`minisoc_aes_shift_rows`) | VCS `+lint=all,noVCDE` | N/A | 0 | 0.629 | PASS (sem latches) |
| `lint_aes` (`minisoc_aes_inv_sub_bytes`) | VCS `+lint=all,noVCDE` | N/A | 0 | 0.675 | PASS (sem latches) |
| `lint_aes` (`minisoc_aes_inv_shift_rows`) | VCS `+lint=all,noVCDE` | N/A | 0 | 0.633 | PASS (sem latches) |

Logs arquivados em `reports/sim_aes.rpt` e `reports/lint_aes.rpt`.

## Decisões e observações

- **S-box por `case`**, forma que a síntese interpreta com mais segurança. Com 16 instâncias no
  SubBytes (mais 4 na expansão de chave, na Semana 4), a área será avaliada na Semana 8.
- **Inversas incluídas**, embora opcionais, porque a decifragem (ECB, CBC e PCBC) as exige na
  Semana 3. O testbench confere que elas desfazem as transformações diretas.
- **Sem `timescale` no RTL.** O `Makefile` passa `-timescale=1ns/1ps` ao VCS, como no alvo `sim`.
- **Referência do padrão.** O PDF usado é o FIPS-197 de 2001, substituído pela FIPS 197-upd1
  (2023), que não muda o algoritmo.
- MixColumns e AddRoundKey ficam para a Semana 3, junto com InvMixColumns.

## Dúvidas sobre o Block Guide

Leitura das seções 1 a 3 e 8 ainda por fazer. As dúvidas abaixo vêm do enunciado do projeto e
devem ser complementadas depois da leitura.

- Os submódulos do datapath têm nomes de porta definidos no Block Guide? Foram usados `state_in`
  e `state_out`, escolhidos aqui.
- Quais são os nomes dos módulos de MixColumns, AddRoundKey e das transformações inversas?
- O PLL mock espera um número pseudoaleatório de ciclos até o `locked`. A semente é fixa? Como o
  verificador reproduz o mesmo comportamento?
- Qual é o clock da MEMORY DATA IF (`mem_clk`) e como é a troca de ownership da memória
  (`MEM_SEL_AES`)?
- Qual ferramenta de lint o instrutor adotará? O `+lint=all` do VCS é o que está em uso.

## Próximos passos

- Fechar a Semana 2: rodar `make regress` no VCS, preencher a tabela de resultados, versionar os
  `.rpt` e criar a tag `w02-sbox-shiftrows-v1.0` (entrega em 30/10).
- Ler as seções 1 a 3 e 8 do Block Guide e completar a lista de dúvidas.
- Semana 3 (06/11): documento de microarquitetura, MixColumns, AddRoundKey, InvMixColumns e
  testes com os Apêndices B e C.1. O rascunho de `docs/architecture/` será revisado contra o
  Block Guide.
