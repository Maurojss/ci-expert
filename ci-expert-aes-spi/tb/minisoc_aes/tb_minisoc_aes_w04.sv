// tb_minisoc_aes_w04.sv
// Testbench integrador (hierarquico) da Semana 4.
// Instancia os testbenches unitarios tb_minisoc_aes_key_exp e tb_minisoc_aes_dp
// em hierarquias separadas (facilitando o debug de ondas no Verdi) e executa
// a bateria completa de verificacao.

`timescale 1ns/1ps

module tb_minisoc_aes_w04;

    int ke_checks, ke_errors;
    int dp_checks, dp_errors;
    int total_checks, total_errors;

    // Instancias modulares dos testbenches (STANDALONE = 0)
    tb_minisoc_aes_key_exp #(.STANDALONE(1'b0)) u_tb_key_exp ();
    tb_minisoc_aes_dp      #(.STANDALONE(1'b0)) u_tb_dp      ();

    initial begin
        $display("=== [1/2] Executando u_tb_key_exp (Expansao de Chave) ===");
        u_tb_key_exp.run_tests(ke_checks, ke_errors);
        $display("    -> %0d checks, %0d erros", ke_checks, ke_errors);

        $display("=== [2/2] Executando u_tb_dp (Datapath Cifra e Decifra) ===");
        u_tb_dp.run_tests(dp_checks, dp_errors);
        $display("    -> %0d checks, %0d erros", dp_checks, dp_errors);

        total_checks = ke_checks + dp_checks;
        total_errors = ke_errors + dp_errors;

        if (total_errors == 0)
            $display("PASS: %0d checks da Semana 4 (key_exp + dp integrados) passaram", total_checks);
        else
            $display("FAIL: %0d erro(s) em %0d checks da Semana 4", total_errors, total_checks);

        $finish;
    end

endmodule
