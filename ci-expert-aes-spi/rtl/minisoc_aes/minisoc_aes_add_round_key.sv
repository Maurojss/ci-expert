// minisoc_aes_add_round_key.sv
// AddRoundKey() do AES (FIPS-197, secao 5.1.4): XOR bit a bit do estado com a chave da rodada.
// Combinacional. A transformacao e a propria inversa (secao 5.3.4), entao o mesmo modulo
// serve na cifragem e na decifragem.

module minisoc_aes_add_round_key (
    input  logic [127:0] state_in,
    input  logic [127:0] round_key,
    output logic [127:0] state_out
);

    assign state_out = state_in ^ round_key;

endmodule
