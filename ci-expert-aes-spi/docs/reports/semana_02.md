# Semana 2 — Arquitetura e microarquitetura

## O que foi feito

- Documento de arquitetura v1.0 (`docs/architecture/arquitetura_v1.0.md`): diagrama de
  blocos, interfaces de topo e internas, clock e reset, protocolo SPI e travessia de
  domínio, microarquitetura do AES, preparação para baixo consumo, registro de decisões.
- Mapa de registradores (`docs/architecture/mapa_de_registradores.md`).
- Interfaces dos modelos do PLL e da memória (`docs/architecture/interfaces_modelos.md`):
  nome do módulo, portas, larguras e significado dos bits de configuração.
- Interface do núcleo AES definida de forma independente do SPI, com porta de acesso à
  memória, para que o núcleo seja desenvolvido e testado antes dele (Semanas 3 e 4).
- Pasta `models/` criada para os modelos do PLL e da memória.

## Decisões principais

| Tema | Decisão | Motivo resumido |
| --- | --- | --- |
| Microarquitetura | Iterativa, 1 rodada por ciclo, 128 bits | Confere com o FIPS-197; núcleo ocioso favorece o baixo consumo |
| Chave e dados | Chave por registradores; blocos lidos e escritos pelo núcleo na memória | Diagrama e descrição da Semana 2 |
| Memória | Dual-port de 128 bits (porta A do AES, porta B do MEMORY/DATA System) | Dispensa arbitragem |
| Reset | `rst_sys_n` liberado no primeiro `locked`; `locked` só reinicia o núcleo depois | O `regbank` não perde `PLL_CFG` ao reconfigurar |
| PLL | `PLL_CFG` só com PLL travado e núcleo ocioso | "Só reprogramados depois do locked" |
| SPI e CDC | Modo 0, `sclk` com travessia por toggle e hold | Dados multibit estáveis por construção |

## Premissas a confirmar

Detalhes na seção 1 do documento de arquitetura (A1 a A10). As mais importantes:

1. Protocolo e **clock** da MEMORY DATA IF (A7). Ela é síncrona a `clk_sys`, que é um clock interno?
2. Nomes de portas e protocolos de topo conforme o RTL de referência da verificação (A9).
3. Interfaces dos modelos do PLL e da memória iguais às da verificação.
4. AES-128, somente cifragem, modo ECB (A3).

## Entrega ao verificador parceiro

- [ ] Enviar `arquitetura_v1.0.md`, `mapa_de_registradores.md` e `interfaces_modelos.md`.
- [ ] Pedir o RTL de referência (ou as portas) e as interfaces dos modelos do PLL e da memória.
- [ ] Listar as diferenças encontradas e registrar como *issues* ou ambiguidades.
- [ ] Combinar o canal para abrir as *issues* no repositório.
