module top #(
    parameter DIVISOR = 50_000_000,
    parameter FILE_NAME = "mem_init copy.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input [1:0] kbd,
    input [2:0] btn,
    input [9:0] sw,     // zato sto u DE0 top nema rst_n, vec sve ide u sw
    input [13:0] mnt,
    output [9:0] led,
    output [27:0] ssd   // zato sto se u DE0 top zove ssd, a ne hex...
);
    
    wire rst_n = sw[9];
    wire out_status;
    assign led[5] = out_status;
    wire we;
    wire [ADDR_WIDTH - 1:0] addr;
    wire [DATA_WIDTH - 1:0] data;
    wire [DATA_WIDTH - 1:0] mem_out;
    wire [ADDR_WIDTH - 1:0] pc;
    wire [ADDR_WIDTH - 1:0] sp;
    wire [DATA_WIDTH - 1:0] out_cpu;
    assign led[4:0] = out_cpu;
    
    wire out_clk;
    clk_div #(.DIVISOR(DIVISOR)) clk_div_inst (
        .clk(clk), .rst_n(rst_n), .out(out_clk)
    );

    wire [15:0] out_code;
    ps2 ps2_inst(
        .clk(clk), .rst_n(rst_n), .ps2_clk(kbd[0]), .ps2_data(kbd[1]), .code(out_code)
    );

    wire out_control;
    wire [3:0] out_num_sc;
    scan_codes scan_codes_inst(
        .clk(clk), .rst_n(rst_n), .code(out_code), .status(out_status), .control(out_control), .num(out_num_sc)
    );

    wire [23:0] out_color_codes;
    color_codes color_codes_inst(
        .num(out_cpu[5:0]), .code(out_color_codes)
    );

    vga vga_inst(
        .clk(clk), .rst_n(rst_n), .code(out_color_codes),
        .hsync(mnt[13]), .vsync(mnt[12]), .red(mnt[11:8]), .green(mnt[7:4]), .blue(mnt[3:0])
    );

    cpu cpu_inst (
        .clk(out_clk),
        .rst_n(rst_n),
        .mem(mem_out),
        .in({12'b0,out_num_sc}),
        .control(out_control),
        .status(out_status),
        .we(we),
        .addr(addr),
        .data(data),
        .out(out_cpu), 
        .pc(pc),
        .sp(sp)
    );


    memory #(
        .FILE_NAME("mem_init.mif"),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) mem_inst (
        .clk(out_clk),
        .we(we),
        .addr(addr),
        .data(data),
        .out(mem_out)
    );

    wire [3:0] ones1, tens1, ones2, tens2;

    bcd bcd_pc (
        .in(pc), .ones(ones1), .tens(tens1)
    );

    bcd bcd_sp (
        .in(sp), .ones(ones2), .tens(tens2)
    );

    ssd ssd1 (
        .in(ones1), .out(ssd[6:0])
    );

    ssd ssd2 (
        .in(tens1), .out(ssd[13:7])
    );
    
    ssd ssd3 (
        .in(ones2), .out(ssd[20:14])
    );
    
    ssd ssd4 (
        .in(tens2), .out(ssd[27:21])
    );
    


endmodule