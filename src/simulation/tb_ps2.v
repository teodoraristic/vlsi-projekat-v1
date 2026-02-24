`timescale 1ns / 1ps

module tb_ps2;

    reg clk;
    reg rst_n;
    reg ps2_clk;
    reg ps2_data;
    wire [15:0] code;

    // Instanciranje tvog modula
    ps2 uut (
        .clk(clk),
        .rst_n(rst_n),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .code(code)
    );

    // Generisanje sistemskog takta, npr 50 MHz (20ns period)
    initial clk = 0;
    always #10 clk = ~clk;

    // PS/2 clock - sporiji, npr ~10 kHz (period 100us = 100000ns)
    initial begin
        ps2_clk = 1;
        forever #50000 ps2_clk = ~ps2_clk; // 10kHz frekvencija
    end

    // Simulacija reset-a
    initial begin
        rst_n = 0;
        ps2_data = 1; // Idle stanje na ps2_data liniji
        #100;
        rst_n = 1;
    end

    // Task za slanje jednog PS/2 bajta
    task send_ps2_byte(input [7:0] byte);
        integer i;
        reg parity;
        begin
            parity = 1'b1; // Odd parity

            // Start bit (0)
            @(negedge ps2_clk);
            ps2_data = 0;

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                @(negedge ps2_clk);
                ps2_data = byte[i];
                parity = parity ^ byte[i];
            end

            // Parity bit
            @(negedge ps2_clk);
            ps2_data = parity;

            // Stop bit (1)
            @(negedge ps2_clk);
            ps2_data = 1;

            // Idle stanje - barem jedan ciklus ps2_clk visok
            @(posedge ps2_clk);
        end
    endtask

    // Glavna test sekvenca
    initial begin
        // Sačekaj reset i sinhronizaciju
        @(posedge rst_n);

        // Daj malo vremena posle reset-a
        #1000;

        $display("Slanje bajta 0x1C (taster 'A')");
        send_ps2_byte(8'h1C);

        #2000000; // pauza između bajtova da modul procesuira

        $display("Slanje bajta 0xF0 (release kod)");
        send_ps2_byte(8'hF0);

        #2000000;

        $display("Slanje bajta 0x1C (taster 'A') ponovo");
        send_ps2_byte(8'h1C);

        #2000000;

        $finish;
    end

    // Monitoring output-a
    //initial begin
    //    $monitor("time=%0t | code = %h", $time, code);
    //end

    // Monitoring promene izlaza 'code'
    reg [15:0] code_prev;
    initial code_prev = 16'h0000;

    always @(posedge clk) begin
        if (code != code_prev) begin
            $display("time=%0t | code promenjen: %h", $time, code);
            code_prev <= code;
        end
    end

endmodule
