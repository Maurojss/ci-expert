// minisoc_aes_sub_bytes.sv
// SubBytes() do AES (FIPS-197, secao 5.1.1): aplica a S-box a cada um dos 16 bytes do estado.
// Combinacional.
//
// Convencao do estado (a mesma do Block Guide): o byte 0 fica em state[127:120] e o byte 15
// em state[7:0]. O byte n corresponde a s[r][c], com r = n mod 4 e c = n div 4.

module minisoc_aes_sub_bytes (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    for (genvar n = 0; n < 16; n++) begin : g_byte
        minisoc_aes_sbox u_sbox (
            .a (state_in [127 - 8*n -: 8]),
            .y (state_out[127 - 8*n -: 8])
        );
    end

endmodule
