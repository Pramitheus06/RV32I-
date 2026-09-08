`include "definitions.vh"


module instruction_decoder (
    input wire [`INST_WIDTH-1:0] i_inst,

    output wire [`OPCODE_WIDTH-1:0]   o_opcode,
    output wire [`REG_ADDR_WIDTH-1:0] o_rs1_addr,
    output wire [`REG_ADDR_WIDTH-1:0] o_rs2_addr,
    output wire [`REG_ADDR_WIDTH-1:0] o_rd_addr,

    output reg [`ALU_OP_WIDTH-1:0]  o_dec_alu_op,
    output reg [`FUNCT3_WIDTH-1:0]  o_branch_op,
    output reg [`FUNCT3_WIDTH-1:0]  o_mem_funct3,

    output reg o_ecall,
    output reg o_ebreak,
    output reg o_illegal_instruction
);

wire [`OPCODE_WIDTH-1:0]opcode=i_inst[`OPCODE_RANGE];
wire [`FUNCT3_WIDTH-1:0] funct3 = i_inst[`FUNCT3_RANGE];
wire [`FUNCT7_WIDTH-1:0] funct7 = i_inst[`FUNCT7_RANGE];

assign o_opcode   = opcode;
assign o_rs1_addr = i_inst[`RS1_RANGE];
assign o_rs2_addr = i_inst[`RS2_RANGE];
assign o_rd_addr  = i_inst[`RD_RANGE];



always @(*) begin
  o_dec_alu_op             = `ALU_ADD;

    o_branch_op           = `F3_BEQ;

    o_mem_funct3          = `F3_LW;

    o_ecall               = 1'b0;
    o_ebreak              = 1'b0;
    o_illegal_instruction = 1'b0;

    case (opcode)
        `OP_LUI: begin
         
      o_dec_alu_op    = `ALU_ADD;
       
            
        end 
        `OP_AUIPC: begin
           o_dec_alu_op   = `ALU_ADD;
            
        end
        `OP_JAL: begin
          o_dec_alu_op    = `ALU_ADD;
           end

           `OP_JALR: begin
            if (funct3 == `F3_JALR) begin
             
           o_dec_alu_op    = `ALU_ADD;
             
              end
    else begin
        o_illegal_instruction = 1'b1;
    end
           end
           `OP_BRANCH: begin
            o_dec_alu_op = `ALU_ADD;
    case (funct3)

        `F3_BEQ,
        `F3_BNE,
        `F3_BLT,
        `F3_BGE,
        `F3_BLTU,
        `F3_BGEU: begin
            
            o_branch_op = funct3;
           
        end

        default: begin
           
            o_illegal_instruction = 1'b1;
        end

    endcase
end

       `OP_LOAD: begin
    o_dec_alu_op = `ALU_ADD;

    case (funct3)
        `F3_LB,
        `F3_LBU,
        `F3_LH,
        `F3_LHU,
        `F3_LW: begin
            o_mem_funct3 = funct3;
        end

        default: begin
            o_illegal_instruction = 1'b1;
        end
    endcase
end
        `OP_STORE: begin
                o_dec_alu_op = `ALU_ADD;

                case (funct3)
                    `F3_SB,
                    `F3_SH,
                    `F3_SW: begin
                        o_mem_funct3 = funct3;
                    end

                    default: begin
                        o_illegal_instruction = 1'b1;
                    end
                endcase
            end

       `OP_ALU: begin
   
   

    case (funct3)

        `F3_ADD: begin
            case (funct7)
                `FUNCT7_BASE:
                   o_dec_alu_op = `ALU_ADD;

                `FUNCT7_ALT:
                    o_dec_alu_op = `ALU_SUB;

                default:
                    begin
    o_illegal_instruction = 1'b1;
 
end
            endcase
        end

        `F3_SRL: begin
            case (funct7)
                `FUNCT7_BASE:
                    o_dec_alu_op = `ALU_SRL;

                `FUNCT7_ALT:
                    o_dec_alu_op = `ALU_SRA;

                default:
                    begin
    o_illegal_instruction = 1'b1;
   
end
            endcase
        end

        `F3_AND: begin
            if (funct7 == `FUNCT7_BASE)
               o_dec_alu_op = `ALU_AND;
            else
                begin
    o_illegal_instruction = 1'b1;
    
end
        end

        `F3_OR: begin
            if (funct7 == `FUNCT7_BASE)
               o_dec_alu_op = `ALU_OR;
            else
                begin
    o_illegal_instruction = 1'b1;
    
end
        end

        `F3_XOR: begin
            if (funct7 == `FUNCT7_BASE)
                o_dec_alu_op = `ALU_XOR;
            else
                begin
    o_illegal_instruction = 1'b1;
    
end
        end

        `F3_SLT: begin
            if (funct7 == `FUNCT7_BASE)
                o_dec_alu_op = `ALU_SLT;
            else begin
    o_illegal_instruction = 1'b1;

end
        end

        `F3_SLTU: begin
            if (funct7 == `FUNCT7_BASE)
                o_dec_alu_op = `ALU_SLTU;
            else
               begin
    o_illegal_instruction = 1'b1;
 
end
        end

        `F3_SLL: begin
            if (funct7 == `FUNCT7_BASE)
                o_dec_alu_op = `ALU_SLL;
            else
                begin
    o_illegal_instruction = 1'b1;

end
        end

        default: 
           begin
    o_illegal_instruction = 1'b1;
 
end
        

    endcase
end

        `OP_ALUI: begin

    case (funct3)

        `F3_ADDI: o_dec_alu_op=`ALU_ADD;
        `F3_SLTI: o_dec_alu_op=`ALU_SLT;
        `F3_SLTIU:o_dec_alu_op = `ALU_SLTU;
        `F3_XORI:o_dec_alu_op = `ALU_XOR;
        `F3_ORI:  o_dec_alu_op = `ALU_OR;
        `F3_ANDI: o_dec_alu_op = `ALU_AND;
        `F3_SRLI: begin
            case (funct7)
                 `FUNCT7_BASE:
                    o_dec_alu_op = `ALU_SRL;

                `FUNCT7_ALT:
                    o_dec_alu_op = `ALU_SRA; 

            default: begin
                o_illegal_instruction = 1'b1;
                
        end
            endcase
        end

            `F3_SLLI: begin
            if (funct7 == `FUNCT7_BASE)
                o_dec_alu_op = `ALU_SLL;
            else begin
                o_illegal_instruction = 1'b1;
                
            end 
            end
default: begin
    o_illegal_instruction = 1'b1;
    
end
    endcase
end

`OP_FENCE: begin
    if ((funct3 != `F3_FENCE) ||
        (o_rs1_addr != {`REG_ADDR_WIDTH{1'b0}}) ||
        (o_rd_addr  != {`REG_ADDR_WIDTH{1'b0}})) begin

        o_illegal_instruction = 1'b1;
    end
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



endmodule