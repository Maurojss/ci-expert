# Mapa de Registradores — v1.0

Documento de apoio ao [`arquitetura_v1.0.md`](arquitetura_v1.0.md). Serve também de base ao
plano de verificação do verificador parceiro.

Registradores de 32 bits, endereçados por **palavra** (endereço de 7 bits). O endereço é
enviado no primeiro byte do quadro SPI (seção 7). `ADDR_W` é a largura do endereço de
memória (padrão 10, premissa A2 do documento de arquitetura).

---

## 1. Convenções

| Sigla | Significado |
| --- | --- |
| RO | Somente leitura. Escritas são ignoradas |
| RW | Leitura e escrita |
| WO | Somente escrita. A leitura retorna `0x00000000` |
| W1P | Escrever 1 gera um pulso de um ciclo. A leitura retorna 0 |
| RSV | Reservado. Escreva 0; a leitura retorna 0 |

Ordem dos bytes da chave: o registrador de menor índice guarda os bytes mais significativos,
como a chave aparece escrita no FIPS-197.

```
key[127:96] = KEY0   key[95:64] = KEY1   key[63:32] = KEY2   key[31:0] = KEY3
```

---

## 2. Visão geral

| Endereço | Nome | Acesso | Reset | Descrição |
| --- | --- | --- | --- | --- |
| `0x00` | `ID` | RO | `0xAE500001` | Identificação e versão. Também indica sistema pronto |
| `0x01` | `CTRL` | W1P | `0x00000000` | Comandos: iniciar e abortar |
| `0x02` | `STATUS` | RO | `0x00000000` | Estado do núcleo e do PLL |
| `0x03` | `PLL_CFG` | RW | `0x00000000` | Configuração do PLL |
| `0x04` | `KEY0` | WO | `0x00000000` | Chave, bits [127:96] |
| `0x05` | `KEY1` | WO | `0x00000000` | Chave, bits [95:64] |
| `0x06` | `KEY2` | WO | `0x00000000` | Chave, bits [63:32] |
| `0x07` | `KEY3` | WO | `0x00000000` | Chave, bits [31:0] |
| `0x08` | `SRC_ADDR` | RW | `0x00000000` | Endereço do primeiro bloco de entrada |
| `0x09` | `DST_ADDR` | RW | `0x00000000` | Endereço do primeiro bloco de saída |
| `0x0A` | `NBLOCKS` | RW | `0x00000000` | Número de blocos de 128 bits |
| `0x0B` | `BLK_CNT` | RO | `0x00000000` | Blocos concluídos |
| `0x0C` a `0x7F` | — | RSV | — | Escrita ignorada, leitura retorna 0 |

---

## 3. Campos

### `ID` (`0x00`)

`0xAE500001`: `0xAE50` identifica o IP, `0x0001` é a versão da arquitetura. Uma leitura que
retorna `0x00000000` significa que o sistema ainda não está pronto (PLL sem lock, ver seção 6).

### `CTRL` (`0x01`)

| Bits | Campo | Acesso | Descrição |
| --- | --- | --- | --- |
| 31:2 | — | RSV | Reservado |
| 1 | `SRST` | W1P | Aborta a operação e leva o núcleo ao estado ocioso, sem gerar `done`. Limpa `DONE` e `ERR` |
| 0 | `START` | W1P | Inicia a cifragem dos `NBLOCKS` blocos (seção 5) |

Se `START` e `SRST` forem escritos juntos, `SRST` tem prioridade.

### `STATUS` (`0x02`)

| Bits | Campo | Acesso | Descrição |
| --- | --- | --- | --- |
| 31:4 | — | RSV | Lê 0 |
| 3 | `ERR` | RO | Sticky. Comando recusado (seção 4) |
| 2 | `PLL_LOCKED` | RO | Reflete o `locked` do PLL, sincronizado em `clk_sys` |
| 1 | `DONE` | RO | Sticky. Todos os blocos foram cifrados e gravados |
| 0 | `BUSY` | RO | Operação em andamento |

### `PLL_CFG` (`0x03`)

| Bits | Campo | Acesso | Descrição |
| --- | --- | --- | --- |
| 31:8 | — | RSV | Reservado |
| 7:2 | — | RW | Reservados no modelo do PLL (escreva 0) |
| 1:0 | `MULT` | RW | Multiplicador de frequência: `00` = ×1 (padrão), `01` = ×2, `10` = ×4, `11` = reservado (tratado como ×1) |

O significado dos bits é o do modelo do PLL (`interfaces_modelos.md`) e deve ser alinhado
com o modelo da verificação.

### `KEY0` a `KEY3` (`0x04` a `0x07`)

Chave de 128 bits, somente escrita. A leitura retorna `0x00000000`.

### `SRC_ADDR` (`0x08`) e `DST_ADDR` (`0x09`)

| Bits | Campo | Acesso | Descrição |
| --- | --- | --- | --- |
| 31:`ADDR_W` | — | RSV | Reservado |
| `ADDR_W`-1:0 | `ADDR` | RW | Endereço de bloco (cada endereço guarda 128 bits) |

