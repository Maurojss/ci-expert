// minisoc_aes_inv_mix_columns.sv
// InvMixColumns() do AES: inverso do MixColumns. Cada coluna e
// multiplicada, em GF(2^8), por (0e 0b 0d 09 / 09 0e 0b 0d / 0d 09 0e 0b / 0b 0d 09 0e).
// Combinacional. Usado na decifragem (ECB, CBC e PCBC).
// As constantes sao obtidas por encadeamento de xtime:
//   {09} = {08} ^ {01}          {0b} = {08} ^ {02} ^ {01}
//   {0d} = {08} ^ {04} ^ {01}   {0e} = {08} ^ {04} ^ {02}

module minisoc_aes_inv_mix_columns (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    function automatic logic [7:0] xtime(input logic [7:0] x);
        return {x[6:0], 1'b0} ^ (x[7] ? 8'h1b : 8'h00);
    endfunction

    function automatic logic [7:0] mul9(input logic [7:0] x);
        return xtime(xtime(xtime(x))) ^ x;
    endfunction

    function automatic logic [7:0] mul11(input logic [7:0] x);
        return xtime(xtime(xtime(x))) ^ xtime(x) ^ x;
    endfunction

    function automatic logic [7:0] mul13(input logic [7:0] x);
        return xtime(xtime(xtime(x))) ^ xtime(xtime(x)) ^ x;
    endfunction

    function automatic logic [7:0] mul14(input logic [7:0] x);
        return xtime(xtime(xtime(x))) ^ xtime(xtime(x)) ^ xtime(x);
    endfunction

    for (genvar c = 0; c < 4; c++) begin : g_col
        logic [7:0] s0, s1, s2, s3;

        assign s0 = state_in[127 - 8*(4*c + 0) -: 8];
        assign s1 = state_in[127 - 8*(4*c + 1) -: 8];
        assign s2 = state_in[127 - 8*(4*c + 2) -: 8];
        assign s3 = state_in[127 - 8*(4*c + 3) -: 8];

        assign state_out[127 - 8*(4*c + 0) -: 8] = mul14(s0) ^ mul11(s1) ^ mul13(s2) ^ mul9(s3);
        assign state_out[127 - 8*(4*c + 1) -: 8] = mul9(s0)  ^ mul14(s1) ^ mul11(s2) ^ mul13(s3);
        assign state_out[127 - 8*(4*c + 2) -: 8] = mul13(s0) ^ mul9(s1)  ^ mul14(s2) ^ mul11(s3);
        assign state_out[127 - 8*(4*c + 3) -: 8] = mul11(s0) ^ mul13(s1) ^ mul9(s2)  ^ mul14(s3);
    end

endmodule
