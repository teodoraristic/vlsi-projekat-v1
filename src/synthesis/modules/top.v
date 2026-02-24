module top #(
    parameter DIVISOR    = 50000000,
    parameter FILE_NAME  = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
)(
    input clk,
    input rst_n,
    input [1:0] kbd,
    input [2:0] btn,
    // input [8:0] sw,
    output [13:0] mnt,
    output [9:0] led,
    output [27:0] hex
);
    wire slow_clk, status, control;
    wire [15:0] code;
    wire [23:0] code_vga;
    wire we;
    wire [ADDR_WIDTH-1:0] addr;
    wire [DATA_WIDTH-1:0] data;
    wire [DATA_WIDTH-1:0] mem;
    wire [ADDR_WIDTH-1:0] pc;
    wire [ADDR_WIDTH-1:0] sp;
    wire [DATA_WIDTH-1:0] cpu_out;
    wire [DATA_WIDTH-1:0] cpu_in;        // gornji bitovi se pune kroz assign ispod
    wire [DATA_WIDTH-1:0] mem_out;
    wire [3:0] pc_ones, pc_tens;
    wire [3:0] sp_ones, sp_tens;

    // Bug 2 fix: poseban wire za num, gornji bitovi cpu_in = 0
    wire [3:0] num_wire;
    assign cpu_in = {{(DATA_WIDTH-4){1'b0}}, num_wire};

    clk_div #(
        .DIVISOR(DIVISOR)
    ) CLK_DIV (
        .clk(clk),
        .rst_n(rst_n),
        .out(slow_clk)
    );

    memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FILE_NAME (FILE_NAME)
    ) MEMORY (
        .clk(slow_clk),
        .rst_n(rst_n),
        .we(we),
        .addr(addr),
        .data(data),
        .out(mem_out)
    );

    cpu #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) CPU (
        .clk(slow_clk),
        .rst_n(rst_n),
        .in(cpu_in),
        .mem(mem_out),
        .we(we),
        .addr(addr),
        .data(data),
        .pc(pc),
        .sp(sp),
        .out(cpu_out),
        .control(control),
        .status(status)
    );

    // Bug 3 fix: 4'b0 umesto 1'b0
    assign led[9:6] = 4'b0;
    assign led[5]   = status;
    assign led[4:0] = cpu_out[4:0];

    bcd BCD_PC (
        .in(pc),
        .ones(pc_ones),
        .tens(pc_tens)
    );

    bcd BCD_SP (
        .in(sp),
        .ones(sp_ones),
        .tens(sp_tens)
    );

    ssd SSD0 (
        .in(pc_ones),
        .out(hex[6:0])
    );

    ssd SSD1 (
        .in(pc_tens),
        .out(hex[13:7])
    );

    ssd SSD2 (
        .in(sp_ones),
        .out(hex[20:14])
    );

    ssd SSD3 (
        .in(sp_tens),
        .out(hex[27:21])
    );

    ps2 PS2 (
        .clk(clk),
        .rst_n(rst_n),
        .ps2_clk(kbd[0]),
        .ps2_data(kbd[1]),
        .code(code)
    );

    // Bug 2 fix: num_wire umesto cpu_in[3:0]
    scan_codes SC (
        .clk(slow_clk),
        .rst_n(rst_n),
        .code(code),
        .control(control),
        .status(status),
        .num(num_wire)
    );

    color_codes CC (
        .num(cpu_out[5:0]),
        .code(code_vga)
    );

    vga VGA (
        .clk(clk),
        .rst_n(rst_n),
        .code(code_vga),
        .hsync(mnt[13]),
        .vsync(mnt[12]),
        .red(mnt[11:8]),
        .green(mnt[7:4]),
        .blue(mnt[3:0])
    );

endmodule
