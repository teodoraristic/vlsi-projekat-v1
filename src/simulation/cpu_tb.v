`timescale 1ns / 1ps

module cpu_tb;

  reg clk;
  reg rst_n;

  wire we;
  wire [5:0] addr;
  wire [15:0] data;
  wire [15:0] mem_out;
  wire [15:0] in = 16'd8;
  wire [5:0] pc;
  wire [5:0] sp;

  reg [15:0] mem_array [0:63];
  reg [15:0] mem_reg;
  

  // CPU instanca
  cpu cpu_inst (
    .clk(clk),
    .rst_n(rst_n),
    .mem(mem_out),
    .in(in),
    .we(we),
    .addr(addr),
    .data(data),
    .out(), 
    .pc(pc),
    .sp(sp)
  );

  memory #(
        .FILE_NAME("mem_init copy.mif"),
        .ADDR_WIDTH(3'd6),
        .DATA_WIDTH(5'd16)
    ) mem_inst (
        .clk(clk),
        .we(we),
        .addr(addr),
        .data(data),
        .out(mem_out)
    );

  // Clock
  initial clk = 0;
  always #10 clk = ~clk;

  // Reset sekvenca
  initial begin
    

    rst_n = 0;
    #50;
    rst_n = 1;

    //wait(cpu_inst.halted);

    //$display("PC je dostigao 63 na vremenu %0t, simulacija završena.", $time);
    //#10;
    //$finish;
  end

  // Praćenje promena PC + dodatnih signala
  reg [5:0] prev_state;
  reg [15:0] prev_mdr;
  reg [15:0] prev_out;

  initial begin
    prev_state = 4'd0;
    prev_mdr = 15'd0;
  end

  initial begin
   #100000; // ili koliko već treba max vremena
    $display("Simulacija timeout. Kraj na %0t", $time);
    $finish;
  end

  always @(posedge clk) begin
    if (cpu_inst.state_reg !== prev_state || cpu_inst.out !== prev_out) begin
      $display("Vreme: %0t | PC=%d | MDR=%h | MAR=%d | ADDR=%d | IR=%h | mem=%h | STATE=%d  | DATA=%h | op_alu = %b | OPCODE = %b | OUT = %h ", 
               $time, pc, cpu_inst.mdr_out, cpu_inst.mar_out, addr, cpu_inst.ir_out, cpu_inst.mem, cpu_inst.state_reg, data, cpu_inst.alu_op_code, cpu_inst.opcode, cpu_inst.out);
      prev_state <= cpu_inst.state_reg;
      prev_out <= cpu_inst.out;
    end
  end

  always @(posedge clk) begin
    if (cpu_inst.state_reg !== prev_state || cpu_inst.out !== prev_out) begin
      $display("Vreme: %0t | PC=%d | MDR=%h | MAR=%d | ADDR=%d | IR=%h | mem=%h | STATE=%d  | DATA=%h | op_alu = %b | OPCODE = %b | OUT = %h | STATUS = %h", 
               $time, pc, cpu_inst.mdr_out, cpu_inst.mar_out, addr, cpu_inst.ir_out, cpu_inst.mem, cpu_inst.state_reg, data, cpu_inst.alu_op_code, cpu_inst.opcode, cpu_inst.out, cpu_inst.status);
      prev_state <= cpu_inst.state_reg;
      prev_out <= cpu_inst.out;
    end
  end

endmodule
