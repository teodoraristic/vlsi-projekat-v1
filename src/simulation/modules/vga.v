module vga (
    input clk,
    input rst_n,
    input [23:0] code,
    output reg hsync,
    output reg vsync,
    output reg [3:0] red,
    output reg [3:0] green,
    output reg [3:0] blue
);

    // VGA Protokol radi na 640x480, refresh 60Hz
    // Potrebni su mi VGA parametri...
    localparam H_VISIBLE_AREA = 'd640;
    localparam H_FRONT_PORCH = 'd16;
    localparam H_SYNC_PULSE = 'd96;
    localparam H_BACK_PORCH = 'd48;
    localparam H_TOTAL = 'd800;

    localparam V_VISIBLE_AREA = 'd480;
    localparam V_FRONT_PORCH = 'd10;
    localparam V_SYNC_PULSE = 'd2;
    localparam V_BACK_PORCH = 'd33;
    localparam V_TOTAL = 'd525;

    reg [9:0] h_counter; // max = 799
    reg [9:0] v_counter; // max = 524 

    // Brojimo horizontalu
    always @(posedge clk, negedge rst_n ) begin
        if (!rst_n)
            h_counter <= 0;
        else if (h_counter == H_TOTAL - 1)
            h_counter <= 0;
        else
            h_counter <= h_counter + 1;
    end

    // Brojimo vertikalu
    always @(posedge clk, negedge rst_n ) begin
        if (!rst_n)
            v_counter <= 0;
        else if (h_counter == H_TOTAL - 1) begin
            if (v_counter == V_TOTAL - 1)
                v_counter <= 0;
            else
                v_counter <= v_counter + 1;
        end
    end

    // Generisanje hsync i vsync
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else begin
            hsync <= ~( (h_counter >= (H_VISIBLE_AREA + H_FRONT_PORCH)) 
            && (h_counter < (H_VISIBLE_AREA + H_FRONT_PORCH + H_SYNC_PULSE)) );
            
            vsync <= ~( (v_counter >= (V_VISIBLE_AREA + V_FRONT_PORCH))
            && (v_counter < (V_VISIBLE_AREA + V_FRONT_PORCH + V_SYNC_PULSE)) );
        end 
    end

    wire video_on;
    assign video_on = (h_counter < H_VISIBLE_AREA) && (v_counter < V_VISIBLE_AREA);

    // Izbor boje HORIZONTALNO!
    reg [11:0] curr_color;

    always @(*) begin
        if (!video_on) begin
            // Van vidljivog dela, crna boja
            curr_color = 12'b0;
        end else if (h_counter < (H_VISIBLE_AREA / 2)) begin
            // Leva polovina ekrana
            curr_color = code[23:12];
        end else begin
            // Desna polovina ekrana
            curr_color = code[11:0];
        end
    end

    // RGB
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            red <= 4'b0000;
            green <= 4'b0000;
            blue <= 4'b0000;
        end else if (video_on) begin
            red   <= curr_color[11:8];
            green <= curr_color[7:4];
            blue  <= curr_color[3:0];
        end else begin
            red   <= 4'b0000;
            green <= 4'b0000;
            blue  <= 4'b0000;
        end
    end


endmodule