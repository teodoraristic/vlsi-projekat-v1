/*module register(clk, rst_n, cl, ld,
    in, inc, dec, sr, ir, sl, il, out);

    input clk, rst_n, ld, cl, inc, dec, sr, sl, ir, il;
    input [3:0] in;
    output [3:0] out;

    reg [3:0] out_next, out_reg;
    assign out = out_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            out_reg <= 4'h0;
        else 
            out_reg <= out_next;
    end
    always @(cl, ld, inc, dec, sr, sl) begin
        casex ({cl, ld, inc, dec, sr, sl})
            6'b1xxxxx: out_next = 4'h0;
            6'b01xxxx: out_next = in;
            6'b001xxx: out_next = out_reg + {{3{1'b0}}, 1'b1};
            6'b0001xx: out_next = out_reg - {{3{1'b0}}, 1'b1};
            6'b00001x: out_next = {ir, out_reg[3:1]};
            6'b000001: out_next = {out_reg[2:0], il};
            default: out_next = out_reg;
        endcase
    end

endmodule
*/
module register #(
    parameter DATA_WIDTH = 16,
    parameter HIGH = DATA_WIDTH - 1
) (
    input clk,
    input rst_n,
    input cl,
    input ld,
    input [HIGH:0] in,
    input inc,
    input dec,
    input sr,
    input ir,
    input sl,
    input il,
    output [HIGH:0] out
);

    //reg state_next, state_reg;
    reg [HIGH:0] out_next, out_reg;
    assign out = out_reg;

    always @(posedge clk, negedge rst_n)
        if (!rst_n)
            out_reg <= {DATA_WIDTH{1'b0}};
        else
            out_reg <= out_next;
    

    always @(cl, ld, inc, dec, sr, sl) begin
        out_next = out_reg;
        casex ({cl, ld, inc, dec, sr, sl})
            6'b1xxxxx: out_next = {DATA_WIDTH{1'b0}};
            6'b01xxxx: out_next = in;
            6'b001xxx: out_next = out_reg + 1'b1;
            6'b0001xx: out_next = out_reg - 1'b1;
            6'b00001x: out_next = {ir, out_reg[HIGH:1]};
            6'b000001: out_next = {out_reg[HIGH-1:0], il};
            default: out_next = out_reg;
        endcase
    end

endmodule