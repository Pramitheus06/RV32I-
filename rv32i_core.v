`include "definitions.vh"

module rv32i_core (
    input  wire i_clk,
    input  wire i_rst,
    output wire o_halt
);

reg [`ADDR_WIDTH-1:0] pc;
reg [`ADDR_WIDTH-1:0] next_pc;
wire [`INST_WIDTH-1:0] instruc;
wire [`XLEN-1:0] immed;
wire [`XLEN-1:0] rs1data;
wire [`XLEN-1:0] rs2data;
reg  [`DATA_WIDTH-1:0] alu_a;
reg  [`DATA_WIDTH-1:0] alu_b;
wire [`DATA_WIDTH-1:0] alu_result;
wire [`DATA_WIDTH-1:0] mem_data;
reg  [`DATA_WIDTH-1:0] writeback_data;
wire branch_taken;

always @(posedge i_clk) begin
    if (i_rst) begin
        pc <= {`ADDR_WIDTH{1'b0}};
    end
    else if (!o_halt) begin
        pc <= next_pc;
    end
end

wire [`ADDR_WIDTH-1:0] pc_plus_4;

assign pc_plus_4 = pc + 32'd4;

instruction_memory i_mem(.i_addr(pc),.o_inst(instruc));

wire [`OPCODE_WIDTH-1:0]   opcode;
wire [`REG_ADDR_WIDTH-1:0] rs1_addr;
wire [`REG_ADDR_WIDTH-1:0] rs2_addr;
wire [`REG_ADDR_WIDTH-1:0] rd_addr;

wire [`ALU_OP_WIDTH-1:0]    alu_op;
wire [`ALU_SRC_A_WIDTH-1:0] alu_src_a;
wire [`ALU_SRC_B_WIDTH-1:0] alu_src_b;

wire                       reg_write;
wire [`WB_SEL_WIDTH-1:0]   wb_sel;

wire                       branch;
wire [`FUNCT3_WIDTH-1:0]   branch_op;
wire [`PC_SEL_WIDTH-1:0]   pc_sel;

wire                       mem_read;
wire                       mem_write;
wire [`FUNCT3_WIDTH-1:0]   mem_funct3;

wire ecall;
wire ebreak;
wire illegal_instruction;

wire [`DATA_WIDTH-1:0] load_data;
wire [`DATA_WIDTH-1:0] store_data;
wire [3:0]             byte_enable;
wire                   misaligned;

wire reg_write_enable;

assign reg_write_enable = reg_write & ~misaligned;


decoder decoder_inst (
    .i_inst                (instruc),

    .o_opcode              (opcode),
    .o_rs1_addr            (rs1_addr),
    .o_rs2_addr            (rs2_addr),
    .o_rd_addr             (rd_addr),

    .o_alu_op              (alu_op),
    .o_alu_src_a           (alu_src_a),
    .o_alu_src_b           (alu_src_b),

    .o_reg_write           (reg_write),
    .o_wb_sel              (wb_sel),

    .o_branch              (branch),
    .o_branch_op           (branch_op),
    .o_pc_sel              (pc_sel),

    .o_mem_read            (mem_read),
    .o_mem_write           (mem_write),
    .o_mem_funct3          (mem_funct3),

    .o_ecall               (ecall),
    .o_ebreak              (ebreak),
    .o_illegal_instruction (illegal_instruction)
);

sign_extension sign_inst(.i_inst (instruc), .i_opcode(opcode), .o_imm(immed));


register_file reg_inst(.i_clk(i_clk),
.i_rst(i_rst), 
.i_we(reg_write_enable), 
.i_write_data(writeback_data), 
.i_rd_addr(rd_addr), 
.i_rs1_addr(rs1_addr), 
.i_rs2_addr(rs2_addr), 
.o_rs1_data(rs1data), 
.o_rs2_data(rs2data));

always @(*) begin
    case (alu_src_a)
        `ALU_SRC_A_RS1:  alu_a = rs1data;
        `ALU_SRC_A_PC:   alu_a = pc;
        `ALU_SRC_A_ZERO: alu_a = {`DATA_WIDTH{1'b0}};
        default:         alu_a = {`DATA_WIDTH{1'b0}};
    endcase
end

always @(*) begin
    case (alu_src_b)
        `ALU_SRC_B_RS2:  alu_b = rs2data;
        `ALU_SRC_B_IMM:  alu_b = immed;
        `ALU_SRC_B_FOUR: alu_b = 32'd4;
        default:         alu_b = {`DATA_WIDTH{1'b0}};
    endcase
end

alu alu_inst(.i_alu_op(alu_op),
.i_a(alu_a),
.i_b(alu_b),
.o_c(alu_result));

branch_unit branch_inst (
    .i_branch       (branch),
    .i_branch_op    (branch_op),
    .i_a            (rs1data),
    .i_b            (rs2data),
    .o_branch_taken (branch_taken)
);



data_memory data_inst (
    .i_clk         (i_clk),
    .i_we          (mem_write & ~misaligned),
    .i_data        (store_data),
    .i_addr        (alu_result),
    .o_data        (mem_data),
    .i_byte_enable (byte_enable)
);



load_store_unit lsu_inst(
    .i_address(alu_result),
    .i_funct3(mem_funct3),
    .i_mem_read(mem_read),
    .i_mem_write(mem_write),
    .i_store_data(rs2data),
    .i_memory_word(mem_data),
    .o_load_data(load_data),
    .o_store_data(store_data),
    .o_byte_enable(byte_enable),
    .o_misaligned(misaligned)
);

always @(*) begin
    case (wb_sel)
        `WB_ALU: begin
            writeback_data=alu_result;
        end
        `WB_MEMORY: begin
            writeback_data=load_data;
        end
        `WB_PC_PLUS_4: begin
            writeback_data=pc_plus_4;
        end

        default: begin
            writeback_data = {`DATA_WIDTH{1'b0}};
        end
    endcase
end

always @(*) begin
    case (pc_sel)
       `PC_PLUS_4 : begin
        next_pc=pc_plus_4;
       end
       `PC_JAL :begin
        next_pc=alu_result;
       end
      `PC_JALR: begin
            next_pc = {alu_result[`ADDR_WIDTH-1:1], 1'b0};
        end
        `PC_BRANCH: begin
            if (branch_taken)
                next_pc = alu_result;
            else
                next_pc = pc_plus_4;
        end
         default: begin
            next_pc = pc_plus_4;
        end
    endcase
end

assign o_halt = ecall | ebreak | illegal_instruction | misaligned;


endmodule