// tb_counter.sv
// Testbench mínimo, com self-check (PASS/FAIL), usado apenas para validar
// que o fluxo clone -> make sim funciona em um ambiente limpo.
//
// Os estímulos são aplicados na borda de DESCIDA do clock e a amostragem
// do DUT ocorre na borda de subida, evitando race condition entre o
// testbench e o flip-flop.

`timescale 1ns/1ps

module tb_counter;

    localparam int WIDTH = 8;

    logic             clk;
    logic             rst_n;
    logic             en;
    logic [WIDTH-1:0] count;

    int errors;

    counter #(.WIDTH(WIDTH)) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .count (count)
    );

    // Clock de 10ns de período
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        errors = 0;
        rst_n  = 1'b0;
        en     = 1'b0;

        // Mantém reset por 2 ciclos e libera na borda de descida
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        // Verifica reset
        if (count !== '0) begin
            $display("FAIL: contador nao zerou apos reset (count=%0d)", count);
            errors++;
        end

        // Habilita contagem: 5 bordas de subida com en=1
        en = 1'b1;
        repeat (5) @(posedge clk);
        @(negedge clk);

        if (count !== 8'd5) begin
            $display("FAIL: valor esperado 5, obtido %0d", count);
            errors++;
        end

        // Desabilita e confirma que o valor se mantém por 3 ciclos
        en = 1'b0;
        repeat (3) @(negedge clk);

        if (count !== 8'd5) begin
            $display("FAIL: contador avancou com en=0 (count=%0d)", count);
            errors++;
        end

        if (errors == 0)
            $display("PASS: todos os checks do exemplo minimo passaram");
        else
            $display("FAIL: %0d erro(s) encontrado(s)", errors);

        $finish;
    end

endmodule