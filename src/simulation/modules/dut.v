module dut (
    clk, we, addr, data, out
);

    input clk, we;
    input [15:0] data;
    input [5:0] addr;
    output [15:0] out;

    //wire [7:0] out_l;
    //wire [7:0] out_h;

    //assign out = {out_h, out_l};

    memory mem_l(clk, we, addr, data[7:0], out[7:0]);
    memory mem_h(clk, we, addr, data[15:8], out[15:8]);

endmodule