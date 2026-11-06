#!/usr/bin/env python3
"""Gera os vetores de referência da Semana 3 (MixColumns, AddRoundKey e transformações inversas).

Uso:
    python3 scripts/gen_aes_round_vectors.py caminho/para/fips-197.pdf

Saída (sobrescreve):
    tb/minisoc_aes/minisoc_aes_round_vectors.svh

Conferências antes de gravar (a geração aborta se alguma falhar):
  1. O modelo AES-128 (de gen_aes_vectors.py) cifra o exemplo do Apêndice B e produz o texto
     cifrado do padrão; as matrizes impressas no Apêndice B do PDF conferem com as do modelo.
  2. O modelo de cifragem inversa reproduz os valores do Apêndice C.1 lidos do PDF
     (istart, is_row, is_box, ik_sch, ik_add, ioutput) nas 10 rodadas.
  3. Seis colunas de teste conhecidas do MixColumns (a literatura as usa como casos clássicos)
     coincidem com o modelo.
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_aes_vectors as g  # noqa: E402

ROOT = g.ROOT


def inv_shift_rows(s):
    out = [0] * 16
    for c in range(4):
        for r in range(4):
            out[r + 4 * ((c + r) % 4)] = s[r + 4 * c]
    return out


INV_SBOX = [0] * 256
for _a in range(256):
    INV_SBOX[g.SBOX[_a]] = _a


def inv_mix_columns(s):
    out = []
    m = g.gf_mul
    for c in range(4):
        a = s[4 * c:4 * c + 4]
        out += [m(a[0], 14) ^ m(a[1], 11) ^ m(a[2], 13) ^ m(a[3], 9),
                m(a[0], 9) ^ m(a[1], 14) ^ m(a[2], 11) ^ m(a[3], 13),
                m(a[0], 13) ^ m(a[1], 9) ^ m(a[2], 14) ^ m(a[3], 11),
                m(a[0], 11) ^ m(a[1], 13) ^ m(a[2], 9) ^ m(a[3], 14)]
    return out


def xor(a, b):
    return [x ^ y for x, y in zip(a, b)]


def decrypt_trace(ct, key):
    rk = g.key_schedule(key)
    ik = [rk[10 - r] for r in range(11)]
    tr = {"iksch": ik, "istart": {}, "isrow": {}, "isbox": {}, "ikadd": {}}
    st = xor(ct, ik[0])
    for r in range(1, 11):
        tr["istart"][r] = st
        sr = inv_shift_rows(st)
        tr["isrow"][r] = sr
        sb = [INV_SBOX[b] for b in sr]
        tr["isbox"][r] = sb
        ka = xor(sb, ik[r])
        if r < 10:
            tr["ikadd"][r] = ka
            st = inv_mix_columns(ka)
        else:
            st = ka
    tr["out"] = st
    return tr


def parse_c1_inverse(txt):
    m = re.search(r"PLAINTEXT:\s+00112233445566778899aabbccddeeff\s*\nKEY:\s+000102030405060708090a0b0c0d0e0f\s*\n", txt)
    assert m, "bloco C.1 nao encontrado"
    sec = txt[m.end():]
    a = sec.index("INVERSE CIPHER (DECRYPT):")
    sec = sec[a:sec.index("EQUIVALENT INVERSE CIPHER (DECRYPT):")]
    return {(r.group(2), int(r.group(1))): r.group(3)
            for r in re.finditer(r"round\[\s*(\d+)\]\.(\w+)\s+([0-9a-f]{32})", sec)}


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    pdf = sys.argv[1]
    txt = g.pdftotext(pdf, True)
    hx, unhx = g.hx, g.unhx

    # 1. Apendice B: cifragem
    key_b, pt_b = unhx("2b7e151628aed2a6abf7158809cf4f3c"), unhx("3243f6a8885a308d313198a2e0370734")
    tb = g.encrypt_trace(pt_b, key_b)
    assert hx(tb["output"]) == "3925841d02dc09fbdc118597196a0b32"
    raw = g.pdftotext(pdf, False)
    a = [m.start() for m in re.finditer(r"Appendix B\s+.\s+Cipher Example", raw)][-1]
    c = [m.start() for m in re.finditer(r"Appendix C\s+.\s+Example Vectors", raw)][-1]
    lines = {l.strip() for l in raw[a:c].splitlines() if re.fullmatch(r"(?:[0-9a-f]{2} ){3}[0-9a-f]{2}", l.strip())}
    for kind, rng in (("start", range(1, 11)), ("sbox", range(1, 11)), ("srow", range(1, 11)), ("mcol", range(1, 10))):
        for r in rng:
            s = tb[kind][r]
            rows = [" ".join(f"{s[rr + 4 * cc]:02x}" for cc in range(4)) for rr in range(4)]
            assert all(x in lines for x in rows), f"Apendice B: {kind} rodada {r}"
    for r in range(0, 11):  # chaves de rodada: linhas "Round Key Value" tambem estao no apendice
        s = tb["ksch"][r]
        rows = [" ".join(f"{s[rr + 4 * cc]:02x}" for cc in range(4)) for rr in range(4)]
        assert all(x in lines for x in rows), f"Apendice B: chave de rodada {r}"
    print("Apendice B: start, s_box, s_row, m_col e chaves de rodada conferem com o PDF")

    # 2. Apendice C.1: cifragem inversa
    ci = parse_c1_inverse(txt)
    ct = unhx("69c4e0d86a7b0430d8cdb78070b4c55a")
    td = decrypt_trace(ct, unhx("000102030405060708090a0b0c0d0e0f"))
    assert hx(td["out"]) == ci[("ioutput", 10)] == "00112233445566778899aabbccddeeff"
    for r in range(0, 11):
        assert hx(td["iksch"][r]) == ci[("ik_sch", r)], f"ik_sch {r}"
    for r in range(1, 11):
        assert hx(td["istart"][r]) == ci[("istart", r)], f"istart {r}"
        assert hx(td["isrow"][r]) == ci[("is_row", r)], f"is_row {r}"
        assert hx(td["isbox"][r]) == ci[("is_box", r)], f"is_box {r}"
        if r < 10:
            assert hx(td["ikadd"][r]) == ci[("ik_add", r)], f"ik_add {r}"
    print("Apendice C.1 (cifragem inversa): 10 rodadas conferem com o PDF")

    # 3. colunas classicas do MixColumns
    cols = [("db135345", "8e4da1bc"), ("f20a225c", "9fdc589d"), ("01010101", "01010101"),
            ("c6c6c6c6", "c6c6c6c6"), ("d4d4d4d5", "d5d5d7d6"), ("2d26314c", "4d7ebdf8")]
    for cin, cout in cols:
        assert hx(g.mix_columns(unhx(cin) * 4)) == cout * 4, cin
        assert hx(inv_mix_columns(unhx(cout) * 4)) == cin * 4, cout

    # ---------- vetores para o testbench ----------
    o = ["// minisoc_aes_round_vectors.svh",
         "// Gerado por scripts/gen_aes_round_vectors.py a partir do FIPS-197 (Apendices B e C.1).",
         "// Incluido dentro de uma task do testbench. Nao editar a mao.", "",
         "// Apendice B (cifragem): chave 2b7e151628aed2a6abf7158809cf4f3c, texto 3243f6a8885a308d313198a2e0370734",
         f"b_input  = 128'h{hx(pt_b)};",
         f"b_output = 128'h{hx(tb['output'])};"]
    for r in range(0, 11):
        o.append(f"b_ksch[{r}] = 128'h{hx(tb['ksch'][r])};")
    for r in range(1, 11):
        o.append(f"b_start[{r}] = 128'h{hx(tb['start'][r])};")
        o.append(f"b_srow[{r}]  = 128'h{hx(tb['srow'][r])};")
        if r < 10:
            o.append(f"b_mcol[{r}]  = 128'h{hx(tb['mcol'][r])};")
    o += ["", "// Apendice C.1 (cifragem inversa): chave 000102030405060708090a0b0c0d0e0f",
          f"ci_input  = 128'h{hx(ct)};",
          f"ci_output = 128'h{hx(td['out'])};"]
    for r in range(0, 11):
        o.append(f"ci_iksch[{r}] = 128'h{hx(td['iksch'][r])};")
    for r in range(1, 11):
        o.append(f"ci_istart[{r}] = 128'h{hx(td['istart'][r])};")
        o.append(f"ci_isrow[{r}]  = 128'h{hx(td['isrow'][r])};")
        o.append(f"ci_isbox[{r}]  = 128'h{hx(td['isbox'][r])};")
        if r < 10:
            o.append(f"ci_ikadd[{r}]  = 128'h{hx(td['ikadd'][r])};")
    o += ["", "// colunas classicas do MixColumns (a mesma coluna repetida nas quatro colunas do estado)"]
    for i, (cin, cout) in enumerate(cols):
        o.append(f"col_in[{i}]  = 32'h{cin};")
        o.append(f"col_out[{i}] = 32'h{cout};")
    (ROOT / "tb/minisoc_aes/minisoc_aes_round_vectors.svh").write_text("\n".join(o) + "\n")
    print("Conferencias concluidas; vetores da Semana 3 gerados.")


if __name__ == "__main__":
    main()
