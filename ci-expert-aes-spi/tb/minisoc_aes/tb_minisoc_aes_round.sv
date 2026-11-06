// tb_minisoc_aes_round.sv
// Testbench autoverificavel da Semana 3: MixColumns, AddRoundKey, InvMixColumns e a
// composicao das transformacoes em AES-128 completo, contra os valores do FIPS-197.
//
// Verifica:
//   1. MixColumns, Apendice B, rodadas 1 a 9 (After ShiftRows -> After MixColumns) e seis
//      colunas classicas de teste.
//   2. InvMixColumns: inverso dos mesmos vetores e InvMixColumns(MixColumns(x)) = x;
//      Apendice C.1 (cifragem inversa), rodadas 1 a 9 (ik_add -> istart seguinte).
//   3. AddRoundKey: rodada 0 e rodadas 1 a 10 do Apendice B; rodadas da cifragem inversa
//      do Apendice C.1; propriedade AddRoundKey(AddRoundKey(x,k),k) = x.
//   4. Cifragem completa do Apendice B e decifragem completa do Apendice C.1, encadeando
//      os modulos das Semanas 2 e 3 (SubBytes, ShiftRows, MixColumns, AddRoundKey e as
//      inversas), com o resultado final comparado ao texto cifrado e ao texto claro do padrao.
//
// Os vetores vem de minisoc_aes_round_vectors.svh, gerado por scripts/gen_aes_round_vectors.py.
// Todos os DUTs sao combinacionais.

