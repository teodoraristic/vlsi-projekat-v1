module top #(
    parameter DIVISOR = 50_000_000,
    parameter FILE_NAME = "mem_init.mif",
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
    
    wire rst_n_raw = sw[9];
    wire rst_n;
    wire status;

    

    debouncer reset_debouncer (
        .clk(clk),
        .rst_n(1'b1),
        .in(rst_n_raw),
        .out(rst_n)
    );

    /*blink blink_test (
        .clk(clk),
        .rst_n(rst_n),
        .led(led)
    );*/

    wire control_stabilized;

    debouncer control_debouncer (
        .clk(clk),
        .rst_n(rst_n),
        .in(btn[0]),    
        .out(control_stabilized)
    );

    // Debounce
    wire sw0_stabilized, sw1_stabilized, sw2_stabilized, sw3_stabilized;

    debouncer sw0_debouncer (
        .clk(clk),
        .rst_n(rst_n),
        .in(sw[0]),
        .out(sw0_stabilized)
    );

    debouncer sw1_debouncer (
        .clk(clk),
        .rst_n(rst_n),
        .in(sw[1]),
        .out(sw1_stabilized)
    );

    debouncer sw2_debouncer (
        .clk(clk),
        .rst_n(rst_n),
        .in(sw[2]),
        .out(sw2_stabilized)
    );

    debouncer sw3_debouncer (
        .clk(clk),
        .rst_n(rst_n),
        .in(sw[3]),
        .out(sw3_stabilized)
    );

    // Combine the stabilized bits into a 4-bit value
    wire [3:0] sw_stabilized;
    assign sw_stabilized = {sw3_stabilized, sw2_stabilized, sw1_stabilized, sw0_stabilized};


    wire we;
    wire [ADDR_WIDTH - 1:0] addr;
    wire [DATA_WIDTH - 1:0] data;
    wire [DATA_WIDTH - 1:0] mem_out;
    wire [ADDR_WIDTH - 1:0] pc;
    wire [ADDR_WIDTH - 1:0] sp;
    wire [ADDR_WIDTH - 1:0] out_cpu_16;

    assign led[4:0] = out_cpu_16[4:0];

    assign led[5] = status;
    
    wire out_clk;
    clk_div #(.DIVISOR(10_000_000)) clk_div_inst (
        .clk(clk), .rst_n(rst_n), .out(out_clk)
    );


    cpu cpu_inst (
        .clk(out_clk),
        .rst_n(rst_n),
        .mem(mem_out),
        .in({12'b0, sw_stabilized}),       // input
        .we(we),
        .addr(addr),
        .data(data),
        .out(out_cpu_16), 
        .pc(pc),
        .sp(sp),
        .status(status),
        .control(btn[2])
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
