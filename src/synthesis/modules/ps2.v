/*module ps2 (
    input clk,           
    input rst_n,         
    input ps2_clk,       
    input ps2_data,      
    output [15:0] code   
);

    reg parity_reg, parity_next                            = 1'b0;
    reg [1:0] state_reg, state_next                        = 2'b00;
    reg [3:0] n_reg, n_next                                = 4'b00;
    reg [8:0] data_reg, data_next                          = 9'd0;
    
    reg [15:0] bin_code_reg, bin_code_next                 = 16'h0000;
    reg [15:0] display_bin_code_reg, display_bin_code_next = 16'h0000;
    reg  counter_reg, counter_next                         = 1'b0;

    assign code = display_bin_code_reg;

    localparam waitingForStart = 0;
    localparam sendingData     = 1;
    localparam endProcessing   = 2;
    localparam START           = 0;
    localparam STOP            = 1;

    always @(posedge clk, negedge rst_n ) begin
        if (!rst_n) begin
            state_reg            <= 2'd0;
            n_reg                <= 4'd0;
            data_reg             <= 9'd0;
            parity_reg           <= 1'd0;
            bin_code_reg         <= 16'd0;
            counter_reg          <= 1'd0;
            display_bin_code_reg <= 16'd0;
        end else begin
            state_reg            <= state_next;
            n_reg                <= n_next;
            data_reg             <= data_next;
            parity_reg           <= parity_next;
            bin_code_reg         <= bin_code_next;
            counter_reg          <= counter_next;
            display_bin_code_reg <= display_bin_code_next;
        end
    end

    always @(negedge ps2_clk) begin
        state_next            = state_reg;
        n_next                = n_reg;
        data_next             = data_reg;
        parity_next           = parity_reg;
        bin_code_next         = bin_code_reg;
        counter_next          = counter_reg;
        display_bin_code_next = display_bin_code_reg;

        case (state_reg)
            waitingForStart: begin
                if (ps2_data == START) begin
                    n_next     = 4'd9;
                    data_next  = 9'd0;
                    state_next = sendingData;
                    if (data_reg[7:0] != 8'he0 && data_reg[7:0] != 8'hf0) begin
                        bin_code_next = 16'd0;
                        // data_next     = 9'd0;
                    end
                end
            end
            sendingData: begin
                if (n_reg == 4'd9) begin
                    parity_next = ps2_data;
                end
                else begin
                    parity_next = parity_reg ^ ps2_data;
                end

                //data_next = (data_reg >> 1'b1) | ({ps2_data,{8{1'b0}}});
                
                if (n_reg == 4'd1) begin
                    state_next = endProcessing;
                end
                else begin
                    n_next = n_reg - 1'b1;
                end
            end
            endProcessing: begin
                if (ps2_data == STOP) begin
                    if (parity_reg) begin
                        // Treba iscrtati na hex!
                        bin_code_next = (bin_code_reg << 8) | data_reg[7:0];
                        if (counter_reg == 0 || data_reg[7:0] == 8'he0 || data_reg[7:0] == 8'hf0) begin
                            counter_next = 1;
                        end else begin
                            display_bin_code_next = bin_code_next;
                            counter_next = 0;
                        end
                    end
                    else begin
                        display_bin_code_next = 16'hFFFF; // greska
                    end
                    state_next = waitingForStart;
                end
            end
            default: begin
                
            end
        endcase
    end

endmodule
*/
module ps2 (
    input clk,
    input rst_n,
    input ps2_clk,
    input ps2_data,
    output [15:0] code
);

    reg [1:0] state_reg, state_next;
    reg [3:0] n_reg, n_next;
    reg [7:0] shift_reg, shift_next;
    reg parity_bit_reg, parity_bit_next;
    reg [15:0] code_reg, code_next;
    reg extended_reg, extended_next;
    reg release_reg, release_next;

    assign code = code_reg;

    localparam WAIT_START = 2'd0;
    localparam READ_BITS  = 2'd1;
    localparam PARITY     = 2'd2;
    localparam STOP       = 2'd3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg      <= WAIT_START;
            n_reg          <= 0;
            shift_reg      <= 0;
            parity_bit_reg <= 0;
            code_reg       <= 0;
            extended_reg   <= 0;
            release_reg    <= 0;
        end else begin
            state_reg      <= state_next;
            n_reg          <= n_next;
            shift_reg      <= shift_next;
            parity_bit_reg <= parity_bit_next;
            code_reg       <= code_next;
            extended_reg   <= extended_next;
            release_reg    <= release_next;
        end
    end

    always @(negedge ps2_clk) begin
        // default dodela
        state_next        = state_reg;
        n_next            = n_reg;
        shift_next        = shift_reg;
        parity_bit_next   = parity_bit_reg;
        code_next         = code_reg;
        extended_next     = extended_reg;
        release_next      = release_reg;

        case (state_reg)
            WAIT_START: begin
                if (ps2_data == 0) begin  // start bit
                    n_next       = 0;
                    shift_next   = 0;
                    state_next   = READ_BITS;
                end
            end

            READ_BITS: begin
                shift_next[n_reg] = ps2_data;
                if (n_reg == 7)
                    state_next = PARITY;
                else
                    n_next = n_reg + 1;
            end

            PARITY: begin
                parity_bit_next = ps2_data;
                state_next = STOP;
            end

            STOP: begin
                if (ps2_data == 1) begin // valid stop bit
                    if ((^shift_reg) == ~parity_bit_reg) begin
                        // valid frame
                        if (shift_reg == 8'hE0) begin
                            extended_next = 1;
                        end else if (shift_reg == 8'hF0) begin
                            release_next = 1;
                        end else begin
                            if (!release_reg) begin
                                code_next = {code_reg[7:0], shift_reg};
                            end
                            extended_next = 0;
                            release_next  = 0;
                        end
                    end
                end
                state_next = WAIT_START;
            end
        endcase
    end

endmodule
