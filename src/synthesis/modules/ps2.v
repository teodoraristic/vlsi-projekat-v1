module ps2 (
    input clk,
    input rst_n,
    input ps2_clk,
    input ps2_data,
    output [15:0] code
);

    reg [15:0] code_q, code_d;
    assign code = code_q;

    reg [2:0] ps2_clk_sync, ps2_data_sync;
    wire ps2_clk_falling = (ps2_clk_sync[2:1] == 2'b10);
    wire data_bit = ps2_data_sync[2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ps2_clk_sync <= 3'b111;
            ps2_data_sync <= 3'b111;
        end else begin
            ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
            ps2_data_sync <= {ps2_data_sync[1:0], ps2_data};
        end
    end

    reg [10:0] shift_reg_q, shift_reg_d;
    reg [3:0] bit_count_q, bit_count_d;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_q <= 0;
            bit_count_q <= 0;
            code_q <= 0;
        end else begin
            shift_reg_q <= shift_reg_d;
            bit_count_q <= bit_count_d;
            code_q <= code_d;
        end
    end

    always @(*) begin
        shift_reg_d = shift_reg_q;
        bit_count_d = bit_count_q;
        code_d = code_q;

        if (ps2_clk_falling) begin
            shift_reg_d = {data_bit, shift_reg_q[10:1]};
            bit_count_d = bit_count_q + 1;

            if (bit_count_q == 10) begin
                bit_count_d = 0;

                if (shift_reg_d[0] == 0 && shift_reg_d[10] == 1) begin
                    code_d = {code_q[7:0], shift_reg_d[8:1]};
                end
            end
        end
    end


endmodule
