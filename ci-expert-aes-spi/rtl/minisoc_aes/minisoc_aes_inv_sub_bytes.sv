// minisoc_aes_inv_sub_bytes.sv
// InvSubBytes() do AES: aplica a S-box inversa a cada byte do estado.
// Combinacional. Opcional na Semana 2; necessario na decifragem (Semana 3 em diante).
// Mesma convencao de bytes de minisoc_aes_sub_bytes.

module minisoc_aes_inv_sub_bytes (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    for (genvar n = 0; n < 16; n++) begin : g_byte
        minisoc_aes_inv_sbox u_inv_sbox (
            .a (state_in [127 - 8*n -: 8]),
            .y (state_out[127 - 8*n -: 8])
        );
    end

endmodule
