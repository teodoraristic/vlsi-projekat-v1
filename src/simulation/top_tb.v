`timescale 1ns / 1ps

module top_tb;

    // Parametri top modula
    parameter DIVISOR = 50_000_000;
    parameter FILE_NAME = "mem_init copy.mif";
    parameter ADDR_WIDTH = 6;
    parameter DATA_WIDTH = 16;

    // Signali
    reg clk;
    reg rst_n;
    reg [1:0] kbd;
    reg [2:0] btn;
    reg [9:0] sw;
    wire [13:0] mnt;
    wire [9:0] led;
    wire [27:0] ssd;

    // Instanca top modula (koji uključuje CPU)
    top #(
        .DIVISOR(DIVISOR),
        .FILE_NAME(FILE_NAME),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .kbd(kbd),
        .btn(btn),
        .sw(sw),
        .mnt(mnt),
        .led(led),
        .ssd(ssd)
    );

    // Clock generator: 50 MHz
    initial clk = 0;
    always #10 clk = ~clk;  // 20ns period = 50 MHz

    // Reset sekvenca
    initial begin
        rst_n = 0;
        #50;
        rst_n = 1;
    end

    // Praćenje promena PC, MDR, IR, STATE, itd.
    reg [5:0] prev_pc;
    reg [15:0] prev_mdr;
    reg [15:0] prev_out;
    reg [4:0] prev_state;

    initial begin
        prev_pc = 6'd0;
        prev_mdr = 16'd0;
        prev_out = 16'd0;
        prev_state = 5'd0;
    end

    // Timeout za simulaciju
    initial begin
        #1000000; // ili koliko već treba max vremena
        $display("Simulacija timeout. Kraj na %0t", $time);
        $finish;
    end

    // Praćenje promena
    always @(posedge clk) begin
        // Praćenje PC, MDR, OUT, STATE, itd.
        if (uut.cpu_inst.pc != prev_pc || 
            uut.cpu_inst.mdr_out != prev_mdr || 
            uut.cpu_inst.out != prev_out || 
            uut.cpu_inst.state_reg != prev_state) 
        begin
            $display("Vreme: %0t | PC=%d | MDR=%h | MAR=%d | ADDR=%d | IR=%h | STATE=%d  | DATA=%h | op_alu=%b | OPCODE=%b | OUT=%h", 
                     $time, 
                     uut.cpu_inst.pc, 
                     uut.cpu_inst.mdr_out, 
                     uut.cpu_inst.mar_out, 
                     uut.addr, 
                     uut.cpu_inst.ir_out, 
                     uut.cpu_inst.state_reg, 
                     uut.data, 
                     uut.cpu_inst.alu_op_code, 
                     uut.cpu_inst.opcode, 
                     uut.cpu_inst.out);

            // Ažuriraj prethodne vrednosti
            prev_pc <= uut.cpu_inst.pc;
            prev_mdr <= uut.cpu_inst.mdr_out;
            prev_out <= uut.cpu_inst.out;
            prev_state <= uut.cpu_inst.state_reg;
        end
    end

endmodule
