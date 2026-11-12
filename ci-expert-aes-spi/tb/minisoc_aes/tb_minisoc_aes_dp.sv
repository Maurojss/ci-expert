// tb_minisoc_aes_dp.sv
// Testbench modular para minisoc_aes_dp integrado com minisoc_aes_key_exp (Semana 4).
// Verifica a cifragem sequencial ciclo a ciclo (Apendice B), a decifragem sequencial
// (Apendice C.1) e o teste de ida e volta (cifrar e decifrar retornando ao texto claro).
// Pode rodar isolado (STANDALONE = 1) ou instanciado na suite da Semana 4 (STANDALONE = 0).

`timescale 1ns/1ps

module tb_minisoc_aes_dp #(
    parameter bit STANDALONE = 1'b1
);

    logic         clk = 1'b0;
    logic         rst_n = 1'b0;

    // Sinais da expansao de chave
    logic         ke_start = 1'b0;
    logic [127:0] key_in = 128'h0;
    logic [3:0]   round_idx;
    logic [127:0] round_key;
    logic         ke_busy;
    logic         ke_done;

    // Sinais do datapath
    logic         dp_start = 1'b0;
    logic         decrypt = 1'b0;
    logic [127:0] block_in = 128'h0;
    logic [127:0] block_out;
    logic         dp_busy;
    logic         dp_done;

    always #5 clk = ~clk;

    minisoc_aes_key_exp u_key_exp (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (ke_start),
        .key_in    (key_in),
        .round_idx (round_idx),
        .round_key (round_key),
        .busy      (ke_busy),
        .done      (ke_done)
    );

    minisoc_aes_dp u_dp (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (dp_start),
        .decrypt   (decrypt),
        .block_in  (block_in),
        .round_key (round_key),
        .round_idx (round_idx),
        .block_out (block_out),
        .busy      (dp_busy),
        .done      (dp_done)
    );

    // Vetores de referencia (FIPS-197)
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

    int checks = 0;
    int errors = 0;

    task automatic check_blk(input string tag, input int step, input logic [127:0] got, input logic [127:0] exp);
        checks++;
        if (got !== exp) begin
            errors++;
            $display("FAIL [dp %s %0d]: obtido %032h, esperado %032h", tag, step, got, exp);
        end
    endtask

    task automatic run_key_exp(input logic [127:0] k);
        @(posedge clk); #1;
        key_in   = k;
        ke_start = 1'b1;
        @(posedge clk); #1;
        ke_start = 1'b0;
        wait (ke_done == 1'b1);
        @(posedge clk); #1;
    endtask

    task automatic run_tests(output int out_checks, output int out_errors);
        checks = 0;
        errors = 0;
        load_vectors();

        rst_n    = 1'b0;
        ke_start = 1'b0;
        dp_start = 1'b0;
        decrypt  = 1'b0;
        block_in = 128'h0;
        repeat (3) @(posedge clk);
        #1;
        rst_n = 1'b1;
        @(posedge clk); #1;

        // 1. Expandir chave do Apendice B e cifrar verificando estado a cada rodada
        run_key_exp(b_ksch[0]);

        decrypt  = 1'b0;
        block_in = b_input;
        dp_start = 1'b1;
        @(posedge clk); #1;
        dp_start = 1'b0;

        // Apos a borda do start, state_q guarda o inicio da rodada 1 (b_start[1])
        for (int r = 1; r <= 10; r++) begin
            check_blk("Apendice B start rodada", r, block_out, b_start[r]);
            @(posedge clk); #1;
        end
        if (!dp_done) begin
            errors++;
            $display("FAIL [dp Apendice B]: dp_done nao subiu ao fim da rodada 10");
        end
        check_blk("Apendice B texto cifrado final", 10, block_out, b_output);

        // 2. Ida e volta com a mesma chave ja expandida: decifrar b_output deve devolver b_input
        @(posedge clk); #1;
        decrypt  = 1'b1;
        block_in = b_output;
        dp_start = 1'b1;
        @(posedge clk); #1;
        dp_start = 1'b0;
        wait (dp_done == 1'b1);
        #1;
        check_blk("Apendice B ida e volta", 10, block_out, b_input);

        // 3. Expandir chave do Apendice C.1 e decifrar verificando cada rodada (ci_istart[1..10])
        run_key_exp(ci_iksch[10]);

        decrypt  = 1'b1;
        block_in = ci_input;
        dp_start = 1'b1;
        @(posedge clk); #1;
        dp_start = 1'b0;

        for (int r = 1; r <= 10; r++) begin
            check_blk("Apendice C.1 istart rodada", r, block_out, ci_istart[r]);
            @(posedge clk); #1;
        end
        if (!dp_done) begin
            errors++;
            $display("FAIL [dp Apendice C.1]: dp_done nao subiu ao fim da rodada 10");
        end
        check_blk("Apendice C.1 texto claro final", 10, block_out, ci_output);

        // 4. Cifrar ci_output com a chave do C.1 deve devolver ci_input
        @(posedge clk); #1;
        decrypt  = 1'b0;
        block_in = ci_output;
        dp_start = 1'b1;
        @(posedge clk); #1;
        dp_start = 1'b0;
        wait (dp_done == 1'b1);
        #1;
        check_blk("Apendice C.1 ida e volta", 10, block_out, ci_input);

        out_checks = checks;
        out_errors = errors;
    endtask

    initial begin
        if (STANDALONE) begin
            int c, e;
            run_tests(c, e);
            if (e == 0)
                $display("PASS: %0d checks de minisoc_aes_dp passaram", c);
            else
                $display("FAIL: %0d erro(s) em %0d checks de minisoc_aes_dp", e, c);
            $finish;
        end
    end

endmodule
