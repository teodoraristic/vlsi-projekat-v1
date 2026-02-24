module scan_codes (
    input clk,
    input rst_n,
    input [15:0] code,
    input status,
    output reg control,
    output reg [3:0] num
);
    // 0 = F045
    // 1 = F016
    // 2 = F01E
    // 3 = F026
    // 4 = F025
    // 5 = F02E
    // 6 = F036
    // 7 = F03D
    // 8 = F03E
    // 9 = F046

    wire status_rising;

    localparam KEY_0 = 16'hF045;
    localparam KEY_1 = 16'hF016;
    localparam KEY_2 = 16'hF01E;
    localparam KEY_3 = 16'hF026;
    localparam KEY_4 = 16'hF025;
    localparam KEY_5 = 16'hF02E;
    localparam KEY_6 = 16'hF036;
    localparam KEY_7 = 16'hF03D;
    localparam KEY_8 = 16'hF03E;
    localparam KEY_9 = 16'hF046;

    red red_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(status),
        .out(status_rising)
    );

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            control <= 1'b0;
            num <= 4'd0;
        end else begin
            if (status_rising) begin
                case (code)
                    KEY_0: begin num <= 4'd0; control <= 1'b1; end
                    KEY_1: begin num <= 4'd1; control <= 1'b1; end
                    KEY_2: begin num <= 4'd2; control <= 1'b1; end
                    KEY_3: begin num <= 4'd3; control <= 1'b1; end
                    KEY_4: begin num <= 4'd4; control <= 1'b1; end
                    KEY_5: begin num <= 4'd5; control <= 1'b1; end
                    KEY_6: begin num <= 4'd6; control <= 1'b1; end
                    KEY_7: begin num <= 4'd7; control <= 1'b1; end
                    KEY_8: begin num <= 4'd8; control <= 1'b1; end
                    KEY_9: begin num <= 4'd9; control <= 1'b1; end
                    default: begin control <= 1'b0; end
                endcase
            end else if (!status) begin
                control <= 1'b0;
            end
        end
    end

endmodule