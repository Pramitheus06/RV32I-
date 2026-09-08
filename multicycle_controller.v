`include "definitions.vh"

module multicycle_controller(
    input wire i_clk,
    input wire i_rst,

    input wire i_illegal_instruction,
    input wire i_ecall,
    input wire i_ebreak,
    input wire i_misaligned,
    input wire i_branch_taken,

    input wire [`OPCODE_WIDTH-1:0] i_opcode,
    input wire [`ALU_OP_WIDTH-1:0] i_dec_alu_op,

    output reg o_pc_write,
    output reg o_ir_write,
    output reg o_instruction_pc_write,

    output reg o_mem_write,
    output reg o_reg_write,

    output reg [`ALU_OP_WIDTH-1:0] o_alu_op,
    output reg [1:0] o_alu_src_a,
    output reg [1:0] o_alu_src_b,

    output reg [1:0] o_wb_sel,
    output reg [1:0] o_pc_source,

    output reg o_halt,
    output reg o_a_write,
    output reg o_b_write,
    output reg o_aluout_write,
    output reg o_mem_read,
    output reg o_mdr_write
);

localparam state_IF   = 5'b00001,
           state_ID   = 5'b00010,
           state_EXE  = 5'b00100,
           state_MEM  = 5'b01000,
           state_WB   = 5'b10000,
           state_HALT = 5'b11111;

reg [4:0] state, next_state;


always @(posedge i_clk) begin
    if (i_rst) begin
        state <= state_IF;
    end
    else begin
        state <= next_state;
    end
end


always @(*) begin

    next_state = state;

    o_pc_write             = 1'b0;
    o_ir_write             = 1'b0;
    o_instruction_pc_write = 1'b0;
    o_a_write              = 1'b0;
    o_b_write              = 1'b0;
    o_aluout_write         = 1'b0;
    o_mdr_write            = 1'b0;
    o_mem_read             = 1'b0;
    o_mem_write            = 1'b0;
    o_reg_write            = 1'b0;
    o_halt                 = 1'b0;

    o_alu_op    = `ALU_ADD;
    o_alu_src_a = `MC_ALU_A_ZERO;
    o_alu_src_b = `MC_ALU_B_ZERO;
    o_pc_source = `MC_PC_ALU;
    o_wb_sel    = `MC_WB_ALUOUT;


    case (state)

        state_IF: begin

            o_ir_write = 1'b1;

            next_state = state_ID;

            o_instruction_pc_write = 1'b1;
            o_pc_write = 1'b1;

            o_alu_src_a = `MC_ALU_A_PC;
            o_alu_src_b = `MC_ALU_B_FOUR;
            o_alu_op    = `ALU_ADD;
            o_pc_source = `MC_PC_ALU;

        end


        state_ID: begin

            if (i_ebreak || i_ecall || i_illegal_instruction) begin
                next_state = state_HALT;
            end
            else begin
                next_state = state_EXE;
            end

            o_a_write = 1'b1;
            o_b_write = 1'b1;

        end


        state_EXE: begin

            case (i_opcode)

                `OP_ALU: begin

                    o_alu_src_a = `MC_ALU_A_AREG;
                    o_alu_src_b = `MC_ALU_B_BREG;
                    o_alu_op = i_dec_alu_op;

                    o_aluout_write = 1'b1;

                    next_state = state_WB;

                end


                `OP_ALUI: begin

                    o_alu_src_a = `MC_ALU_A_AREG;
                    o_alu_src_b = `MC_ALU_B_IMM;
                    o_alu_op = i_dec_alu_op;

                    o_aluout_write = 1'b1;

                    next_state = state_WB;

                end


                `OP_AUIPC: begin

                    o_alu_src_a = `MC_ALU_A_INSTRUCTION_PC;
                    o_alu_src_b = `MC_ALU_B_IMM;
                    o_alu_op = i_dec_alu_op;

                    o_aluout_write = 1'b1;

                    next_state = state_WB;

                end


                `OP_BRANCH: begin

                    o_alu_src_a = `MC_ALU_A_INSTRUCTION_PC;
                    o_alu_src_b = `MC_ALU_B_IMM;
                    o_alu_op = i_dec_alu_op;

                    if (i_branch_taken) begin
                        o_pc_write = 1'b1;
                    end

                    o_pc_source = `MC_PC_ALU;

                    next_state = state_IF;

                end


                `OP_LOAD,
                `OP_STORE: begin

                    o_alu_src_a = `MC_ALU_A_AREG;
                    o_alu_src_b = `MC_ALU_B_IMM;
                    o_alu_op = i_dec_alu_op;

                    o_aluout_write = 1'b1;

                    next_state = state_MEM;

                end


                `OP_LUI: begin

                    o_alu_src_a = `MC_ALU_A_ZERO;
                    o_alu_src_b = `MC_ALU_B_IMM;
                    o_alu_op = i_dec_alu_op;

                    o_aluout_write = 1'b1;

                    next_state = state_WB;

                end


                `OP_JAL: begin

                    o_alu_src_a = `MC_ALU_A_INSTRUCTION_PC;
                    o_alu_src_b = `MC_ALU_B_IMM;
                    o_alu_op = i_dec_alu_op;

                    o_pc_write = 1'b1;
                    o_pc_source = `MC_PC_ALU;

                    o_reg_write = 1'b1;
                    o_wb_sel = `MC_WB_PC_PLUS_4;

                    next_state = state_IF;

                end


                `OP_JALR: begin

                    o_alu_src_a = `MC_ALU_A_AREG;
                    o_alu_src_b = `MC_ALU_B_IMM;
                    o_alu_op = i_dec_alu_op;

                    o_pc_write = 1'b1;
                    o_pc_source = `MC_PC_ALU_MASKED;

                    o_reg_write = 1'b1;
                    o_wb_sel = `MC_WB_PC_PLUS_4;

                    next_state = state_IF;

                end


                `OP_FENCE: begin

                    next_state = state_IF;

                end


                default: begin

                    next_state = state_HALT;

                end

            endcase

        end


        state_MEM: begin

           

            if (i_opcode == `OP_LOAD) begin
                if(~i_misaligned) begin

                o_mem_read = 1'b1;
                o_mdr_write = 1'b1;

                next_state = state_WB;
                end
                else begin
                    o_mem_read = 1'b1;
                o_mdr_write = 1'b0;
                next_state=state_HALT;
                end

            end

            else if (i_opcode == `OP_STORE) begin
                if(~i_misaligned) begin

                o_mem_write = 1'b1;

                next_state = state_IF;
                end else begin
                    next_state=state_HALT;
                    o_mem_write = 1'b1;
                end

            end

            else begin

                next_state = state_HALT;

            end

        end


        state_WB: begin

            case (i_opcode)

                `OP_LOAD: begin

                    o_reg_write = 1'b1;
                    o_wb_sel = `MC_WB_MDR;

                end


                `OP_ALU,
                `OP_ALUI,
                `OP_LUI,
                `OP_AUIPC: begin

                    o_reg_write = 1'b1;
                    o_wb_sel = `MC_WB_ALUOUT;

                end


                default: begin

                    o_reg_write = 1'b0;

                end

            endcase

            next_state = state_IF;

        end


        state_HALT: begin

            o_halt = 1'b1;
            next_state = state_HALT;

        end

    endcase

end

endmodule