O bloco `i` é lido de `SRC_ADDR + i` e escrito em `DST_ADDR + i`. `SRC_ADDR = DST_ADDR` é
permitido.

### `NBLOCKS` (`0x0A`)

| Bits | Campo | Acesso | Descrição |
| --- | --- | --- | --- |
| 31:16 | — | RSV | Reservado |
| 15:0 | `N` | RW | Número de blocos. `0` faz o `START` ser recusado |

### `BLK_CNT` (`0x0B`)

| Bits | Campo | Acesso | Descrição |
| --- | --- | --- | --- |
| 31:16 | — | RSV | Lê 0 |
| 15:0 | `CNT` | RO | Blocos concluídos na operação atual ou na última. Zerado no `START` |

---

## 4. Regras de acesso

1. Escritas em registradores RO, em `0x0C` a `0x7F` e em bits RSV são **ignoradas**, sem
   sinalização.
2. Leituras de endereços reservados e de `KEY0..3` retornam `0x00000000`.
3. Com `BUSY=1`, escritas em `KEY0..3`, `SRC_ADDR`, `DST_ADDR`, `NBLOCKS` e `PLL_CFG` são
   **ignoradas** e `ERR` é setado. Isso mantém esses valores estáveis durante a operação.
4. Escrita em `PLL_CFG` com `PLL_LOCKED=0` é ignorada e `ERR` é setado.
5. `ERR` é limpo por um `START` válido ou por `SRST`.

---

## 5. Comportamento de START, DONE e ERR

| Situação | Efeito |
| --- | --- |
| `START` com `BUSY=0`, `PLL_LOCKED=1` e `NBLOCKS ≥ 1` | Dispara o núcleo. `DONE`, `ERR` e `BLK_CNT` são limpos. `BUSY` sobe em até 2 ciclos de `clk_sys` |
| `START` com `BUSY=1` | Ignorado. `ERR` é setado |
| `START` com `PLL_LOCKED=0` | Ignorado. `ERR` é setado |
| `START` com `NBLOCKS = 0` | Ignorado. `ERR` é setado |
| Cada bloco gravado na memória | `BLK_CNT` incrementa |
| Fim do último bloco | `DONE` é setado e `BUSY` cai |
| `SRST` | Núcleo volta ao estado ocioso. `DONE` e `ERR` são limpos. A memória não é alterada além dos blocos já gravados |

Uma leitura SPI posterior a um `START` só chega ao `regbank` depois do byte de endereço do
quadro seguinte, ou seja, pelo menos 8 períodos de `sclk`. Com `f_sys ≥ 4 × f_sclk`, isso são
pelo menos 32 ciclos de `clk_sys`, mais que os 2 ciclos do efeito do `START`.

---

## 6. Prontidão do sistema

Depois do reset, o `regbank` só existe quando o PLL trava (o `rst_sys_n` é liberado no primeiro
`locked`). Enquanto isso, o `spi_slave` devolve zeros em `miso` e descarta escritas. O mestre
lê `ID` até obter `0xAE500001`. A primeira leitura depois do lock pode ainda retornar zero; basta
repetir.

---

## 7. Quadro SPI de acesso

Modo 0, MSB primeiro. O primeiro byte é `{RW, addr[6:0]}`, com `RW=1` para escrita e `RW=0` para
leitura.

| Tipo | Quadro |
| --- | --- |
| Escrita | `{1, addr}` + 4 bytes de dado em `mosi` (40 bits) |
| Leitura | `{0, addr}` + 1 byte dummy + 4 bytes de dado em `miso` (48 bits) |

Exemplos:

- Escrever `KEY0` (`0x04`): primeiro byte `0x84`, depois os 4 bytes do dado.
- Ler `STATUS` (`0x02`): primeiro byte `0x02`, byte dummy, depois 4 bytes lidos em `miso`.

---

## 8. Sequência de uso (cifragem de blocos)

1. Ler `ID` até obter `0xAE500001`.
2. Opcional: escrever `PLL_CFG` e esperar `STATUS.PLL_LOCKED = 1`.
3. Pela MEMORY DATA IF, gravar os blocos de entrada a partir de `SRC` na memória.
4. Escrever `KEY0..3`, `SRC_ADDR`, `DST_ADDR` e `NBLOCKS`.
5. Escrever `CTRL.START = 1`.
6. Ler `STATUS` até `DONE = 1` (e conferir `ERR = 0`).
7. Pela MEMORY DATA IF, ler os blocos cifrados a partir de `DST`.

Exemplo com o vetor do Apêndice C.1 do FIPS-197:

| Item | Valor |
| --- | --- |
| `KEY0..3` | `0x00010203`, `0x04050607`, `0x08090A0B`, `0x0C0D0E0F` |
| `SRC_ADDR`, `DST_ADDR`, `NBLOCKS` | `0`, `1`, `1` |
| Memória[0] antes | `0x00112233445566778899AABBCCDDEEFF` |
| Memória[1] depois | `0x69C4E0D86A7B0430D8CDB78070B4C55A` |
