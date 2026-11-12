// minisoc_aes_dp.sv
// Datapath iterativo de 128 bits do AES-128 (1 rodada por ciclo).
// Suporta cifragem (decrypt = 0, FIPS-197 Fig. 5) e decifragem pela cifra inversa
// direta (decrypt = 1, FIPS-197 Fig. 12), reaproveitando os modulos combinacionais
// das Semanas 2 e 3.
//
// Latencia por bloco: 11 ciclos a partir do start (rodada 0 inicial + rodadas 1 a 10).

module minisoc_aes_dp (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic         decrypt,
    input  logic [127:0] block_in,
    input  logic [127:0] round_key,
    output logic [3:0]   round_idx,
    output logic [127:0] block_out,
    output logic         busy,
    output logic         done
);

    logic [127:0] state_q;
    logic [3:0]   rnd_q;
    logic         dec_q;
    logic         running_q;

    // Sinais das transformacoes combinacionais
    logic [127:0] sub_out, shr_out, mix_out;
    logic [127:0] ishr_out, isub_out, imix_in, imix_out;
    logic [127:0] ark_in, ark_out;

    // Instancias de cifragem
    minisoc_aes_sub_bytes   u_sub (.state_in(state_q), .state_out(sub_out));
    minisoc_aes_shift_rows  u_shr (.state_in(sub_out), .state_out(shr_out));
    minisoc_aes_mix_columns u_mix (.state_in(shr_out), .state_out(mix_out));

    // Instancias de decifragem (cifra inversa direta: InvShiftRows -> InvSubBytes -> AddRoundKey -> InvMixColumns)
    minisoc_aes_inv_shift_rows  u_ishr (.state_in(state_q),  .state_out(ishr_out));
    minisoc_aes_inv_sub_bytes   u_isub (.state_in(ishr_out), .state_out(isub_out));
    minisoc_aes_inv_mix_columns u_imix (.state_in(imix_in),  .state_out(imix_out));

    // AddRoundKey compartilhada entre rodada 0, cifra e decifra
    minisoc_aes_add_round_key u_ark (
        .state_in  (ark_in),
        .round_key (round_key),
        .state_out (ark_out)
    );

    assign imix_in = ark_out;

    // Selecao do indice da chave de rodada:
    // No ciclo de start (rodada 0): chave 0 na cifra, chave 10 na decifra.
    // Nas rodadas 1..10: rnd_q na cifra, (10 - rnd_q) na decifra.
    always_comb begin
        if (start) begin
            round_idx = decrypt ? 4'd10 : 4'd0;
        end else if (dec_q) begin
            round_idx = 4'd10 - rnd_q;
        end else begin
            round_idx = rnd_q;
        end
    end

    // Selecao da entrada do AddRoundKey
    always_comb begin
        if (start) begin
            ark_in = block_in;
        end else if (!dec_q) begin
            // Cifragem: rodadas 1 a 9 usam saida do MixColumns; rodada 10 pula MixColumns
            ark_in = (rnd_q == 4'd10) ? shr_out : mix_out;
        end else begin
            // Decifragem: AddRoundKey vem logo apos InvSubBytes
            ark_in = isub_out;
        end
    end

    // Proximo estado
    logic [127:0] next_state;
    always_comb begin
        if (start) begin
            next_state = ark_out;
        end else if (!dec_q) begin
            next_state = ark_out;
        end else begin
            // Decifragem: rodadas 1 a 9 passam por InvMixColumns apos AddRoundKey; rodada 10 pula InvMixColumns
            next_state = (rnd_q == 4'd10) ? ark_out : imix_out;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q   <= 128'h0;
            rnd_q     <= 4'd0;
            dec_q     <= 1'b0;
            running_q <= 1'b0;
            done      <= 1'b0;
        end else begin
            if (start) begin
                state_q   <= next_state;
                rnd_q     <= 4'd1;
                dec_q     <= decrypt;
                running_q <= 1'b1;
                done      <= 1'b0;
            end else if (running_q) begin
                state_q <= next_state;
                if (rnd_q == 4'd10) begin
                    running_q <= 1'b0;
                    done      <= 1'b1;
                end else begin
                    rnd_q <= rnd_q + 4'd1;
                end
            end
        end
    end

    assign busy      = running_q;
    assign block_out = state_q;

endmodule
