/*module top;

    reg [2:0] oc;
    reg [3:0] a, b;
    wire [3:0] f;

    integer index;

    alu alu_inst(oc, a, b, f);

    reg clk, rst_n, cl, ld, inc, dec, sr, ir, sl, il;
    reg [3:0] in;
    wire [3:0] out;

    register register_inst(clk, rst_n, cl, ld, in, inc, dec, sr, ir, sl, il, out);

    initial begin
        $monitor("Time: %d, oc: %b, a: %b, b: %b, f: %f", $time, oc, a, b, f);
        for (index = 0; index < 2048; index = index + 1) begin
            {oc, a, b} = index;
            #5;
        end
        $stop;
        
        rst_n = 1'b0; clk = 1'b0; ld = 1'b0; inc = 1'b0; dec = 1'b0; 
        sr = 1'b0; sl = 1'b0; ir = 1'b0; il = 1'b0; in = 4'h0; 
        #2 rst_n = 1'b1;
        
        repeat (1000) begin
            #5;
            cl = $urandom % 2;
            ld = $urandom % 2;
            inc = $urandom % 2;
            dec = $urandom % 2;
            sr = $urandom % 2;
            sl = $urandom % 2;
            ir = $urandom % 2;
            il = $urandom % 2;
            in = $urandom_range(15);
        end
        #10 $finish;
    end

    always begin 
        #5 clk = ~clk;
    end

    always @(out) begin
        $display("Izlaz = %d, Ulaz = %d, clk = %d, rst_n = %d, cl = %d, ld = %d, inc = %d, dec = %d, sr = %d, ir = %d, sl = %d, il = %d",
       out, in, clk, rst_n, cl, ld, inc, dec, sr, ir, sl, il);
    end

endmodule*/