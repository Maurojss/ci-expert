// tb_minisoc_aes_key_exp.sv
// Testbench modular para minisoc_aes_key_exp (Semana 4).
// Verifica as 11 subchaves geradas para a chave do Apendice B (2b7e1516...)
// e para a chave do Apendice A.1 / C.1 (00010203...), alem da leitura em ordem
// direta (0 a 10) e inversa (10 a 0).
// Pode rodar isolado (STANDALONE = 1) ou instanciado na suite da Semana 4 (STANDALONE = 0).

`timescale 1ns/1ps

module tb_minisoc_aes_key_exp #(
    parameter bit STANDALONE = 1'b1
);

    logic         clk = 1'b0;
    logic         rst_n = 1'b0;
    logic         start = 1'b0;
    logic [127:0] key_in = 128'h0;
    logic [3:0]   round_idx = 4'd0;
    logic [127:0] round_key;
    logic         busy;
    logic         done;

    always #5 clk = ~clk;

    minisoc_aes_key_exp u_dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .key_in    (key_in),
        .round_idx (round_idx),
        .round_key (round_key),
        .busy      (busy),
        .done      (done)
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

    task automatic check_rk(input string tag, input int r, input logic [127:0] got, input logic [127:0] exp);
        checks++;
        if (got !== exp) begin
            errors++;
            $display("FAIL [key_exp %s r=%0d]: obtido %032h, esperado %032h", tag, r, got, exp);
        end
    endtask

    task automatic run_tests(output int out_checks, output int out_errors);
        int cyc;
        checks = 0;
        errors = 0;
        load_vectors();

        // Reset inicial
        rst_n  = 1'b0;
        start  = 1'b0;
        key_in = 128'h0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // 1. Expansao da chave do Apendice B
        key_in = b_ksch[0];
        start  = 1'b1;
        @(posedge clk);
        start  = 1'b0;

        cyc = 0;
        while (!done && cyc < 30) begin
            @(posedge clk);
            cyc++;
        end
        if (!done) begin
            errors++;
            $display("FAIL [key_exp Apendice B]: timeout esperando done");
        end

        // Leitura direta (0 a 10)
        for (int r = 0; r <= 10; r++) begin
            round_idx = r[3:0];
            #1;
            check_rk("Apendice B direta", r, round_key, b_ksch[r]);
        end

        // Leitura inversa (10 a 0)
        for (int r = 10; r >= 0; r--) begin
            round_idx = r[3:0];
            #1;
            check_rk("Apendice B inversa", r, round_key, b_ksch[r]);
        end

        // 2. Expansao da chave do Apendice C.1 (ci_iksch[10] e a chave original 000102...0f)
        @(posedge clk);
        key_in = ci_iksch[10];
        start  = 1'b1;
        @(posedge clk);
        start  = 1'b0;

        cyc = 0;
        while (!done && cyc < 30) begin
            @(posedge clk);
            cyc++;
        end
        if (!done) begin
            errors++;
            $display("FAIL [key_exp Apendice C.1]: timeout esperando done");
        end

        // Na cifra inversa do C.1, ci_iksch[r] equivale a round_key[10 - r]
        for (int r = 0; r <= 10; r++) begin
            round_idx = 4'd10 - r[3:0];
            #1;
            check_rk("Apendice C.1", r, round_key, ci_iksch[r]);
        end

        out_checks = checks;
        out_errors = errors;
    endtask

    initial begin
        if (STANDALONE) begin
            int c, e;
            run_tests(c, e);
            if (e == 0)
                $display("PASS: %0d checks de minisoc_aes_key_exp passaram", c);
            else
                $display("FAIL: %0d erro(s) em %0d checks de minisoc_aes_key_exp", e, c);
            $finish;
        end
    end

endmodule
