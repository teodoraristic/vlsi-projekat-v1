/*module alu(oc, a, b, f);

    input [2:0] oc;
    input [3:0] a;
    input [3:0] b;
    output reg [3:0] f;

    always @(oc, a, b) begin
        case (oc)
            3'b000: f = a + b;
            3'b001: f = a - b;
            3'b010: f = a * b;
            3'b011: f = a / b;
            3'b100: f = ~a;
            3'b101: f = a ^ b;
            3'b110: f = a | b;
            3'b111: f = a & b;
        endcase
    end

endmodule
*/module alu #(
    parameter DATA_WIDTH = 16,
    parameter HIGH = DATA_WIDTH - 1
) (
    input [2:0] oc,
    input [HIGH:0] a,
    input [HIGH:0] b,
    output reg [HIGH:0] f
);
    localparam add = 3'b000;
    localparam sub = 3'b001;
    localparam mul = 3'b010;
    localparam div = 3'b011;
    localparam neg = 3'b100;
    localparam xorr = 3'b101;
    localparam orr = 3'b110;
    localparam andd = 3'b111;

    always @(oc, a, b) begin
        case (oc)
            add:    f = a + b;
            sub:    f = a - b;
            mul:    f = a * b; 
            div:    f = a / b;
            neg:    f = ~a;
            xorr:   f = a ^ b;
            orr:    f = a | b;
            andd:   f = a & b;
            default: f = {DATA_WIDTH{1'b0}};
        endcase
    end
endmodule