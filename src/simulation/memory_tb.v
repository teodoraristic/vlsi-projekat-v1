`timescale 1ns/1ps

module memory_tb;

    // Parametri
    parameter ADDR_WIDTH = 6;
    parameter DATA_WIDTH = 16;
    parameter MEM_DEPTH = 1 << ADDR_WIDTH;

    reg clk;
    reg we;
    reg [ADDR_WIDTH-1:0] addr;
    reg [DATA_WIDTH-1:0] data;
    wire [DATA_WIDTH-1:0] out;

    
    // Instanca memorije
    memory #(
        .FILE_NAME("mem_init copy.mif"),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) mem_inst (
        .clk(clk),
        .we(we),
        .addr(addr),
        .data(data),
        .out(out)
    );

    
    // Clock signal
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns perioda
    end
    integer i;
    // Test logika (samo čitanje)
    initial begin
        we = 0;        // samo čitamo
        data = 16'h0000;

        // Čekamo da se RAM učita
        #20;

        // Čitanje nekoliko adresa iz memorije
        for (i = 0; i < 16; i = i + 1) begin
            addr = i[ADDR_WIDTH-1:0];
            #10;  // čekaj 1 ciklus posle promene adrese
            $display("Time: %0t | Addr: %0h | Out: %0h", $time, addr, out);
        end

        $finish;
    end

endmodule
