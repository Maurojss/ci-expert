// tb_minisoc_aes_sub_shift.sv
// Testbench autoverificavel da Semana 2: S-box, SubBytes e ShiftRows (e, como opcional, as
// transformacoes inversas) contra os valores de referencia do FIPS-197.
//
// Verifica:
//   1. minisoc_aes_sbox: as 256 entradas contra a Figura 7, com sbox(00)=63 e sbox(53)=ed.
//   2. SubBytes e ShiftRows sobre o exemplo de cifragem do Apendice B, nas 10 rodadas:
//        Start of Round -> After SubBytes -> After ShiftRows
//      (rodada 1 conferida tambem com os valores literais do enunciado).
//   3. Opcional: minisoc_aes_inv_sbox contra a Figura 14 e InvSubBytes(SubBytes(x)) = x;
//      InvShiftRows e InvSubBytes desfazendo as transformacoes diretas nas 10 rodadas.
//
// Os vetores vem de minisoc_aes_vectors.svh, gerado por scripts/gen_aes_vectors.py.
// Todos os DUTs sao combinacionais.

`timescale 1ns/1ps

module tb_minisoc_aes_sub_shift;

    // ---------------- DUTs ----------------
    logic [7:0]   sb_a, sb_y, isb_a, isb_y;
    logic [127:0] sub_in, sub_out, shr_in, shr_out;
    logic [127:0] isub_in, isub_out, ishr_in, ishr_out;

    minisoc_aes_sbox           u_sbox  (.a(sb_a),  .y(sb_y));
    minisoc_aes_inv_sbox       u_isbox (.a(isb_a), .y(isb_y));
    minisoc_aes_sub_bytes      u_sub   (.state_in(sub_in),  .state_out(sub_out));
    minisoc_aes_shift_rows     u_shr   (.state_in(shr_in),  .state_out(shr_out));
    minisoc_aes_inv_sub_bytes  u_isub  (.state_in(isub_in), .state_out(isub_out));
    minisoc_aes_inv_shift_rows u_ishr  (.state_in(ishr_in), .state_out(ishr_out));

    // ---------------- Vetores de referencia ----------------
    logic [7:0]   sbox_ref     [0:255];
    logic [7:0]   inv_sbox_ref [0:255];
    logic [127:0] b_start [1:10];
    logic [127:0] b_sbox  [1:10];
    logic [127:0] b_srow  [1:10];

    task automatic load_vectors();
        `include "minisoc_aes_vectors.svh"
    endtask

    // ---------------- Verificacao ----------------
    int checks;
    int errors;

    task automatic check8(input string name, input int idx, input logic [7:0] got, input logic [7:0] exp);
        checks++;
        if (got !== exp) begin
            errors++;
            $display("FAIL [%s %0d]: obtido %02h, esperado %02h", name, idx, got, exp);
        end
    endtask

    task automatic check128(input string name, input int rnd, input logic [127:0] got, input logic [127:0] exp);
        checks++;
        if (got !== exp) begin
            errors++;
            $display("FAIL [%s rodada %0d]: obtido %032h, esperado %032h", name, rnd, got, exp);
        end
    endtask

    initial begin
        checks = 0;
        errors = 0;
        sb_a = '0; isb_a = '0; sub_in = '0; shr_in = '0; isub_in = '0; ishr_in = '0;
        load_vectors();

        // 1. S-box: as 256 entradas e os dois valores citados no enunciado
        for (int i = 0; i < 256; i++) begin
            sb_a = i[7:0];
            #1;
            check8("sbox", i, sb_y, sbox_ref[i]);
        end
        sb_a = 8'h00; #1; check8("sbox(00)", 0, sb_y, 8'h63);
        sb_a = 8'h53; #1; check8("sbox(53)", 0, sb_y, 8'hed);

        // 2. SubBytes e ShiftRows, Apendice B, rodadas 1 a 10
        for (int r = 1; r <= 10; r++) begin
            sub_in = b_start[r];
            #1;
            check128("SubBytes", r, sub_out, b_sbox[r]);

            shr_in = b_sbox[r];
            #1;
            check128("ShiftRows", r, shr_out, b_srow[r]);

            // cadeia completa: ShiftRows(SubBytes(start)) = After ShiftRows
            shr_in = sub_out;
            #1;
            check128("SubBytes+ShiftRows", r, shr_out, b_srow[r]);
        end

        // valores literais do enunciado (rodada 1)
        sub_in = 128'h193de3bea0f4e22b9ac68d2ae9f84808;
        #1;
        check128("SubBytes literal", 1, sub_out, 128'hd42711aee0bf98f1b8b45de51e415230);
        shr_in = 128'hd42711aee0bf98f1b8b45de51e415230;
        #1;
        check128("ShiftRows literal", 1, shr_out, 128'hd4bf5d30e0b452aeb84111f11e2798e5);

        // 3. Opcional: transformacoes inversas
        for (int i = 0; i < 256; i++) begin
            isb_a = i[7:0];
            #1;
            check8("inv_sbox", i, isb_y, inv_sbox_ref[i]);
            sb_a = i[7:0];
            #1;
            isb_a = sb_y;
            #1;
            check8("inv_sbox(sbox(x))", i, isb_y, i[7:0]);
        end
        for (int r = 1; r <= 10; r++) begin
            ishr_in = b_srow[r];
            #1;
            check128("InvShiftRows", r, ishr_out, b_sbox[r]);
            isub_in = b_sbox[r];
            #1;
            check128("InvSubBytes", r, isub_out, b_start[r]);
            isub_in = ishr_out;
            #1;
            check128("InvSubBytes(InvShiftRows)", r, isub_out, b_start[r]);
        end

        if (errors == 0)
            $display("PASS: %0d checks de S-box, SubBytes e ShiftRows passaram", checks);
        else
            $display("FAIL: %0d erro(s) em %0d checks", errors, checks);

        $finish;
    end

endmodule
