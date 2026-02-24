module vga (
    input clk,        // 25MHz pixel clock
    input rst_n,
    input [23:0] code,
    output reg hsync,
    output reg vsync,
    output reg [3:0] red,
    output reg [3:0] green,
    output reg [3:0] blue
);
    // VGA 640x480 @ 60Hz parametri (25MHz pixel clock)
    localparam H_VISIBLE    = 10'd640;
    localparam H_FRONT_PORCH = 10'd16;
    localparam H_SYNC_PULSE  = 10'd96;
    localparam H_BACK_PORCH  = 10'd48;
    localparam H_TOTAL       = 10'd800;  // 640+16+96+48

    localparam V_VISIBLE    = 10'd480;
    localparam V_FRONT_PORCH = 10'd10;
    localparam V_SYNC_PULSE  = 10'd2;
    localparam V_BACK_PORCH  = 10'd33;
    localparam V_TOTAL       = 10'd525;  // 480+10+2+33

    // Brojaci
    reg [9:0] h_cnt, v_cnt;

    // Horizontalni brojac
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            h_cnt <= 10'd0;
        else if (h_cnt == H_TOTAL - 1)
            h_cnt <= 10'd0;
        else
            h_cnt <= h_cnt + 10'd1;
    end

    // Vertikalni brojac
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            v_cnt <= 10'd0;
        else if (h_cnt == H_TOTAL - 1) begin
            if (v_cnt == V_TOTAL - 1)
                v_cnt <= 10'd0;
            else
                v_cnt <= v_cnt + 10'd1;
        end
    end

    // Vidljivi region
    wire video_on = (h_cnt < H_VISIBLE) && (v_cnt < V_VISIBLE);

    // hsync i vsync (aktivni nisko za 640x480)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else begin
            hsync <= ~((h_cnt >= H_VISIBLE + H_FRONT_PORCH) &&
                       (h_cnt <  H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE));
            vsync <= ~((v_cnt >= V_VISIBLE + V_FRONT_PORCH) &&
                       (v_cnt <  V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE));
        end
    end

    // RGB izlaz
    // code[23:12] = leva polovina, code[11:0] = desna polovina
    // svaka boja je {R[3:0], G[3:0], B[3:0]}
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            red   <= 4'b0;
            green <= 4'b0;
            blue  <= 4'b0;
        end else begin
            if (!video_on) begin
                red   <= 4'b0;
                green <= 4'b0;
                blue  <= 4'b0;
            end else if (h_cnt < (H_VISIBLE / 2)) begin
                // Leva polovina
                red   <= code[23:20];
                green <= code[19:16];
                blue  <= code[15:12];
            end else begin
                // Desna polovina
                red   <= code[11:8];
                green <= code[7:4];
                blue  <= code[3:0];
            end
        end
    end

endmodule
