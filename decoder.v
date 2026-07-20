`include "definitions.vh"


module decoder (
    input  wire [`INST_WIDTH-1:0] i_inst,

    // Extracted instruction fields
    output wire [`OPCODE_WIDTH-1:0]   o_opcode,
    output wire [`REG_ADDR_WIDTH-1:0] o_rs1_addr,
    output wire [`REG_ADDR_WIDTH-1:0] o_rs2_addr,
    output wire [`REG_ADDR_WIDTH-1:0] o_rd_addr,

    // ALU controls
    output reg [`ALU_OP_WIDTH-1:0]    o_alu_op,
    output reg [`ALU_SRC_A_WIDTH-1:0] o_alu_src_a,
    output reg [`ALU_SRC_B_WIDTH-1:0] o_alu_src_b,

    // Register writeback controls
    output reg                         o_reg_write,
    output reg [`WB_SEL_WIDTH-1:0]     o_wb_sel,

    // Branch and next-PC controls
    output reg                         o_branch,
    output reg [`FUNCT3_WIDTH-1:0]     o_branch_op,
    output reg [`PC_SEL_WIDTH-1:0]     o_pc_sel,

    // Memory controls
    output reg                         o_mem_read,
    output reg                         o_mem_write,
    output reg [`FUNCT3_WIDTH-1:0]     o_mem_funct3,

    // Basic exception/system indicators
    output reg                         o_ecall,
    output reg                         o_ebreak,
    output reg                         o_illegal_instruction
);

wire [`OPCODE_WIDTH-1:0]opcode=i_inst[`OPCODE_RANGE];
wire [`FUNCT3_WIDTH-1:0] funct3 = i_inst[`FUNCT3_RANGE];
wire [`FUNCT7_WIDTH-1:0] funct7 = i_inst[`FUNCT7_RANGE];

always @(*) begin
    o_alu_op              = `ALU_ADD;
    o_alu_src_a           = `ALU_SRC_A_RS1;
    o_alu_src_b           = `ALU_SRC_B_RS2;

    o_reg_write           = 1'b0;
    o_wb_sel              = `WB_ALU;

    o_branch              = 1'b0;
    o_branch_op           = `F3_BEQ;
    o_pc_sel              = `PC_PLUS_4;

    o_mem_read            = 1'b0;
    o_mem_write           = 1'b0;
    o_mem_funct3          = `F3_LW;

    o_ecall               = 1'b0;
    o_ebreak              = 1'b0;
    o_illegal_instruction = 1'b0;

    case (opcode)
        `OP_LUI: begin
           o_alu_src_a = `ALU_SRC_A_ZERO;
        o_alu_src_b = `ALU_SRC_B_IMM;
        o_alu_op    = `ALU_ADD;
        o_reg_write = 1'b1;
        o_wb_sel    = `WB_ALU;
            
        end 
        `OP_AUIPC: begin
            o_alu_src_a=`ALU_SRC_A_PC;
            o_alu_src_b=`ALU_SRC_B_IMM;
             o_reg_write=1;
        end
        `OP_JAL: begin
             o_alu_src_a = `ALU_SRC_A_PC;
            o_alu_src_b = `ALU_SRC_B_IMM;
            o_alu_op    = `ALU_ADD;
             o_pc_sel=`PC_JAL;
             o_reg_write=1;
             o_wb_sel=`WB_PC_PLUS_4;
             o_branch    = 1'b0;
           end

           `OP_JALR: begin
            if (funct3 == `F3_JALR) begin
             o_alu_src_a = `ALU_SRC_A_RS1;
            o_alu_src_b = `ALU_SRC_B_IMM;
            o_alu_op    = `ALU_ADD;
             o_pc_sel=`PC_JALR;
             o_reg_write=1;
             o_wb_sel=`WB_PC_PLUS_4;
             o_branch    = 1'b0;
              end
    else begin
        o_illegal_instruction = 1'b1;
    end
           end
           `OP_BRANCH: begin
    case (funct3)

        `F3_BEQ,
        `F3_BNE,
        `F3_BLT,
        `F3_BGE,
        `F3_BLTU,
        `F3_BGEU: begin
            o_branch    = 1'b1;
            o_branch_op = funct3;
            o_pc_sel    = `PC_BRANCH;

           
            o_alu_src_a = `ALU_SRC_A_PC;
            o_alu_src_b = `ALU_SRC_B_IMM;
            o_alu_op    = `ALU_ADD;
        end

        default: begin
            o_branch              = 1'b0;
            o_illegal_instruction = 1'b1;
        end

    endcase
