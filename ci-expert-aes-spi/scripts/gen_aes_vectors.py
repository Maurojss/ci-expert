#!/usr/bin/env python3
"""Gera a S-box (RTL) e os vetores de referência (testbench) a partir do FIPS-197.

Uso:
    python3 scripts/gen_aes_vectors.py caminho/para/fips-197.pdf

Saídas (sobrescreve):
    rtl/minisoc_aes/minisoc_aes_sbox.sv
    rtl/minisoc_aes/minisoc_aes_inv_sbox.sv
    tb/minisoc_aes/minisoc_aes_vectors.svh

Como os valores são conferidos antes de serem gravados:
  1. A S-box e a S-box inversa lidas do PDF (Figuras 7 e 14) são comparadas com o cálculo
     direto (inverso em GF(2^8) mais transformação afim).
  2. Um modelo AES-128 em Python gera os estados de cada rodada. Ele é validado contra as
     10 rodadas do Apêndice C.1 lidas do PDF (start, s_box, s_row, m_col, k_sch).
  3. O mesmo modelo gera as rodadas do exemplo do Apêndice B, conferidas contra o texto
     cifrado final do padrão, contra os valores da rodada 1 (start, SubBytes, ShiftRows) e
     contra as matrizes impressas no Apêndice B do PDF.
Requer `pdftotext` (poppler). A geração aborta se qualquer conferência falhar.
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def pdftotext(pdf, layout):
    args = ["pdftotext"] + (["-layout"] if layout else []) + [pdf, "-"]
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def parse_table(txt, caption_regex):
    start = [m.start() for m in re.finditer(caption_regex, txt)][-1]
    rows = {}
    for line in txt[:start].splitlines()[-30:]:
        m = re.match(r"\s*([0-9a-f])\s+((?:[0-9a-f]{2}\s+){15}[0-9a-f]{2})\s*$", line)
        if m:
            rows[int(m.group(1), 16)] = [int(v, 16) for v in m.group(2).split()]
    assert sorted(rows) == list(range(16)), "tabela incompleta no PDF"
    return [rows[x][y] for x in range(16) for y in range(16)]


def gf_mul(a, b):
    p = 0
    for _ in range(8):
        if b & 1:
            p ^= a
        hi = a & 0x80
        a = (a << 1) & 0xFF
        if hi:
            a ^= 0x1B
        b >>= 1
    return p


def sbox_computed():
    out = []
    for a in range(256):
        inv = 0 if a == 0 else next(b for b in range(1, 256) if gf_mul(a, b) == 1)
        r = inv
        for i in range(1, 5):
            r ^= ((inv << i) | (inv >> (8 - i))) & 0xFF
        out.append(r ^ 0x63)
    return out


SBOX = sbox_computed()


def key_schedule(key):
    w = [list(key[4 * i:4 * i + 4]) for i in range(4)]
    rcon = 1
    for i in range(4, 44):
        t = list(w[i - 1])
        if i % 4 == 0:
            t = t[1:] + t[:1]
            t = [SBOX[b] for b in t]
            t[0] ^= rcon
            rcon = gf_mul(rcon, 2)
        w.append([w[i - 4][j] ^ t[j] for j in range(4)])
    return [sum((w[4 * r + c] for c in range(4)), []) for r in range(11)]


def shift_rows(s):
    return [s[r + 4 * ((c + r) % 4)] for c in range(4) for r in range(4)]


def mix_columns(s):
    out = []
    for c in range(4):
        a = s[4 * c:4 * c + 4]
        out += [gf_mul(a[0], 2) ^ gf_mul(a[1], 3) ^ a[2] ^ a[3],
                a[0] ^ gf_mul(a[1], 2) ^ gf_mul(a[2], 3) ^ a[3],
                a[0] ^ a[1] ^ gf_mul(a[2], 2) ^ gf_mul(a[3], 3),
                gf_mul(a[0], 3) ^ a[1] ^ a[2] ^ gf_mul(a[3], 2)]
    return out


def encrypt_trace(pt, key):
    rk = key_schedule(key)
    st = [p ^ k for p, k in zip(pt, rk[0])]
    tr = {"ksch": rk, "start": {}, "sbox": {}, "srow": {}, "mcol": {}}
    for r in range(1, 11):
        tr["start"][r] = st
        sb = [SBOX[b] for b in st]
        tr["sbox"][r] = sb
        sr = shift_rows(sb)
        tr["srow"][r] = sr
        if r < 10:
            mc = mix_columns(sr)
            tr["mcol"][r] = mc
            st = [a ^ b for a, b in zip(mc, rk[r])]
        else:
            st = [a ^ b for a, b in zip(sr, rk[r])]
    tr["output"] = st
    return tr


def hx(b):
    return "".join(f"{v:02x}" for v in b)


def unhx(s):
    return [int(s[i:i + 2], 16) for i in range(0, len(s), 2)]


def parse_c1(txt):
    m = re.search(r"PLAINTEXT:\s+00112233445566778899aabbccddeeff\s*\nKEY:\s+000102030405060708090a0b0c0d0e0f\s*\n", txt)
    assert m, "bloco C.1 (AES-128) nao encontrado"
    sec = txt[m.end():]
    sec = sec[:sec.index("INVERSE CIPHER (DECRYPT):")]
    return {(r.group(2), int(r.group(1))): r.group(3)
            for r in re.finditer(r"round\[\s*(\d+)\]\.(\w+)\s+([0-9a-f]{32})", sec)}


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    pdf = sys.argv[1]
    txt = pdftotext(pdf, True)

    # 1. tabelas do PDF x calculo direto
    sb = parse_table(txt, r"Figure 7\.\s+S-box: substitution")
    isb = parse_table(txt, r"Figure 14\.\s+Inverse S-box")
    assert sb == SBOX, "S-box do PDF diverge do calculo direto"
    assert all(isb[sb[a]] == a for a in range(256)), "S-box inversa do PDF nao inverte a S-box"
    assert sb[0x00] == 0x63 and sb[0x53] == 0xED and sb[0xFF] == 0x16

    # 2. modelo x Apendice C.1 do PDF (10 rodadas)
    c1 = parse_c1(txt)
    tr = encrypt_trace(unhx("00112233445566778899aabbccddeeff"), unhx("000102030405060708090a0b0c0d0e0f"))
    for r in range(0, 11):
        assert hx(tr["ksch"][r]) == c1[("k_sch", r)], f"k_sch {r}"
    for r in range(1, 11):
        assert hx(tr["start"][r]) == c1[("start", r)], f"start {r}"
        assert hx(tr["sbox"][r]) == c1[("s_box", r)], f"s_box {r}"
        assert hx(tr["srow"][r]) == c1[("s_row", r)], f"s_row {r}"
        if r < 10:
            assert hx(tr["mcol"][r]) == c1[("m_col", r)], f"m_col {r}"
    assert hx(tr["output"]) == c1[("output", 10)]

    # 3. Apendice B: modelo x texto cifrado e rodada 1 do padrao
    tb = encrypt_trace(unhx("3243f6a8885a308d313198a2e0370734"), unhx("2b7e151628aed2a6abf7158809cf4f3c"))
    assert hx(tb["output"]) == "3925841d02dc09fbdc118597196a0b32"
    assert hx(tb["start"][1]) == "193de3bea0f4e22b9ac68d2ae9f84808"
    assert hx(tb["sbox"][1]) == "d42711aee0bf98f1b8b45de51e415230"
    assert hx(tb["srow"][1]) == "d4bf5d30e0b452aeb84111f11e2798e5"

    # conferencia adicional contra as matrizes impressas no Apendice B do PDF. O texto extraido
    # nao preserva a ordem das matrizes, entao confere-se que TODAS as linhas de cada matriz
    # esperada (start, s_box, s_row das 10 rodadas) aparecem na secao do Apendice B.
    raw = pdftotext(pdf, False)
    a = [m.start() for m in re.finditer(r"Appendix B\s+.\s+Cipher Example", raw)][-1]
    c = [m.start() for m in re.finditer(r"Appendix C\s+.\s+Example Vectors", raw)][-1]
    lines = {l.strip() for l in raw[a:c].splitlines() if re.fullmatch(r"(?:[0-9a-f]{2} ){3}[0-9a-f]{2}", l.strip())}
    for kind in ("start", "sbox", "srow"):
        for r in range(1, 11):
            s = tb[kind][r]
            rows = [" ".join(f"{s[rr + 4 * cc]:02x}" for cc in range(4)) for rr in range(4)]
            assert all(x in lines for x in rows), f"Apendice B: matriz {kind} rodada {r} nao confere com o PDF"
    print("Apendice B: as 30 matrizes (start, s_box, s_row) conferem com o PDF")

    def sbox_rtl(modname, desc, table, gen):
        body = "\n".join(f"            8'h{a:02x}: y = 8'h{table[a]:02x};" for a in range(256))
        return f"""// {modname}.sv
