// minisoc_aes_inv_shift_rows.sv
// InvShiftRows() do AES: a linha r do estado e deslocada ciclicamente
// de r posicoes para a direita. Apenas reordenacao de fios. Opcional na Semana 2.
// Pela equacao (5.8): s'[r, (c + r) mod 4] = s[r, c].

module minisoc_aes_inv_shift_rows (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    for (genvar c = 0; c < 4; c++) begin : g_col
        for (genvar r = 0; r < 4; r++) begin : g_row
            localparam int SRC = r + 4 * c;
            localparam int DST = r + 4 * ((c + r) % 4);
            assign state_out[127 - 8*DST -: 8] = state_in[127 - 8*SRC -: 8];
        end
    end

endmodule
