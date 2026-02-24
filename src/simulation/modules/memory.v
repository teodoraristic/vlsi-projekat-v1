/*module memory (
    clk, we, addr, data, out
);

    input clk, we;
    input [5:0] addr;
    input [7:0] data;
    output [7:0] out;

    reg [7:0] mem [0:63];

    reg [7:0] out_reg; 
    reg [7:0] out_next;
    assign out = out_reg;

    always @(posedge clk ) begin
        out_reg <= out_next;
    end

    always @(*) begin
        if (we) begin
            mem[addr] = data;
        end
        out_next = mem[addr];
    end
    
endmodule
*/module memory #(
	parameter FILE_NAME = "mem_init copy.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
)(
    input clk,
    input we,
    input [ADDR_WIDTH - 1:0] addr,
    input [DATA_WIDTH - 1:0] data,
    output reg [DATA_WIDTH - 1:0] out
);

	(* ram_init_file = FILE_NAME *) reg [DATA_WIDTH - 1:0] mem [2**ADDR_WIDTH - 1:0];
   
    initial begin
        $readmemh("mem_init copy.mif", mem);  // ako je .mif u hex formatu
    end

    always @(posedge clk) begin
        if (we) begin
            mem[addr] = data;
        end
        out <= mem[addr];
    end

endmodule
