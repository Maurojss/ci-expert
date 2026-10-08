// counter.sv
// Módulo trivial usado apenas para validar o fluxo mínimo do repositório
// (clone -> make sim rodando sem fricção). Não faz parte do IP final.

module counter #(
    parameter int WIDTH = 8
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             en,
    output logic [WIDTH-1:0] count
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= '0;
        else if (en)
            count <= count + 1'b1;
    end

endmodule