`timescale 1ns/1ps

module tb_minisoc_aes_round;

    // ---------------- DUTs ----------------
    logic [127:0] sub_in, sub_out, shr_in, shr_out, mix_in, mix_out;
    logic [127:0] isub_in, isub_out, ishr_in, ishr_out, imix_in, imix_out;
    logic [127:0] ark_in, ark_key, ark_out;

    minisoc_aes_sub_bytes          u_sub  (.state_in(sub_in),  .state_out(sub_out));
    minisoc_aes_shift_rows         u_shr  (.state_in(shr_in),  .state_out(shr_out));
    minisoc_aes_mix_columns        u_mix  (.state_in(mix_in),  .state_out(mix_out));
    minisoc_aes_inv_sub_bytes      u_isub (.state_in(isub_in), .state_out(isub_out));
    minisoc_aes_inv_shift_rows     u_ishr (.state_in(ishr_in), .state_out(ishr_out));
    minisoc_aes_inv_mix_columns    u_imix (.state_in(imix_in), .state_out(imix_out));
    minisoc_aes_add_round_key      u_ark  (.state_in(ark_in), .round_key(ark_key), .state_out(ark_out));

    // ---------------- Vetores de referencia ----------------
    logic [127:0] b_input, b_output, ci_input, ci_output;
    logic [127:0] b_ksch   [0:10];
    logic [127:0] b_start  [1:10];
    logic [127:0] b_srow   [1:10];
    logic [127:0] b_mcol   [1:9];
    logic [127:0] ci_iksch [0:10];
    logic [127:0] ci_istart[1:10];
    logic [127:0] ci_isrow [1:10];
    logic [127:0] ci_isbox [1:10];
    logic [127:0] ci_ikadd [1:9];
    logic [31:0]  col_in   [0:5];
    logic [31:0]  col_out  [0:5];

    task automatic load_vectors();
        `include "minisoc_aes_round_vectors.svh"
    endtask

    // ---------------- Verificacao ----------------
    int checks;
    int errors;

    task automatic check128(input string name, input int rnd, input logic [127:0] got, input logic [127:0] exp);
        checks++;
        if (got !== exp) begin
            errors++;
            $display("FAIL [%s %0d]: obtido %032h, esperado %032h", name, rnd, got, exp);
        end
    endtask

    // Passos combinacionais: aplica a entrada, espera o DUT assentar e devolve a saida.
    task automatic do_sub (input logic [127:0] x, output logic [127:0] y); sub_in  = x; #1; y = sub_out;  endtask
    task automatic do_shr (input logic [127:0] x, output logic [127:0] y); shr_in  = x; #1; y = shr_out;  endtask
    task automatic do_mix (input logic [127:0] x, output logic [127:0] y); mix_in  = x; #1; y = mix_out;  endtask
    task automatic do_isub(input logic [127:0] x, output logic [127:0] y); isub_in = x; #1; y = isub_out; endtask
    task automatic do_ishr(input logic [127:0] x, output logic [127:0] y); ishr_in = x; #1; y = ishr_out; endtask
    task automatic do_imix(input logic [127:0] x, output logic [127:0] y); imix_in = x; #1; y = imix_out; endtask
    task automatic do_ark (input logic [127:0] x, input logic [127:0] k, output logic [127:0] y);
        ark_in = x; ark_key = k; #1; y = ark_out;
    endtask

    logic [127:0] t, st;

    initial begin
        checks = 0;
        errors = 0;
        sub_in = '0; shr_in = '0; mix_in = '0; isub_in = '0; ishr_in = '0; imix_in = '0;
        ark_in = '0; ark_key = '0;
        load_vectors();

        // 1. MixColumns
        for (int r = 1; r <= 9; r++) begin
            do_mix(b_srow[r], t);
            check128("MixColumns", r, t, b_mcol[r]);
        end
        for (int i = 0; i < 6; i++) begin
            do_mix({4{col_in[i]}}, t);
            check128("MixColumns coluna", i, t, {4{col_out[i]}});
        end

        // 2. InvMixColumns
        for (int r = 1; r <= 9; r++) begin
            do_imix(b_mcol[r], t);
            check128("InvMixColumns", r, t, b_srow[r]);
        end
        for (int i = 0; i < 6; i++) begin
            do_imix({4{col_out[i]}}, t);
            check128("InvMixColumns coluna", i, t, {4{col_in[i]}});
        end
        for (int r = 1; r <= 10; r++) begin
            do_mix(b_start[r], t);
            do_imix(t, st);
            check128("InvMixColumns(MixColumns)", r, st, b_start[r]);
        end
        for (int r = 1; r <= 9; r++) begin
            do_imix(ci_ikadd[r], t);
            check128("InvMixColumns C.1", r, t, ci_istart[r+1]);
        end

        // 3. AddRoundKey
        do_ark(b_input, b_ksch[0], t);
        check128("AddRoundKey", 0, t, b_start[1]);
        for (int r = 1; r <= 9; r++) begin
            do_ark(b_mcol[r], b_ksch[r], t);
            check128("AddRoundKey", r, t, b_start[r+1]);
        end
        do_ark(b_srow[10], b_ksch[10], t);
        check128("AddRoundKey", 10, t, b_output);
        do_ark(ci_input, ci_iksch[0], t);
        check128("AddRoundKey C.1", 0, t, ci_istart[1]);
        for (int r = 1; r <= 9; r++) begin
            do_ark(ci_isbox[r], ci_iksch[r], t);
            check128("AddRoundKey C.1", r, t, ci_ikadd[r]);
        end
        do_ark(ci_isbox[10], ci_iksch[10], t);
        check128("AddRoundKey C.1", 10, t, ci_output);
        for (int r = 1; r <= 10; r++) begin
            do_ark(b_start[r], b_ksch[r], t);
            do_ark(t, b_ksch[r], st);
            check128("AddRoundKey(AddRoundKey)", r, st, b_start[r]);
        end

        // 4a. Cifragem completa do Apendice B
        do_ark(b_input, b_ksch[0], st);
        for (int r = 1; r <= 10; r++) begin
            do_sub(st, t);
            do_shr(t, st);
            if (r < 10) begin
                do_mix(st, t);
                st = t;
            end
            do_ark(st, b_ksch[r], t);
            st = t;
        end
        check128("Cifra completa (Apendice B)", 10, st, b_output);

        // 4b. Decifragem completa do Apendice C.1
        do_ark(ci_input, ci_iksch[0], st);
        for (int r = 1; r <= 10; r++) begin
            do_ishr(st, t);
            do_isub(t, st);
            do_ark(st, ci_iksch[r], t);
            st = t;
            if (r < 10) begin
                do_imix(st, t);
                st = t;
            end
        end
        check128("Decifra completa (C.1)", 10, st, ci_output);

        // 4c. Ida e volta: decifrar o resultado da cifragem do Apendice B devolve o texto claro
        do_ark(b_output, b_ksch[10], st);
        for (int r = 1; r <= 10; r++) begin
            do_ishr(st, t);
            do_isub(t, st);
            do_ark(st, b_ksch[10 - r], t);
            st = t;
            if (r < 10) begin
                do_imix(st, t);
                st = t;
            end
        end
        check128("Ida e volta (Apendice B)", 10, st, b_input);

        if (errors == 0)
            $display("PASS: %0d checks de MixColumns, AddRoundKey e AES-128 completo passaram", checks);
        else
            $display("FAIL: %0d erro(s) em %0d checks", errors, checks);

        $finish;
    end

endmodule