// {desc}
// Combinacional. Gerado por scripts/gen_aes_vectors.py a partir do FIPS-197 ({gen}) e
// conferido contra o calculo direto em GF(2^8). Nao editar a mao.

module {modname} (
    input  logic [7:0] a,
    output logic [7:0] y
);

    always_comb begin
        y = 8'h00;
        case (a)
{body}
        endcase
    end

endmodule
"""
    (ROOT / "rtl/minisoc_aes/minisoc_aes_sbox.sv").write_text(
        sbox_rtl("minisoc_aes_sbox", "S-box do AES: substituicao de um byte.", sb, "Figura 7"))
    (ROOT / "rtl/minisoc_aes/minisoc_aes_inv_sbox.sv").write_text(
        sbox_rtl("minisoc_aes_inv_sbox", "S-box inversa do AES (InvSubBytes): substituicao de um byte.", isb, "Figura 14"))

    o = ["// minisoc_aes_vectors.svh",
         "// Gerado por scripts/gen_aes_vectors.py a partir do FIPS-197 (Figuras 7 e 14 e Apendice B).",
         "// Incluido dentro de uma task do testbench. Nao editar a mao.", "",
         "// S-box e S-box inversa de referencia"]
    o += [f"sbox_ref[{a}] = 8'h{sb[a]:02x};" for a in range(256)]
    o += [f"inv_sbox_ref[{a}] = 8'h{isb[a]:02x};" for a in range(256)]
    o += ["", "// Apendice B: chave 2b7e151628aed2a6abf7158809cf4f3c, texto 3243f6a8885a308d313198a2e0370734",
          "// start = Start of Round, sbox = After SubBytes, srow = After ShiftRows"]
    for r in range(1, 11):
        o.append(f"b_start[{r}] = 128'h{hx(tb['start'][r])};")
        o.append(f"b_sbox[{r}]  = 128'h{hx(tb['sbox'][r])};")
        o.append(f"b_srow[{r}]  = 128'h{hx(tb['srow'][r])};")
    (ROOT / "tb/minisoc_aes/minisoc_aes_vectors.svh").write_text("\n".join(o) + "\n")
    print("Conferencias concluidas; arquivos gerados.")


if __name__ == "__main__":
    main()
