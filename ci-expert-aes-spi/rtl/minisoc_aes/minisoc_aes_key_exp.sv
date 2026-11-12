// minisoc_aes_key_exp.sv
// Expansao de chave do AES-128: gera as 11 chaves de rodada
// (round keys 0 a 10, de 128 bits) a partir da chave de 128 bits.
// Arquitetura pre-computada iterativa: no pulso de start, carrega a chave na rodada 0
// e calcula uma chave de rodada por ciclo ao longo de 10 ciclos (usando 4 S-boxes),
// guardando as 11 subchaves em registradores para leitura direta por indice (round_idx),
// o que permite ler de 0 a 10 na cifragem e de 10 a 0 na decifragem sem custo adicional.

module minisoc_aes_key_exp (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic [127:0] key_in,
    input  logic [3:0]   round_idx,
    output logic [127:0] round_key,
    output logic         busy,
    output logic         done
);

    logic [127:0] rk_mem [0:10];
    logic [3:0]   cnt;
    logic         running;

    // Palavras da ultima chave calculada (rk_mem[cnt])
    logic [31:0] w0, w1, w2, w3;
    logic [31:0] rot_w3, sub_w3, rcon_word, temp;
    logic [31:0] nw0, nw1, nw2, nw3;

    assign w0 = rk_mem[cnt][127:96];
    assign w1 = rk_mem[cnt][95:64];
    assign w2 = rk_mem[cnt][63:32];
    assign w3 = rk_mem[cnt][31:0];

    // RotWord(w3): deslocamento ciclico de 1 byte para a esquerda
    assign rot_w3 = {w3[23:0], w3[31:24]};

    // SubWord(RotWord(w3)): 4 instancias da S-box
    minisoc_aes_sbox u_sbox0 (.a(rot_w3[31:24]), .y(sub_w3[31:24]));
    minisoc_aes_sbox u_sbox1 (.a(rot_w3[23:16]), .y(sub_w3[23:16]));
    minisoc_aes_sbox u_sbox2 (.a(rot_w3[15:8]),  .y(sub_w3[15:8]));
    minisoc_aes_sbox u_sbox3 (.a(rot_w3[7:0]),   .y(sub_w3[7:0]));

    // Rcon[r] para r = cnt + 1 (rodadas 1 a 10)
    function automatic logic [7:0] get_rcon(input logic [3:0] idx);
        case (idx)
            4'd0:    return 8'h01;
            4'd1:    return 8'h02;
            4'd2:    return 8'h04;
            4'd3:    return 8'h08;
            4'd4:    return 8'h10;
            4'd5:    return 8'h20;
            4'd6:    return 8'h40;
            4'd7:    return 8'h80;
            4'd8:    return 8'h1b;
            4'd9:    return 8'h36;
            default: return 8'h00;
        endcase
    endfunction

    assign rcon_word = {get_rcon(cnt), 24'h000000};
    assign temp      = sub_w3 ^ rcon_word;

    assign nw0 = w0 ^ temp;
    assign nw1 = w1 ^ nw0;
    assign nw2 = w2 ^ nw1;
    assign nw3 = w3 ^ nw2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i <= 10; i++) begin
                rk_mem[i] <= 128'h0;
            end
            cnt     <= 4'd0;
            running <= 1'b0;
            done    <= 1'b0;
        end else begin
            if (start) begin
                rk_mem[0] <= key_in;
                cnt       <= 4'd0;
                running   <= 1'b1;
                done      <= 1'b0;
            end else if (running) begin
                rk_mem[cnt + 4'd1] <= {nw0, nw1, nw2, nw3};
                if (cnt == 4'd9) begin
                    running <= 1'b0;
                    done    <= 1'b1;
                end else begin
                    cnt <= cnt + 4'd1;
                end
            end
        end
    end

    assign busy      = running;
    assign round_key = (round_idx <= 4'd10) ? rk_mem[round_idx] : 128'h0;

endmodule
