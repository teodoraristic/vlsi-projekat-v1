module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16,
    parameter ADDR_HIGH = ADDR_WIDTH - 1,
    parameter DATA_HIGH = DATA_WIDTH - 1,
    parameter IR_WIDTH = 32
) (
    input clk,
    input rst_n,
    input [DATA_HIGH:0] mem,
    input [DATA_HIGH:0] in,
    input control,
    output status,
    output we,
    output [ADDR_HIGH:0] addr,
    output [DATA_HIGH:0] data,
    output [DATA_HIGH:0] out,
    output [ADDR_HIGH:0] pc,
    output [ADDR_HIGH:0] sp
);

    // Kontrole
    reg ld_pc, inc_pc;
    reg ld_sp, inc_sp, dec_sp;
    reg ld_mar;
    reg ld_mdr;
    reg ld_acc;
    reg ld_ir;


    reg status_reg, status_next;
    assign status = status_reg;
    
    // Ulazi
    wire [ADDR_HIGH:0] in_pc, in_sp;
    reg [ADDR_HIGH:0] in_mar;
    reg [DATA_HIGH:0] in_mdr, in_acc;
    reg [IR_WIDTH-1:0] in_ir;

    reg [ADDR_HIGH:0] in_pc_next, in_pc_reg, in_sp_reg, in_sp_next;
    assign in_pc = in_pc_reg;
    assign in_sp = in_sp_reg;

    // PC REG
    wire [ADDR_HIGH:0] pc_out;
    register #(.DATA_WIDTH(ADDR_WIDTH)) PC (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(ld_pc), .in(in_pc), .inc(inc_pc),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(pc_out)
    );

    // SP REG
    wire [ADDR_HIGH:0] sp_out;
    register #(.DATA_WIDTH(ADDR_WIDTH)) SP (
        .clk(clk),.rst_n(rst_n),.cl(1'b0),.ld(ld_sp),.in(in_sp),.inc(inc_sp),.dec(dec_sp),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(sp_out)
    );

    // MAR REG
    wire [ADDR_HIGH:0] mar_out;
    register #(.DATA_WIDTH(ADDR_WIDTH)) MAR (
        .clk(clk),.rst_n(rst_n),.cl(1'b0),.ld(ld_mar),.in(in_mar),.inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(mar_out)
    );

    // MDR REG
    wire [DATA_HIGH:0] mdr_out;
    register #(.DATA_WIDTH(DATA_WIDTH)) MDR (
        .clk(clk),.rst_n(rst_n),.cl(1'b0),.ld(ld_mdr),.in(in_mdr),.inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(mdr_out)
    );

    // ACC REG
    wire [DATA_HIGH:0] acc_out;
    register #(.DATA_WIDTH(DATA_WIDTH)) ACC (
        .clk(clk),.rst_n(rst_n),.cl(1'b0),.ld(ld_acc),.in(in_acc),.inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(acc_out)
    );

    // IR REG
    wire [IR_WIDTH-1:0] ir_out;
    register #(.DATA_WIDTH(IR_WIDTH)) IR (
        .clk(clk),.rst_n(rst_n),.cl(1'b0),.ld(ld_ir),.in(in_ir),.inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(ir_out)
    );

    // POMOCNI REGISTRI ZA X,Y,Z
    wire [DATA_HIGH:0] x_out;
    reg ld_x;
    reg [DATA_HIGH:0] in_x;
    register #(.DATA_WIDTH(DATA_WIDTH)) REGX (
        .clk(clk),.rst_n(rst_n),.cl(1'b0),.ld(ld_x),.in(in_x),.inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(x_out)
    );
    wire [DATA_HIGH:0] y_out;
    reg ld_y;
    reg [DATA_HIGH:0] in_y;
    register #(.DATA_WIDTH(DATA_WIDTH)) REGY (
        .clk(clk),.rst_n(rst_n),.cl(1'b0),.ld(ld_y),.in(in_y),.inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(y_out)
    );
    wire [DATA_HIGH:0] z_out;
    reg ld_z;
    reg [DATA_HIGH:0] in_z;
    register #(.DATA_WIDTH(DATA_WIDTH)) REGZ (
        .clk(clk),.rst_n(rst_n),.cl(1'b0),.ld(ld_z),.in(in_z),.inc(1'b0),.dec(1'b0),.sr(1'b0),.ir(1'b0),.sl(1'b0),.il(1'b0),.out(z_out)
    );

    reg [ADDR_HIGH:0] addr_reg, addr_next;
    reg [DATA_HIGH:0] data_reg, data_next;
    reg we_reg, we_next;
    reg [DATA_HIGH:0] out_reg, out_next;

    assign pc = pc_out;
    assign sp = sp_out;
    assign data = data_reg;
    assign addr = addr_reg;
    assign we = we_reg;
    assign out = out_reg;
    assign acc = acc_out;
    
    // OPERACIJE
    
    wire [3:0] opcode = ir_out[31:28];

    wire mode_x = ir_out[27];    // 0 dir , 1 indir
    wire [2:0] addr_x = ir_out[26:24];

    wire mode_y = ir_out[23];
    wire [2:0] addr_y = ir_out[22:20];

    wire mode_z = ir_out[19];
    wire [2:0] addr_z = ir_out[18:16];

    wire [15:0] immed = ir_out[15:0];

    // Adrese su 6 bita?
    wire [5:0] full_addr_x = {3'b000, addr_x};
    wire [5:0] full_addr_y = {3'b000, addr_y};
    wire [5:0] full_addr_z = {3'b000, addr_z};

    reg [DATA_HIGH:0] op_x_data, op_y_data, op_z_data;  // za smeštanje učitanih operanada
    reg [DATA_HIGH:0] op_x_next, op_y_next, op_z_next;
    reg [ADDR_HIGH:0] addr_x_reg, addr_y_reg, addr_z_reg; // registre za adrese operanada
    reg [ADDR_HIGH:0] addr_x_next, addr_y_next, addr_z_next; 

    // ALU JEDINICA
    wire [2:0] alu_op_code = opcode[2:0] - 1'b1;
    wire [DATA_HIGH:0] op1 = y_out; 
    wire [DATA_HIGH:0] op2 = acc_out;
    wire [DATA_HIGH:0] alu_result_reg;
    alu #(.DATA_WIDTH(DATA_WIDTH)) alu_unit (
        .oc(alu_op_code),.a(op1),.b(op2),.f(alu_result_reg)
    );

    reg [5:0] state_reg, state_next;

    localparam [3:0] MOV = 4'b0000;
    localparam [3:0] ADD = 4'b0001;
    localparam [3:0] SUB = 4'b0010;
    localparam [3:0] MUL = 4'b0011;
    localparam [3:0] DIV = 4'b0100;
    localparam [3:0] IN = 4'b0111;
    localparam [3:0] OUT = 4'b1000;
    localparam [3:0] STOP = 4'b1111;

    localparam lastMemoryField = 6'd63;
    localparam pc_start = 6'd8;
    localparam pc_end = 6'd24;
    localparam [5:0] ZERO_STATE = 6'b000000;
    localparam [5:0] INITIATION = 6'b111111;
    reg halted = 1'b0;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= INITIATION; // Podrazumevano
            in_pc_reg <= pc_start;
            in_sp_reg <= lastMemoryField;
            halted <= 0;
           
            data_reg <= {DATA_WIDTH{1'b0}};
            addr_reg <= {ADDR_WIDTH{1'b0}};
            out_reg <= {ADDR_WIDTH{1'b0}};
            we_reg <= 1'b0;
            status_reg <= 1'b0;

        end else begin
           
            data_reg <= data_next;
            addr_reg <= addr_next;
            out_reg <= out_next;
            we_reg <= we_next;
            status_reg <= status_next;
            state_reg <= state_next;
            
            in_pc_reg <= in_pc_next;
            in_sp_reg <= in_sp_next;
        end
    end


    localparam [5:0] FETCH = 6'd1;
    localparam [5:0] DECODE = 6'd2, DECODE_PAUSE = 6'd3, DECODE2 = 6'd4, DECODE3 = 6'd5;
    localparam [5:0] EXEC = 6'd6, EXEC2 = 6'd7, EXEC_PAUSE = 6'd8, EXEC3 = 6'd9, EXEC4 = 6'd10, EXEC5 = 6'd11, EXEC_PAUSE2 = 6'd12;
    localparam [5:0] EXEC_PAUSE3 = 6'd13, EXEC6 = 6'd14, EXEC7 = 6'd15, EXEC8 = 6'd16;
    localparam [5:0] HALT = 6'd17;
    localparam [5:0] ADR_X = 6'd18, ADR_X_PAUSE = 6'd19, ADR_X_EPILOG = 6'd20;
    localparam [5:0] ADR_Y = 6'd21, ADR_Y_PAUSE = 6'd22, ADR_Y_EPILOG = 6'd23;
    localparam [5:0] ADR_Z = 6'd24, ADR_Z_PAUSE = 6'd25, ADR_Z_EPILOG = 6'd26;
    localparam [5:0] EXEC_PAUSE4 = 6'd27, EXEC9 = 6'd28, EXEC10 = 6'd29;
    localparam [5:0] DECODE_HALF = 6'd30;
    // FSM
    always @(*) begin
        state_next = state_reg;
        ld_mar = 0; ld_mdr = 0; ld_ir = 0;
        ld_pc = 0; inc_pc = 0; in_mar = 0;
        in_mdr = 0; in_ir = 0; we_next = 0;
        ld_sp = 0;
        ld_acc = 0; in_acc = 0;
        addr_next = 0;
        data_next = 0;
        out_next = 0;
        ld_acc = 0;
        //status_next = 0;
        in_pc_next = {{ADDR_WIDTH},1'b0};
        in_sp_next = {{ADDR_WIDTH},1'b0};

        ld_x = 0; ld_y = 0; ld_z = 0;
        in_x = {{DATA_WIDTH},1'b0};
        in_y = {{DATA_WIDTH},1'b0};
        in_z = {{DATA_WIDTH},1'b0};

        case (state_reg)
            INITIATION: begin
                ld_pc = 1;
                inc_pc = 0;
                ld_sp = 1;
                
                state_next = FETCH;
            end
            ZERO_STATE: begin
                state_next = FETCH;
                if (pc_out == pc_end) state_next = HALT;
            end
            FETCH: begin
                // Prva faza, potrebno je procitati instrukciju iz pc
                in_mar = pc_out;
                ld_mar = 1;
                inc_pc = 1;
                state_next = DECODE;
            end
            DECODE: begin
                // Postavlja se adresa iz mar_out, treba jedan takt pauze da bi se upisalo u mdr...
                addr_next = mar_out;
                state_next = DECODE_PAUSE;                
            end
            DECODE_PAUSE: begin
                state_next = DECODE2;
            end
            DECODE2: begin
                in_mdr = mem;   // sad je mem validan
                ld_mdr = 1;
                in_ir = {mem,16'h0000};
                ld_ir = 1;
                state_next = DECODE3;     
            end
            DECODE3: begin
                // DEKODIRANJE
                case (opcode)
                    MOV: begin
                        // MOV instrukcija
                        if ({mode_z,addr_z} == 4'h0) begin
                            // Ukoliko je poslednji operand 0, instrukcija se izvrsava
                            // Potrebno je videti koja su adresiranja u pitanju
                            if ({mode_x,mode_y} == 0) begin
                                // Oba su direktno adresiranje, idemo direktno na EXEC fazu
                               
                                in_y = full_addr_y;
                                ld_y = 1;
                                in_x = full_addr_x;
                                ld_x = 1;
                                state_next = EXEC;
                            end else begin
                                // Indirektna adresiranja cemo da proveravamo u posebnim stanjima
                                // Na kraju poslednjeg indirektnog stanja, tacne adrese oba operanda moraju da se nalaze u adekvatnim reg
                                in_y = full_addr_y;
                                ld_y = 1;
                                in_x = full_addr_x;
                                ld_x = 1;
                                state_next = ADR_Y;
                            end
                        end else begin
                            // Ako poslednji operand nije 0, instrukcija se NE izvrsava

                        end
                        
                    end
                    ADD, SUB, MUL, DIV: begin
                        // Ove 4 instrukcije imaju istu osnovu
                        // X = Y OP Z
                        // Opet proveravamo adresiranje
                        if ({mode_x,mode_y,mode_z} == 3'b000) begin
                            // sve je direktno, idemo odmah u EXEC
                            
                            in_y = full_addr_y;
                            ld_y = 1;
                            in_z = full_addr_z;
                            ld_z = 1;
                            in_x = full_addr_x;
                            ld_x = 1;

                            state_next = EXEC;
                        
                        end else begin
                            in_z = full_addr_z;
                            ld_z = 1;
                            in_y = full_addr_y;
                            ld_y = 1;
                            in_x = full_addr_x;
                            ld_x = 1;

                            state_next = ADR_Z;
                        end
                    end
                    IN: begin
                        // IN instrukcija, TEK ZA ISPIT TREBA
                        if (mode_x == 1'b0) begin
                            in_x = full_addr_x;
                            ld_x = 1;
                            state_next = EXEC;
                        end else begin
                            in_x = full_addr_x;
                            ld_x = 1;
                            state_next = ADR_X;
                        end
                        //in_x = full_addr_x;
                        //ld_x = 1;
                        //state_next = ZERO_STATE; // ZBOG PROVERE CPU
                        //state_next = EXEC;
                    end
                    OUT: begin
                        // OUT instrukcija, TEK ZA ISPIT
                        if (mode_x == 1'b0) begin
                            in_x = full_addr_x;
                            ld_x = 1;
                            state_next = EXEC;
                        end else begin
                            in_x = full_addr_x;
                            ld_x = 1;
                            state_next = ADR_X;
                        end
                        //state_next = HALT; // ZBOG PROVERE CPU
                    end
                    STOP: begin
                        // I stop ispisuje na standardni izlaz...
                        if (addr_x == 3'b000 && addr_y == 3'b000 && addr_z == 3'b000) begin
                            state_next = HALT;
                        end else if ({mode_x,mode_y,mode_z} == 3'b000) begin
                            state_next = EXEC;
                        end else begin
                            in_z = full_addr_z;
                            ld_z = 1;
                            in_y = full_addr_y;
                            ld_y = 1;
                            in_x = full_addr_x;
                            ld_x = 1;
                            state_next = ADR_Z;
                        end
                    end
                    default:
                        state_next = ZERO_STATE; 
                endcase
            end
            EXEC:   begin
                // Prvo moramo opet postaviti CASE strukturu
                case (opcode)
                    MOV: begin
                        // Imamo adrese oba operanda u addr_x_reg, addr_y_reg
                        // Na adresu x treba upisati element iz y
                        in_mar = y_out;
                        ld_mar = 1;

                        // U mar upisali adresu x, u sl koraku ga dohvatamo iz memorije
                        state_next = EXEC2;
                    end
                    ADD, SUB, MUL, DIV: begin
                        // Ove 4 instrukcije imaju istu osnovu
                        // X = Y OP Z
                        in_mar = y_out;
                        ld_mar = 1;

                        state_next = EXEC2;
                    end
                    IN: begin
                        // IN instrukcija
                        in_mar = x_out;
                        ld_mar = 1;
                        status_next = 1;
                        state_next = EXEC2;
                    end
                    OUT: begin
                        // OUT instrukcija
                        in_mar = x_out;
                        ld_mar = 1;

                        state_next = EXEC2;
                    end
                    STOP: begin
                        // Ispisuje podatke koji nisu 0 na standardni izlaz
                        if (x_out != 6'd0) begin
                            in_mar = x_out;
                            ld_mar = 1;
                            state_next = EXEC2;
                        end else begin
                            state_next = EXEC4;
                        end
                    end
                    default:
                        state_next = ZERO_STATE; 
                endcase
            end
            EXEC2:   begin
                // Prvo moramo opet postaviti CASE strukturu
                case (opcode)
                    MOV: begin
                        // u MAR se nalazi adresa od y, dohvatamo podatak iz Y,
                        addr_next = mar_out;
                        state_next =  EXEC_PAUSE;
                    end
                    ADD, SUB, MUL, DIV: begin
                        // Ove 4 instrukcije imaju istu osnovu
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE;
                    end
                    IN: begin
                        // IN instrukcija
                        status_next = 1;
                        if (control == 1'b1) begin
                            status_next = 0;
                            in_mdr = in;
                            ld_mdr = 1;
                            state_next = EXEC4;
                        end else begin
                            state_next = EXEC2;
                        end
                        //in_mdr = in;
                        //ld_mdr = 1;
                        //state_next = EXEC4;
                    end
                    OUT: begin
                        // OUT instrukcija
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE;
                    end
                    STOP: begin
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE;
                    end
                    default:
                        state_next = ZERO_STATE; 
                endcase
            end
            EXEC_PAUSE: begin
                state_next = EXEC3;
                
            end
            EXEC3:   begin
                
                in_mdr = mem;
                ld_mdr = 1;
                state_next = EXEC4;
            end
            EXEC4: begin
                // Prvo moramo opet postaviti CASE strukturu
                case (opcode)
                    MOV: begin
                        // u mdr imamo podatak iz Y, a u mar imamo adresu X
                        in_y = mdr_out;
                        ld_y = 1;
                        // na mdr aut je ono sto treba
                        in_mar = x_out;
                        ld_mar = 1;
                        // mar i data postavljeni
                        state_next = EXEC5;
                    end
                    ADD, SUB, MUL, DIV: begin
                        // Ove 4 instrukcije imaju istu osnovu
                        in_acc = mdr_out;
                        ld_acc = 1;
                        // u acc Y
                        in_mar = z_out;
                        ld_mar = 1;

                        state_next = EXEC5;
                    end
                    IN: begin
                        // IN instrukcija
                        addr_next = mar_out;
                        data_next = mdr_out;
                        we_next = 1;
                        state_next = EXEC_PAUSE2;
                    end
                    OUT: begin
                        // OUT instrukcija
                        out_next = mdr_out;
                        state_next = ZERO_STATE;
                    end
                    STOP: begin
                        out_next = mdr_out;
                        if (y_out != 6'd0) begin
                            in_mar = y_out;
                            ld_mar = 1;
                            state_next = EXEC5;
                        end else begin
                            state_next = EXEC7;
                        end   
                    end
                    default:
                        state_next = ZERO_STATE; 
                endcase
            end
            EXEC5:   begin
                case (opcode)
                    MOV: begin
                        addr_next = mar_out;
                        data_next = y_out;                
                        we_next = 1;    // upis
                        state_next = EXEC_PAUSE2;
                    end
                    ADD, SUB, MUL, DIV: begin
                        in_y = acc_out;
                        ld_y = 1;

                        addr_next = mar_out;
                        state_next = EXEC_PAUSE3;

                    end
                    IN: begin
                        // IN instrukcija
                    end
                    OUT: begin
                        // OUT instrukcija
                        
                    end
                    STOP: begin
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE3;
                    end
                    default:
                        state_next = ZERO_STATE; 
                endcase
                
            end
            EXEC_PAUSE2: begin
                state_next = ZERO_STATE;
            end
            EXEC_PAUSE3: begin
                state_next = EXEC6;
            end
            EXEC6: begin
                in_mdr = mem;
                ld_mdr = 1;
                we_next = 0;
                state_next = EXEC7;
                
            end
            EXEC7: begin
                case (opcode)
                    ADD,SUB,MUL,DIV: begin
                        in_acc = mdr_out;
                        ld_acc = 1;

                        in_mar = x_out;
                        ld_mar = 1;
                        
                        state_next = EXEC8;
                    end
                    STOP: begin
                        out_next = mdr_out;
                        if (z_out != 6'd0) begin
                            in_mar = z_out;
                            ld_mar = 1;
                            state_next = EXEC8;
                        end else begin
                            state_next = ZERO_STATE;
                        end
                    end 
                    default: begin
                        state_next = ZERO_STATE;
                    end
                endcase
                
            end
            EXEC8: begin
                case (opcode)
                    ADD,SUB,MUL,DIV: begin
                        addr_next = mar_out;
                        data_next = alu_result_reg;
                        we_next = 1; // upis
                        state_next = EXEC_PAUSE2;
                    end
                    STOP: begin
                        addr_next = mar_out;
                        state_next = EXEC_PAUSE4;
                    end 
                    default: begin
                        
                    end 
                endcase
            end
            EXEC_PAUSE4: begin
                state_next = EXEC9;
            end
            EXEC9: begin
                in_mdr = mem;
                ld_mdr = 1;
                we_next = 0;
                state_next = EXEC10;
            end
            EXEC10: begin
                out_next = mdr_out;
                state_next = ZERO_STATE;
            end
            HALT: begin
                halted = 1'b1;
                state_next = HALT; // ostani u ovom stanju zauvek
                ld_pc = 0;
                ld_sp = 0;
                ld_mar = 0;
                ld_mdr = 0;
                ld_ir = 0;
                ld_acc = 0;
                we_next = 0;
                addr_next = addr_reg;
                data_next = data_reg;
                if (out_reg !== 4'b1111)
                    out_next = 4'b1111;
                else
                    out_next = 4'b1010;
            end
            ADR_Z: begin
                if (mode_z != 1'b0) begin
                    addr_next = z_out;
                    state_next = ADR_Z_PAUSE;
                end else begin
                    state_next = ADR_Y;
                end
            end
            ADR_Z_PAUSE: begin
                state_next = ADR_Z_EPILOG;
            end
            ADR_Z_EPILOG: begin
                in_z = mem;
                ld_z = 1;
                state_next = ADR_Y;
            end
            ADR_Y: begin
                if (mode_y != 1'b0) begin
                    addr_next = y_out;
                    state_next = ADR_Y_PAUSE;
                end else begin
                    state_next = ADR_X;
                end
            end
            ADR_Y_PAUSE: begin
                state_next = ADR_Y_EPILOG;
            end
            ADR_Y_EPILOG: begin
                in_y = mem;
                ld_y = 1;
                state_next = ADR_X;
            end
            ADR_X: begin
                if (mode_x != 1'b0) begin
                    addr_next = x_out;
                    state_next = ADR_X_PAUSE;
                end else begin
                    state_next = EXEC;
                end
            end
            ADR_X_PAUSE: begin
                state_next = ADR_X_EPILOG;
            end
            ADR_X_EPILOG: begin
                in_x = mem;
                ld_x = 1;
                state_next = EXEC;
            end
            default: begin
                
            end
        endcase
    end

endmodule