`include "definitions.vh"

module rv32i_multicycle_core (
    input  wire i_clk,
    input  wire i_rst,
    output wire o_halt
);

    // Architectural and multicycle datapath registers
    reg [`ADDR_WIDTH-1:0] pc;
    reg [`INST_WIDTH-1:0] IR;
    reg [`ADDR_WIDTH-1:0] instruction_pc;
    reg [`DATA_WIDTH-1:0] a_reg;
    reg [`DATA_WIDTH-1:0] b_reg;
    reg [`DATA_WIDTH-1:0] alu_out;
    reg [`DATA_WIDTH-1:0] mdr;

    // Datapath signals
    wire [`ADDR_WIDTH-1:0] next_pc;
    wire [`INST_WIDTH-1:0] instruction_memory_output;
    wire [`XLEN-1:0] immediate;
    wire [`XLEN-1:0] rs1_data;
    wire [`XLEN-1:0] rs2_data;
    reg  [`DATA_WIDTH-1:0] alu_a;
    reg  [`DATA_WIDTH-1:0] alu_b;
    wire [`DATA_WIDTH-1:0] alu_result;
    wire [`DATA_WIDTH-1:0] memory_data;
    reg  [`DATA_WIDTH-1:0] writeback_data;

    // Instruction-decoder outputs
    wire [`OPCODE_WIDTH-1:0] opcode;
    wire [`REG_ADDR_WIDTH-1:0] rs1_addr;
    wire [`REG_ADDR_WIDTH-1:0] rs2_addr;
    wire [`REG_ADDR_WIDTH-1:0] rd_addr;
    wire [`ALU_OP_WIDTH-1:0] dec_alu_op;
    wire [`FUNCT3_WIDTH-1:0] branch_op;
    wire [`FUNCT3_WIDTH-1:0] mem_funct3;
    wire ecall;
    wire ebreak;
    wire illegal_instruction;

    // Controller outputs
    wire pc_write;
    wire ir_write;
    wire instruction_pc_write;
    wire a_write;
    wire b_write;
    wire aluout_write;
    wire mdr_write;
    wire mem_read;
    wire mem_write;
    wire reg_write;
    wire [`ALU_OP_WIDTH-1:0] alu_op;
    wire [`MC_ALU_SRC_A_WIDTH-1:0] alu_src_a;
    wire [`MC_ALU_SRC_B_WIDTH-1:0] alu_src_b;
    wire [`MC_WB_SEL_WIDTH-1:0] wb_sel;
    wire [`MC_PC_SRC_WIDTH-1:0] pc_source;
    wire controller_halt;
    wire reg_write_enable;

    // Branch and load/store signals
    wire branch;
    wire branch_taken;
    wire [`DATA_WIDTH-1:0] load_data;
    wire [`DATA_WIDTH-1:0] store_data;
    wire [3:0] byte_enable;
    wire misaligned;

    assign branch = (opcode == `OP_BRANCH);
    assign reg_write_enable = reg_write & ~misaligned;
    assign o_halt = ecall |
                    ebreak |
                    illegal_instruction |
                    misaligned |
                    controller_halt;

    // Inter-cycle storage. Nonblocking assignments ensure that FETCH saves
    // the instruction's old PC while the architectural PC advances.
    always @(posedge i_clk) begin
        if (i_rst) begin
            pc             <= {`ADDR_WIDTH{1'b0}};
            IR             <= `NOP_INSTRUCTION;
            instruction_pc <= {`ADDR_WIDTH{1'b0}};
            a_reg          <= {`DATA_WIDTH{1'b0}};
            b_reg          <= {`DATA_WIDTH{1'b0}};
            alu_out        <= {`DATA_WIDTH{1'b0}};
            mdr            <= {`DATA_WIDTH{1'b0}};
        end
        else begin
            if (pc_write)
                pc <= next_pc;

            if (ir_write)
                IR <= instruction_memory_output;

            if (instruction_pc_write)
                instruction_pc <= pc;

            if (a_write)
                a_reg <= rs1_data;

            if (b_write)
                b_reg <= rs2_data;

            if (aluout_write)
                alu_out <= alu_result;

            if (mdr_write)
                mdr <= load_data;
        end
    end

    instruction_memory instruction_memory_inst (
        .i_addr (pc),
        .o_inst (instruction_memory_output)
    );

    instruction_decoder decoder_inst (
        .i_inst                   (IR),
        .o_opcode                 (opcode),
        .o_rs1_addr               (rs1_addr),
        .o_rs2_addr               (rs2_addr),
        .o_rd_addr                (rd_addr),
        .o_dec_alu_op             (dec_alu_op),
        .o_branch_op              (branch_op),
        .o_mem_funct3             (mem_funct3),
        .o_ecall                  (ecall),
        .o_ebreak                 (ebreak),
        .o_illegal_instruction    (illegal_instruction)
    );

    sign_extension sign_extension_inst (
        .i_inst   (IR),
        .i_opcode (opcode),
        .o_imm    (immediate)
    );

    register_file register_file_inst (
        .i_clk        (i_clk),
        .i_rst        (i_rst),
        .i_we         (reg_write_enable),
        .i_write_data (writeback_data),
        .i_rd_addr    (rd_addr),
        .i_rs1_addr   (rs1_addr),
        .i_rs2_addr   (rs2_addr),
        .o_rs1_data   (rs1_data),
        .o_rs2_data   (rs2_data)
    );

    always @(*) begin
        case (alu_src_a)
            `MC_ALU_A_PC:
                alu_a = pc;
            `MC_ALU_A_INSTRUCTION_PC:
                alu_a = instruction_pc;
            `MC_ALU_A_AREG:
                alu_a = a_reg;
            `MC_ALU_A_ZERO:
                alu_a = {`DATA_WIDTH{1'b0}};
            default:
                alu_a = {`DATA_WIDTH{1'b0}};
        endcase
    end

    always @(*) begin
        case (alu_src_b)
            `MC_ALU_B_BREG:
                alu_b = b_reg;
            `MC_ALU_B_IMM:
                alu_b = immediate;
            `MC_ALU_B_FOUR:
                alu_b = `INST_BYTES;
            `MC_ALU_B_ZERO:
                alu_b = {`DATA_WIDTH{1'b0}};
            default:
                alu_b = {`DATA_WIDTH{1'b0}};
        endcase
    end

    alu alu_inst (
        .i_alu_op (alu_op),
        .i_a      (alu_a),
        .i_b      (alu_b),
        .o_c      (alu_result)
    );

    branch_unit branch_inst (
        .i_branch        (branch),
        .i_branch_op     (branch_op),
        .i_a             (a_reg),
        .i_b             (b_reg),
        .o_branch_taken  (branch_taken)
    );

    data_memory data_memory_inst (
        .i_clk          (i_clk),
        .i_we           (mem_write & ~misaligned),
        .i_data         (store_data),
        .i_addr         (alu_out),
        .o_data         (memory_data),
        .i_byte_enable  (byte_enable)
    );

    load_store_unit load_store_unit_inst (
        .i_address       (alu_out),
        .i_funct3        (mem_funct3),
        .i_mem_read      (mem_read),
        .i_mem_write     (mem_write),
        .i_store_data    (b_reg),
        .i_memory_word   (memory_data),
        .o_load_data     (load_data),
        .o_store_data    (store_data),
        .o_byte_enable   (byte_enable),
        .o_misaligned    (misaligned)
    );

    always @(*) begin
        case (wb_sel)
            `MC_WB_ALUOUT:
                writeback_data = alu_out;
            `MC_WB_MDR:
                writeback_data = mdr;
            `MC_WB_PC_PLUS_4:
                writeback_data = pc;
            default:
                writeback_data = {`DATA_WIDTH{1'b0}};
        endcase
    end

    assign next_pc = (pc_source == `MC_PC_ALU_MASKED)
                   ? {alu_result[`ADDR_WIDTH-1:1], 1'b0}
                   : alu_result;

    multicycle_controller controller_inst (
        .i_clk                    (i_clk),
        .i_rst                    (i_rst),
        .i_illegal_instruction    (illegal_instruction),
        .i_ecall                  (ecall),
        .i_ebreak                 (ebreak),
        .i_misaligned             (misaligned),
        .i_branch_taken           (branch_taken),
        .i_opcode                 (opcode),
        .i_dec_alu_op             (dec_alu_op),
        .o_pc_write               (pc_write),
        .o_ir_write               (ir_write),
        .o_instruction_pc_write   (instruction_pc_write),
        .o_mem_write              (mem_write),
        .o_reg_write              (reg_write),
        .o_alu_op                 (alu_op),
        .o_alu_src_a              (alu_src_a),
        .o_alu_src_b              (alu_src_b),
        .o_wb_sel                 (wb_sel),
        .o_pc_source              (pc_source),
        .o_halt                   (controller_halt),
        .o_a_write                (a_write),
        .o_b_write                (b_write),
        .o_aluout_write           (aluout_write),
        .o_mem_read               (mem_read),
        .o_mdr_write              (mdr_write)
    );

endmodule