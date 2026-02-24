module tb;
    reg [5:0] addr;
    reg [15:0] data;
    reg we, clk;
    wire [15:0] out;
    integer index;
    dut dut_inst(clk, we, addr, data, out);
    
    always begin
        #5 clk = ~clk;
    end
    initial begin
        clk = 1'b0;
        we = 1'b0;
        addr = 6'b0;
        data = 16'b0;
        $display("Popunjavanje memorije...");
        $monitor("Addr: %d: Data: %4h", addr, data);
        for (index = 0; index < 64; index = index + 1) begin
            data = $random;
            we = 1;
            addr = index;
            #10;
            we = 0;
            #10;
        end
        $stop;
        $monitoroff;
        for (index = 0; index < 100; index = index + 1) begin
            addr = $random % 64;
            #10;
            $display("Addr %d: OUT: %4h", addr, out);
        end
        $finish;
    end
    
endmodule