end

        `OP_LOAD: begin
             case (funct3) 
             `F3_LB,`F3_LBU,`F3_LH,`F3_LHU,`F3_LW: begin
                o_reg_write=1;
                o_alu_src_a = `ALU_SRC_A_RS1;
                o_alu_src_b = `ALU_SRC_B_IMM;
                o_wb_sel=`WB_MEMORY;
                o_mem_read=1;
                o_mem_funct3=funct3;
                o_alu_op=`ALU_ADD;

                
             end
             default: o_illegal_instruction=1;
             endcase
             
            
        end
        `OP_STORE: begin
            case (funct3) 
               `F3_SB,`F3_SH,`F3_SW: begin
                o_alu_src_a = `ALU_SRC_A_RS1;
                o_reg_write=0;
                o_alu_src_b = `ALU_SRC_B_IMM;
                o_mem_write=1;
                o_mem_funct3=funct3;
                
                o_alu_op=`ALU_ADD;

               end
            
                
                 default: o_illegal_instruction=1; 
            endcase
        end

       `OP_ALU: begin
    o_alu_src_a = `ALU_SRC_A_RS1;
    o_alu_src_b = `ALU_SRC_B_RS2;
    o_reg_write = 1'b1;
    o_wb_sel    = `WB_ALU;

    case (funct3)

        `F3_ADD: begin
            case (funct7)
                `FUNCT7_BASE:
                    o_alu_op = `ALU_ADD;

                `FUNCT7_ALT:
                    o_alu_op = `ALU_SUB;

                default:
                    begin
    o_illegal_instruction = 1'b1;
    o_reg_write           = 1'b0;
end
            endcase
        end

        `F3_SRL: begin
            case (funct7)
                `FUNCT7_BASE:
                    o_alu_op = `ALU_SRL;

                `FUNCT7_ALT:
                    o_alu_op = `ALU_SRA;

                default:
                    begin
    o_illegal_instruction = 1'b1;
    o_reg_write           = 1'b0;
end
            endcase
        end

        `F3_AND: begin
            if (funct7 == `FUNCT7_BASE)
                o_alu_op = `ALU_AND;
            else
                begin
    o_illegal_instruction = 1'b1;
    o_reg_write           = 1'b0;
end
        end

        `F3_OR: begin
            if (funct7 == `FUNCT7_BASE)
                o_alu_op = `ALU_OR;
            else
                begin
    o_illegal_instruction = 1'b1;
    o_reg_write           = 1'b0;
end
        end

        `F3_XOR: begin
            if (funct7 == `FUNCT7_BASE)
                o_alu_op = `ALU_XOR;
            else
                begin
    o_illegal_instruction = 1'b1;
    o_reg_write           = 1'b0;
end
        end

        `F3_SLT: begin
            if (funct7 == `FUNCT7_BASE)
                o_alu_op = `ALU_SLT;
            else begin
    o_illegal_instruction = 1'b1;
    o_reg_write           = 1'b0;
end
        end

        `F3_SLTU: begin
            if (funct7 == `FUNCT7_BASE)
                o_alu_op = `ALU_SLTU;
            else
               begin
    o_illegal_instruction = 1'b1;
    o_reg_write           = 1'b0;
end
        end

        `F3_SLL: begin
            if (funct7 == `FUNCT7_BASE)
                o_alu_op = `ALU_SLL;
            else
                begin
    o_illegal_instruction = 1'b1;
    o_reg_write           = 1'b0;
end
        end

        default: 
           begin
    o_illegal_instruction = 1'b1;
    o_reg_write           = 1'b0;
end
        

    endcase
end

        `OP_ALUI: begin
    o_alu_src_a = `ALU_SRC_A_RS1;
    o_alu_src_b = `ALU_SRC_B_IMM;
    o_reg_write = 1'b1;
    o_wb_sel    = `WB_ALU;

    case (funct3)

        `F3_ADDI: o_alu_op=`ALU_ADD;
        `F3_SLTI: o_alu_op=`ALU_SLT;
        `F3_SLTIU:o_alu_op = `ALU_SLTU;
        `F3_XORI:o_alu_op = `ALU_XOR;
        `F3_ORI:  o_alu_op = `ALU_OR;
        `F3_ANDI: o_alu_op = `ALU_AND;
        `F3_SRLI: begin
            case (funct7)
                 `FUNCT7_BASE:
                    o_alu_op = `ALU_SRL;

                `FUNCT7_ALT:
                    o_alu_op = `ALU_SRA; 

            default: begin
                o_illegal_instruction = 1'b1;
                o_reg_write           = 1'b0;
        end
            endcase
        end

            `F3_SLLI: begin
            if (funct7 == `FUNCT7_BASE)
                o_alu_op = `ALU_SLL;
            else begin
                o_illegal_instruction = 1'b1;
                o_reg_write           = 1'b0;
            end 
            end
default: begin
    o_illegal_instruction = 1'b1;
    o_reg_write           = 1'b0;
end
    endcase
end

`OP_FENCE: begin
    if (funct3 != `F3_FENCE)
        o_illegal_instruction = 1'b1;
end

`OP_SYSTEM: begin
    if (i_inst == `INST_ECALL) begin
        o_ecall = 1'b1;
    end
    else if (i_inst == `INST_EBREAK) begin
        o_ebreak = 1'b1;
    end
    else begin
        o_illegal_instruction = 1'b1;
    end
end


        default: begin
    o_illegal_instruction = 1'b1;
end 
    endcase
    
end

assign o_opcode   = opcode;
assign o_rs1_addr = i_inst[`RS1_RANGE];
assign o_rs2_addr = i_inst[`RS2_RANGE];
assign o_rd_addr  = i_inst[`RD_RANGE];


endmodule