module color_codes (
    input [5:0] num,
    output [23:0] code
);
    localparam CRNA = 4'd0;
    localparam CRVENA = 4'd1;
    localparam NARANDZASTA = 4'd2;
    localparam ZUTA = 4'd3;
    localparam ZELENA = 4'd4;
    localparam CIJAN = 4'd5;
    localparam SVETLOPLAVA = 4'd6;
    localparam PLAVA = 4'd7;
    localparam MAGENTA = 4'd8;
    localparam BELA = 4'd9;

    wire [3:0] ones;
    wire [3:0] tens;

    bcd bcd_inst (
        .in(num), .ones(ones), .tens(tens)
    );

    reg [11:0] color_tens;
    reg [11:0] color_ones;

    always @(*) begin
        case (tens)
            CRNA:           color_tens = 12'h000;
            CRVENA:         color_tens = 12'hF00;
            NARANDZASTA:    color_tens = 12'hF80;
            ZUTA:           color_tens = 12'hFF0;
            ZELENA:         color_tens = 12'h0F0;
            CIJAN:          color_tens = 12'h0FF;
            SVETLOPLAVA:    color_tens = 12'h08F;
            PLAVA:          color_tens = 12'h00F;
            MAGENTA:        color_tens = 12'hF0F;
            BELA:           color_tens = 12'hFFF;
            default:        color_tens = 12'h000;
        endcase

        case (ones)
            CRNA:           color_ones = 12'h000;
            CRVENA:         color_ones = 12'hF00;
            NARANDZASTA:    color_ones = 12'hF80;
            ZUTA:           color_ones = 12'hFF0;
            ZELENA:         color_ones = 12'h0F0;
            CIJAN:          color_ones = 12'h0FF;
            SVETLOPLAVA:    color_ones = 12'h08F;
            PLAVA:          color_ones = 12'h00F;
            MAGENTA:        color_ones = 12'hF0F;
            BELA:           color_ones = 12'hFFF;
            default:        color_ones = 12'h000;
        endcase
    end

    assign code = {color_tens, color_ones};
    
      
endmodule