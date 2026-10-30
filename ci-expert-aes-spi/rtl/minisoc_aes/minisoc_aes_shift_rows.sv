// minisoc_aes_shift_rows.sv
// ShiftRows() do AES (FIPS-197, secao 5.1.2): a linha r do estado e deslocada ciclicamente
// de r posicoes para a esquerda. Apenas reordenacao de fios, sem logica.
//
// Convencao do estado: o byte n (n = r + 4c) fica em state[127-8n -: 8]; o byte 0 esta em
// state[127:120]. Pela equacao (5.3) do FIPS-197: s'[r,c] = s[r, (c + r) mod 4].

module minisoc_aes_shift_rows (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    for (genvar c = 0; c < 4; c++) begin : g_col
        for (genvar r = 0; r < 4; r++) begin : g_row
            localparam int DST = r + 4 * c;
            localparam int SRC = r + 4 * ((c + r) % 4);
            assign state_out[127 - 8*DST -: 8] = state_in[127 - 8*SRC -: 8];
        end
    end

endmodule
