// minisoc_aes_mix_columns.sv
// MixColumns() do AES (FIPS-197, secao 5.1.3): cada coluna do estado e multiplicada, em
// GF(2^8), pela matriz fixa (02 03 01 01 / 01 02 03 01 / 01 01 02 03 / 03 01 01 02).
// Combinacional. A coluna c reune os bytes 4c a 4c+3 (s0c a s3c).
// Convencao do estado: byte 0 em state[127:120], byte 15 em state[7:0].

module minisoc_aes_mix_columns (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    // Multiplicacao por {02} (xtime, secao 4.2.1): deslocamento e XOR condicional com {1b}.
    function automatic logic [7:0] xtime(input logic [7:0] x);
        return {x[6:0], 1'b0} ^ (x[7] ? 8'h1b : 8'h00);
    endfunction

    // Multiplicacao por {03} = {02} XOR {01}.
    function automatic logic [7:0] mul3(input logic [7:0] x);
        return xtime(x) ^ x;
    endfunction

    for (genvar c = 0; c < 4; c++) begin : g_col
        logic [7:0] s0, s1, s2, s3;

        assign s0 = state_in[127 - 8*(4*c + 0) -: 8];
        assign s1 = state_in[127 - 8*(4*c + 1) -: 8];
        assign s2 = state_in[127 - 8*(4*c + 2) -: 8];
        assign s3 = state_in[127 - 8*(4*c + 3) -: 8];

        assign state_out[127 - 8*(4*c + 0) -: 8] = xtime(s0) ^ mul3(s1) ^ s2       ^ s3;
        assign state_out[127 - 8*(4*c + 1) -: 8] = s0        ^ xtime(s1) ^ mul3(s2) ^ s3;
        assign state_out[127 - 8*(4*c + 2) -: 8] = s0        ^ s1        ^ xtime(s2) ^ mul3(s3);
        assign state_out[127 - 8*(4*c + 3) -: 8] = mul3(s0)  ^ s1        ^ s2        ^ xtime(s3);
    end

endmodule
