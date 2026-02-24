module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
)(
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] mem,
    input [DATA_WIDTH-1:0] in,
    input control,
    output status,
    output we,
    output [ADDR_WIDTH-1:0] addr,
    output [DATA_WIDTH-1:0] data,
    output [DATA_WIDTH-1:0] out,
    output [ADDR_WIDTH-1:0] pc,
    output [ADDR_WIDTH-1:0] sp
);

    // ALU
    localparam [2:0] ALU_ADD = 3'b000;
    localparam [2:0] ALU_SUB = 3'b001;
    localparam [2:0] ALU_MUL = 3'b010;

    reg [2:0] alu_oc_d, alu_oc_q;
    reg [DATA_WIDTH-1:0] alu_a_d, alu_a_q;
    reg [DATA_WIDTH-1:0] alu_b_d, alu_b_q;
    wire [DATA_WIDTH-1:0] alu_f;

    alu #(.DATA_WIDTH(DATA_WIDTH)) ALU (
        .oc(alu_oc_q),
        .a (alu_a_q),
        .b (alu_b_q),
        .f (alu_f)
    );

    // Opcodes
    localparam [3:0] OP_MOV = 4'b0000;
    localparam [3:0] OP_ADD = 4'b0001;
    localparam [3:0] OP_SUB = 4'b0010;
    localparam [3:0] OP_MUL = 4'b0011;
    localparam [3:0] OP_DIV = 4'b0100;
    localparam [3:0] OP_IN = 4'b0111;
    localparam [3:0] OP_OUT = 4'b1000;
    localparam [3:0] OP_STOP = 4'b1111;

    // States
    localparam [7:0]
        S_RESET = 8'd0,
        S_FETCH_MAR = 8'd1,
        S_FETCH_MDR = 8'd2,
        S_FETCH_IR = 8'd3,
        S_DECODE = 8'd4,
        S_EAX_START = 8'd5,
        S_EAX_PTR_MDR = 8'd6,
        S_EAX_DONE = 8'd7,
        S_EAY_START = 8'd8,
        S_EAY_PTR_MDR = 8'd9,
        S_EAY_DONE = 8'd10,
        S_EAZ_START = 8'd11,
        S_EAZ_PTR_MDR = 8'd12,
        S_EAZ_DONE = 8'd13,
        S_RDY_MAR = 8'd14,
        S_RDY_MDR = 8'd15,
        S_RDZ_MAR = 8'd16,
        S_RDZ_MDR = 8'd17,
        S_MOV_WB = 8'd18,
        S_ALU_EXEC = 8'd19,
        S_ALU_WB = 8'd20,
        S_IN_WB = 8'd21,
        S_OUT_MAR = 8'd22,
        S_OUT_MDR = 8'd23,
        S_OUT_DONE = 8'd24,
        S_STOP_NEXT = 8'd25,
        S_STOP_MDR = 8'd26,
        S_STOP_OUT = 8'd27,
        S_NEXT_FETCH = 8'd28,
        S_HALT = 8'd29,
        S_FETCH_MDR_W = 8'd30,
        S_RDY_MDR_W = 8'd31,
        S_OUT_MDR_W = 8'd32,
        S_RDY_MAR_W = 8'd33,
        S_RDZ_MDR_W = 8'd34,
        S_RDZ_MAR_W = 8'd35,
        S_EAX_PTR_MDR_W = 8'd36,
        S_EAY_PTR_MDR_W = 8'd37,
        S_EAZ_PTR_MDR_W = 8'd38,
        S_STOP_MDR_W = 8'd39,
        S_FETCH_MAR_2 = 8'd40,
        S_FETCH_MDR_2 = 8'd41,
        S_FETCH_MDR_W_2 = 8'd42,
        S_FETCH_IR_2 = 8'd43
    ;

    reg [7:0] state_d, state_q;

    // PC
    reg [ADDR_WIDTH-1:0] pc_in_d;  
    reg pc_cl_d, pc_ld_d, pc_inc_d, pc_dec_d;
    wire [ADDR_WIDTH-1:0] pc_out;
    register #(.DATA_WIDTH(ADDR_WIDTH)) PC_REG (
        .clk(clk), .rst_n(rst_n),
        .cl(pc_cl_d), .ld(pc_ld_d), .in(pc_in_d),
        .inc(pc_inc_d), .dec(pc_dec_d),
        .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(pc_out)
    );
    assign pc = pc_out;

    // SP
    reg [ADDR_WIDTH-1:0] sp_in_d;
    reg sp_cl_d, sp_ld_d, sp_inc_d, sp_dec_d;
    wire [ADDR_WIDTH-1:0] sp_out;
    register #(.DATA_WIDTH(ADDR_WIDTH)) SP_REG (
        .clk(clk), .rst_n(rst_n),
        .cl(sp_cl_d), .ld(sp_ld_d), .in(sp_in_d),
        .inc(sp_inc_d), .dec(sp_dec_d),
        .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(sp_out)
    );
    assign sp = sp_out;

    // IR
    reg [31:0] ir_in_d; 
    reg ir_cl_d, ir_ld_d;
    wire [31:0] ir_out;
    register #(.DATA_WIDTH(32)) IR_REG (
        .clk(clk), .rst_n(rst_n),
        .cl(ir_cl_d), .ld(ir_ld_d), .in(ir_in_d),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(ir_out)
    );

    // MAR
    reg [ADDR_WIDTH-1:0] mar_in_d; 
    reg mar_cl_d, mar_ld_d;
    wire [ADDR_WIDTH-1:0] mar_out;
    register #(.DATA_WIDTH(ADDR_WIDTH)) MAR_REG (
        .clk(clk), .rst_n(rst_n),
        .cl(mar_cl_d), .ld(mar_ld_d), .in(mar_in_d),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(mar_out)
    );
    assign addr = mar_out;

    // MDR
    reg [DATA_WIDTH-1:0] mdr_in_d; 
    reg mdr_cl_d, mdr_ld_d;
    wire [DATA_WIDTH-1:0] mdr_out;
    register #(.DATA_WIDTH(DATA_WIDTH)) MDR_REG (
        .clk(clk), .rst_n(rst_n),
        .cl(mdr_cl_d), .ld(mdr_ld_d), .in(mdr_in_d),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(mdr_out)
    );

    reg [DATA_WIDTH-1:0] acl_in_d;
    reg acl_cl_d, acl_ld_d;
    wire [DATA_WIDTH-1:0] acl_out;
    register #(.DATA_WIDTH(DATA_WIDTH)) ACL_REG (
        .clk(clk), .rst_n(rst_n),
        .cl(acl_cl_d), .ld(acl_ld_d), .in(acl_in_d),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(acl_out)
    );

    reg we_d, we_q;
    reg [DATA_WIDTH-1:0] data_d, data_q;
    reg [DATA_WIDTH-1:0] out_d, out_q;
    reg status_d, status_q;

    assign we = we_q;
    assign data = data_q;
    assign out = out_q;
    assign status = status_d;

    // IR
    wire [15:0] ir16 = ir_out[15:0];
    wire [3:0] opcode = ir16[15:12];
    wire [3:0] Xo = ir16[11:8];
    wire [3:0] Yo = ir16[7:4];
    wire [3:0] Zo = ir16[3:0];

    wire X_ind = Xo[3];
    wire Y_ind = Yo[3];
    wire Z_ind = Zo[3];
    wire [2:0] X_reg = Xo[2:0];
    wire [2:0] Y_reg = Yo[2:0];
    wire [2:0] Z_reg = Zo[2:0];

    wire [ADDR_WIDTH-1:0] X_dir_addr = {{(ADDR_WIDTH-3){1'b0}}, X_reg};
    wire [ADDR_WIDTH-1:0] Y_dir_addr = {{(ADDR_WIDTH-3){1'b0}}, Y_reg};
    wire [ADDR_WIDTH-1:0] Z_dir_addr = {{(ADDR_WIDTH-3){1'b0}}, Z_reg};

    // EA
    reg [ADDR_WIDTH-1:0] EA_x_d, EA_x_q;
    reg [ADDR_WIDTH-1:0] EA_y_d, EA_y_q;
    reg [ADDR_WIDTH-1:0] EA_z_d, EA_z_q;

    reg [DATA_WIDTH-1:0] Y_val_d, Y_val_q;
    reg [DATA_WIDTH-1:0] Z_val_d, Z_val_q;

    reg [1:0] stop_phase_d, stop_phase_q;

    reg x_ptr_d, x_ptr_q, y_ptr_d, y_ptr_q, z_ptr_d, z_ptr_q;

    task set_defaults;
    begin
        we_d = 1'b0;
        data_d = data_q;
        out_d = out_q;
        status_d = 1'b0;

        pc_cl_d=1'b0; pc_ld_d=1'b0; pc_inc_d=1'b0; pc_dec_d=1'b0; pc_in_d = {ADDR_WIDTH{1'b0}};
        sp_cl_d=1'b0; sp_ld_d=1'b0; sp_inc_d=1'b0; sp_dec_d=1'b0; sp_in_d = {ADDR_WIDTH{1'b0}};
        mar_cl_d=1'b0; mar_ld_d=1'b0; mar_in_d = {ADDR_WIDTH{1'b0}};
        mdr_cl_d=1'b0; mdr_ld_d=1'b0; mdr_in_d = {DATA_WIDTH{1'b0}};
        ir_cl_d =1'b0; ir_ld_d =1'b0; ir_in_d = 32'd0;
        acl_cl_d=1'b0; acl_ld_d=1'b0; acl_in_d = {DATA_WIDTH{1'b0}};

        alu_oc_d = alu_oc_q;
        alu_a_d = alu_a_q;
        alu_b_d = alu_b_q;

        EA_x_d = EA_x_q; EA_y_d = EA_y_q; EA_z_d = EA_z_q;
        Y_val_d = Y_val_q; Z_val_d = Z_val_q;
        stop_phase_d = stop_phase_q;

        x_ptr_d = x_ptr_q; y_ptr_d = y_ptr_q; z_ptr_d = z_ptr_q;

        state_d = state_q;
    end
    endtask

    always @(*) begin
        set_defaults();

        case (state_q)
            // 0
            S_RESET: begin
                pc_ld_d = 1'b1;
                pc_in_d = {{(ADDR_WIDTH-3){1'b0}}, 3'd1} << 3;
                sp_ld_d = 1'b1;
                sp_in_d = {ADDR_WIDTH{1'b1}};
                ir_cl_d = 1'b1;
                mdr_cl_d = 1'b1;
                mar_cl_d = 1'b1;
                status_d = 1'b0;

                state_d = S_FETCH_MAR;
            end

            //1
            S_FETCH_MAR: begin
                mar_ld_d = 1'b1;
                mar_in_d = pc_out;
                state_d = S_FETCH_MDR;
            end

            //2
            S_FETCH_MDR: begin
                state_d = S_FETCH_MDR_W;
            end

            //28
            S_FETCH_MDR_W: begin
                mdr_in_d = mem;
                mdr_ld_d = 1'b1;
                state_d = S_FETCH_IR;
            end

            //3
            S_FETCH_IR: begin
                ir_in_d = {16'b0, mdr_out};
                ir_ld_d = 1'b1;
                pc_inc_d = 1'b1;

                x_ptr_d = 1'b0;
                y_ptr_d = 1'b0;
                z_ptr_d = 1'b0;
                state_d = S_DECODE;
            end

            //4
            S_DECODE: begin
                if (opcode != OP_IN && opcode != OP_ADD && opcode != OP_DIV && opcode != OP_MOV && opcode != OP_MUL && opcode != OP_OUT && opcode != OP_STOP && opcode != OP_SUB) state_d = S_FETCH_MAR_2;
                else state_d = S_EAX_START;
            end

            S_FETCH_MAR_2: begin
                mar_ld_d = 1'b1;
                mar_in_d = pc_out;
                state_d = S_FETCH_MDR_2;
            end
            //2
            S_FETCH_MDR_2: begin
                state_d = S_FETCH_MDR_W_2;
            end

            //28
            S_FETCH_MDR_W_2: begin
                mdr_in_d = mem;
                mdr_ld_d = 1'b1;
                state_d = S_FETCH_IR_2;
            end

            //3
            S_FETCH_IR_2: begin
                ir_in_d = {mdr_out, ir16};
                ir_ld_d = 1'b1;
                pc_inc_d = 1'b1;

                x_ptr_d = 1'b0;
                y_ptr_d = 1'b0;
                z_ptr_d = 1'b0;
                state_d = S_EAX_START;
            end

            //5
            // EA X
            S_EAX_START: begin
                if (Xo == 4'b0000) begin
                    EA_x_d = {ADDR_WIDTH{1'b0}};
                    x_ptr_d = 1'b0;
                    state_d = S_EAX_DONE;
                end else if (X_ind) begin
                    mar_ld_d = 1'b1;
                    mar_in_d = X_dir_addr;
                    x_ptr_d = 1'b1;
                    state_d = S_EAX_PTR_MDR;
                end else begin
                    EA_x_d = X_dir_addr;
                    x_ptr_d = 1'b0;
                    state_d = S_EAX_DONE;
                end
            end

            //6
            S_EAX_PTR_MDR: begin
                state_d = S_EAX_PTR_MDR_W;
            end

            //
            S_EAX_PTR_MDR_W: begin
                mdr_in_d = mem;
                mdr_ld_d = 1'b1;
                state_d = S_EAX_DONE;
            end

            //7
            S_EAX_DONE: begin
                if (x_ptr_q) EA_x_d = mdr_out[ADDR_WIDTH-1:0];
                state_d = S_EAY_START;
            end

            //8
            // EA Y
            S_EAY_START: begin
                if (Yo == 4'b0000) begin
                    EA_y_d = {ADDR_WIDTH{1'b0}};
                    y_ptr_d = 1'b0;
                    state_d = S_EAY_DONE;
                end else if (Y_ind) begin
                    mar_ld_d = 1'b1;
                    mar_in_d = Y_dir_addr;
                    y_ptr_d = 1'b1;
                    state_d = S_EAY_PTR_MDR;
                end else begin
                    EA_y_d  = Y_dir_addr;
                    y_ptr_d = 1'b0;
                    state_d = S_EAY_DONE;
                end
            end

            //9
            S_EAY_PTR_MDR: begin
                state_d = S_EAY_PTR_MDR_W;
            end

            S_EAY_PTR_MDR_W: begin
                mdr_in_d = mem;
                mdr_ld_d = 1'b1;
                state_d = S_EAY_DONE;
            end

            //10
            S_EAY_DONE: begin
                if (y_ptr_q) EA_y_d = mdr_out[ADDR_WIDTH-1:0];

                if (opcode==OP_MOV && Zo==4'b0000) begin
                    state_d = S_RDY_MAR;
                end else if (opcode==OP_OUT) begin
                    state_d = S_OUT_MAR;
                end else if (opcode==OP_IN) begin
                    status_d = 1'b1;
                    state_d = S_IN_WB;
                end else if (opcode==OP_STOP) begin
                    stop_phase_d = 2'd0;
                    state_d = S_STOP_NEXT;
                end else begin
                    state_d = S_EAZ_START;
                end
            end

            //11
            // EA Z
            S_EAZ_START: begin
                if (Zo == 4'b0000) begin
                    EA_z_d = {ADDR_WIDTH{1'b0}};
                    z_ptr_d = 1'b0;
                    state_d = S_RDY_MAR;
                end else if (Z_ind) begin
                    mar_ld_d = 1'b1;
                    mar_in_d = Z_dir_addr;
                    z_ptr_d = 1'b1;
                    state_d = S_EAZ_PTR_MDR;
                end else begin
                    EA_z_d = Z_dir_addr;
                    z_ptr_d = 1'b0;
                    state_d = S_RDY_MAR;
                end
            end
            //12
            S_EAZ_PTR_MDR: begin
                state_d = S_EAZ_PTR_MDR_W;
            end
            //12
            S_EAZ_PTR_MDR_W: begin
                mdr_in_d = mem;
                mdr_ld_d = 1'b1;
                state_d = S_EAZ_DONE;
            end
            //13
            S_EAZ_DONE: begin
                if (z_ptr_q) EA_z_d = mdr_out[ADDR_WIDTH-1:0];
                state_d = S_RDY_MAR;
            end

            //14
            // Y then Z
            S_RDY_MAR: begin
                mar_ld_d = 1'b1; mar_in_d = EA_y_q;
                state_d = S_RDY_MAR_W;
            end
            //33
            S_RDY_MAR_W: begin
                state_d = S_RDY_MDR;
            end
            //15
            S_RDY_MDR: begin
                mdr_in_d = mem; mdr_ld_d = 1'b1;
                state_d = S_RDY_MDR_W;
            end
            //31
            S_RDY_MDR_W: begin
                state_d = (opcode==OP_MOV && Zo==4'b0000) ? S_MOV_WB : S_RDZ_MAR;
                Y_val_d = mdr_out;
            end
            //16
            S_RDZ_MAR: begin
                mar_ld_d = 1'b1;
                mar_in_d = EA_z_q;
                state_d = S_RDZ_MAR_W;
            end
            S_RDZ_MAR_W: begin
                state_d = S_RDZ_MDR;
            end
            //17
            S_RDZ_MDR: begin
                mdr_in_d = mem; mdr_ld_d = 1'b1;
                state_d = S_RDZ_MDR_W;
            end
            S_RDZ_MDR_W: begin
                state_d = S_ALU_EXEC;
                Z_val_d = mdr_out;
            end
            //18
            // MOV
            S_MOV_WB: begin
                we_d = 1'b1;
                data_d = Y_val_q;
                mar_ld_d = 1'b1; 
                mar_in_d = EA_x_q;
                state_d = S_NEXT_FETCH;
            end
            //19
            // ALU
            S_ALU_EXEC: begin
                case (opcode)
                    OP_ADD: alu_oc_d = ALU_ADD;
                    OP_SUB: alu_oc_d = ALU_SUB;
                    OP_MUL: alu_oc_d = ALU_MUL;
                    default: alu_oc_d = ALU_ADD;
                endcase
                alu_a_d = Y_val_q;
                alu_b_d = Z_val_q;
                state_d = S_ALU_WB;
            end
            //20
            S_ALU_WB: begin
                we_d = 1'b1;
                data_d = alu_f;
                mar_ld_d = 1'b1;
                mar_in_d = EA_x_q;
                state_d = S_NEXT_FETCH;
            end

            // IN
            S_IN_WB: begin
                if (control == 1'b1) begin 
                    we_d = 1'b1;
                    data_d = in;
                    mar_ld_d = 1'b1;
                    mar_in_d = EA_x_q;
                    state_d = S_NEXT_FETCH;
                end else begin
                    status_d = 1'b1;
                    state_d = S_IN_WB;
                end
            end

            // OUT
            S_OUT_MAR: begin
                mar_ld_d = 1'b1;
                mar_in_d = EA_x_q;
                state_d = S_OUT_MDR;
            end
            S_OUT_MDR: begin
                state_d = S_OUT_MDR_W;
            end
            S_OUT_MDR_W: begin
                mdr_in_d = mem;
                mdr_ld_d = 1'b1;
                state_d = S_OUT_DONE;
            end
            S_OUT_DONE: begin
                out_d = mdr_out;
                state_d = S_NEXT_FETCH;
            end

            // STOP
            S_STOP_NEXT: begin
                if (stop_phase_q == 2'd0) begin
                    if (Xo == 4'b0000) begin
                        stop_phase_d = 2'd1;
                        state_d = S_STOP_NEXT;
                    end else begin
                        mar_ld_d = 1'b1; 
                        mar_in_d = EA_x_q;
                        state_d = S_STOP_MDR;
                    end
                end else if (stop_phase_q == 2'd1) begin
                    if (Yo == 4'b0000) begin
                        stop_phase_d = 2'd2;
                        state_d = S_STOP_NEXT;
                    end else begin
                        mar_ld_d = 1'b1;
                        mar_in_d = EA_y_q;
                        state_d = S_STOP_MDR;
                    end
                end else begin
                    if (Zo == 4'b0000) begin
                        state_d = S_HALT;
                    end else begin
                        mar_ld_d = 1'b1;
                        mar_in_d = EA_z_q;
                        state_d = S_STOP_MDR;
                    end
                end
            end
            S_STOP_MDR: begin
                state_d = S_STOP_MDR_W;
            end
            S_STOP_MDR_W: begin
                mdr_in_d = mem;
                mdr_ld_d = 1'b1;
                state_d = S_STOP_OUT;
            end
            S_STOP_OUT: begin
                out_d = mdr_out;
                if (stop_phase_q < 2'd2) begin
                    stop_phase_d = stop_phase_q + 1'b1;
                    state_d = S_STOP_NEXT;
                end else begin
                    state_d = S_HALT;
                end
            end

            S_NEXT_FETCH: begin
                state_d = S_FETCH_MAR;
            end

            S_HALT: begin
                state_d = S_HALT;
            end

            default: begin
                state_d = S_RESET;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= S_RESET;

            we_q <= 1'b0;
            data_q <= {DATA_WIDTH{1'b0}};
            out_q <= {DATA_WIDTH{1'b0}};

            EA_x_q <= {ADDR_WIDTH{1'b0}}; 
            EA_y_q <= {ADDR_WIDTH{1'b0}}; 
            EA_z_q <= {ADDR_WIDTH{1'b0}};
            Y_val_q <= {DATA_WIDTH{1'b0}}; 
            Z_val_q <= {DATA_WIDTH{1'b0}};
            stop_phase_q <= 2'd0;

            x_ptr_q <= 1'b0;
            y_ptr_q <= 1'b0;
            z_ptr_q <= 1'b0;

            alu_oc_q <= ALU_ADD; 
            alu_a_q <= 8'd0; 
            alu_b_q <= 8'd0;
        end else begin
            state_q <= state_d;

            we_q <= we_d;
            data_q <= data_d;
            out_q <= out_d;

            EA_x_q <= EA_x_d; EA_y_q <= EA_y_d; EA_z_q <= EA_z_d;
            Y_val_q <= Y_val_d; Z_val_q <= Z_val_d;
            stop_phase_q <= stop_phase_d;

            x_ptr_q <= x_ptr_d; y_ptr_q <= y_ptr_d; z_ptr_q <= z_ptr_d;

            alu_oc_q <= alu_oc_d; alu_a_q <= alu_a_d; alu_b_q <= alu_b_d;
        end
    end

endmodule
