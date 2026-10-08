# Semana 1 — Kick-off, estudo e ambiente

## O que foi feito

- Estruturação inicial do repositório (rtl/, tb/, formal/, syn/, upf/, docs/, scripts/).
- Makefile com alvo único `make sim`, validado em ambiente limpo.
- Exemplo mínimo (`counter.sv` + `tb_counter.sv`) compilando e simulando via VCS,
  com self-check PASS/FAIL, para provar o fluxo antes do RTL real começar (Semana 3).
- Revisão do algoritmo AES (FIPS-197).
- Estudo do protocolo SPI: modos de operação, polaridade e fase de clock.

## AES — pontos revisados (FIPS-197)

- Estrutura geral: rodadas de SubBytes, ShiftRows, MixColumns, AddRoundKey;
  número de rodadas depende do tamanho da chave (10/12/14 para 128/192/256 bits).
- Expansão de chave (key schedule): geração das round keys a partir da chave original.
- Decifragem usa as transformações inversas (InvSubBytes, InvShiftRows,
  InvMixColumns) na ordem inversa — ponto que costuma gerar confusão na
  implementação em RTL se não houver atenção ao offset de rodada.
- Vetores de teste de referência do FIPS-197 serão a base do testbench
  dirigido a partir da Semana 4.

## SPI — protocolo

SPI é full-duplex, mestre-escravo, com 4 sinais: `SCLK`, `CS_N` (chip select,
ativo baixo), `MOSI` (master out, slave in) e `MISO` (master in, slave out).

### Modos de operação (CPOL / CPHA)

| Modo | CPOL | CPHA | Clock ocioso | Amostragem de dado |
|------|------|------|--------------|---------------------|
| 0    | 0    | 0    | Nível baixo  | Borda de subida (primeira borda) |
| 1    | 0    | 1    | Nível baixo  | Borda de descida (segunda borda) |
| 2    | 1    | 0    | Nível alto   | Borda de descida (primeira borda) |
| 3    | 1    | 1    | Nível alto   | Borda de subida (segunda borda) |

- **CPOL** (clock polarity) define o nível do clock em repouso (quando `CS_N`
  está inativo).
- **CPHA** (clock phase) define em qual borda do clock o dado é amostrado:
  na primeira borda de transição (CPHA=0) ou na segunda (CPHA=1).
- O modo a ser implementado pela interface SPI deste projeto será definido
  pela especificação funcional do instrutor — ponto de atenção para a
  Semana 2 (arquitetura), já que isso afeta diretamente a máquina de estados
  da interface.

### Ponto de atenção para a integração (Semana 5-6)

O domínio de clock do SPI (`SCLK`, tipicamente gerado pelo mestre externo,
podendo ser assíncrono ao clock do sistema) exige sincronização — os sinais
vindos do SPI (dado recebido, pulso de fim de transação) precisam atravessar
para o domínio do sistema com sincronizador de 2 flip-flops (ou FIFO
assíncrona, dependendo da taxa de dados), como já mapeado no cronograma do
projeto (Semana 5-6, verificação de CDC).

## Próximos passos

- Semana 2: definir diagrama de blocos, estratégia de clock/reset e
  microarquitetura do núcleo AES (iterativa por rodada vs. alternativas).
- Confirmar com o instrutor: PDK/ferramentas finais, especificação funcional
  detalhada, e modo SPI exato a ser implementado.
