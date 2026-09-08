`ifndef DEFINITIONS_VH
`define DEFINITIONS_VH


// ============================================================
// RV32I ARCHITECTURAL DEFINITIONS
// ============================================================

`define XLEN               32
`define DATA_WIDTH         32
`define ADDR_WIDTH         32
`define INST_WIDTH         32

`define NUM_REGISTERS      32
`define REG_ADDR_WIDTH     5

`define OPCODE_WIDTH       7
`define FUNCT3_WIDTH       3
`define FUNCT7_WIDTH       7
`define SHAMT_WIDTH        5

// Each RV32I instruction occupies 4 bytes
`define INST_BYTES         32'd4

// addi x0, x0, 0
`define NOP_INSTRUCTION    32'h0000_0013


// ============================================================
// INSTRUCTION FIELD LOCATIONS
// ============================================================

`define OPCODE_RANGE       6:0
`define RD_RANGE           11:7
`define FUNCT3_RANGE       14:12
`define RS1_RANGE          19:15
`define RS2_RANGE          24:20
`define FUNCT7_RANGE       31:25

`define SHAMT_RANGE        24:20

// SYSTEM immediate field
`define SYSTEM_IMM_RANGE   31:20


// ============================================================
// RV32I MAJOR OPCODES
// ============================================================

`define OP_LOAD            7'b0000011
`define OP_FENCE           7'b0001111
`define OP_ALUI            7'b0010011
`define OP_AUIPC           7'b0010111
`define OP_STORE           7'b0100011
`define OP_ALU             7'b0110011
`define OP_LUI             7'b0110111
`define OP_BRANCH          7'b1100011
`define OP_JALR            7'b1100111
`define OP_JAL             7'b1101111
`define OP_SYSTEM          7'b1110011


// ============================================================
// COMMON FUNCT7 VALUES
// ============================================================

// ADD, SLL, SLT, SLTU, XOR, SRL, OR, AND
`define FUNCT7_BASE        7'b0000000

// SUB and SRA
`define FUNCT7_ALT         7'b0100000


// ============================================================
// REGISTER-REGISTER ALU INSTRUCTIONS
//
// opcode = OP_ALU
// ============================================================

`define F3_ADD             3'b000
`define F3_SUB             3'b000

`define F3_SLL             3'b001
`define F3_SLT             3'b010
`define F3_SLTU            3'b011
`define F3_XOR             3'b100

`define F3_SRL             3'b101
`define F3_SRA             3'b101

`define F3_OR              3'b110
`define F3_AND             3'b111


// ============================================================
// IMMEDIATE ALU INSTRUCTIONS
//
// opcode = OP_ALUI
// ============================================================

`define F3_ADDI            3'b000
`define F3_SLLI            3'b001
`define F3_SLTI            3'b010
`define F3_SLTIU           3'b011
`define F3_XORI            3'b100

`define F3_SRLI            3'b101
`define F3_SRAI            3'b101

`define F3_ORI             3'b110
`define F3_ANDI            3'b111


// ============================================================
// BRANCH INSTRUCTIONS
//
// opcode = OP_BRANCH
// ============================================================

`define F3_BEQ             3'b000
`define F3_BNE             3'b001
`define F3_BLT             3'b100
`define F3_BGE             3'b101
`define F3_BLTU            3'b110
`define F3_BGEU            3'b111


// ============================================================
// LOAD INSTRUCTIONS
//
// opcode = OP_LOAD
// ============================================================

`define F3_LB              3'b000
`define F3_LH              3'b001
`define F3_LW              3'b010
`define F3_LBU             3'b100
`define F3_LHU             3'b101


// ============================================================
// STORE INSTRUCTIONS
//
// opcode = OP_STORE
// ============================================================

`define F3_SB              3'b000
`define F3_SH              3'b001
`define F3_SW              3'b010


// ============================================================
// JALR
//
// opcode = OP_JALR
// ============================================================

`define F3_JALR            3'b000


// ============================================================
// FENCE INSTRUCTIONS
//
// You may decode these and treat them as NOPs for now.
// ============================================================

`define F3_FENCE           3'b000
`define F3_FENCE_I         3'b001


// ============================================================
// SYSTEM INSTRUCTIONS
//
// The uploaded older table calls these SCALL and SBREAK.
// Modern names are ECALL and EBREAK.
// ============================================================

`define F3_SYSTEM          3'b000

`define IMM_ECALL          12'h000
`define IMM_EBREAK         12'h001

`define INST_ECALL         32'h0000_0073
`define INST_EBREAK        32'h0010_0073


// ============================================================
// INTERNAL ALU OPERATION CODES
//
// These are not RISC-V encodings.
// They are control values chosen for our processor.
// ============================================================

`define ALU_OP_WIDTH       4

`define ALU_NOP            4'd0
`define ALU_ADD            4'd1
`define ALU_SUB            4'd2
`define ALU_AND            4'd3
`define ALU_OR             4'd4
`define ALU_XOR            4'd5
`define ALU_SLT            4'd6
`define ALU_SLTU           4'd7
`define ALU_SLL            4'd8
`define ALU_SRL            4'd9
`define ALU_SRA            4'd10


// ============================================================
// IMMEDIATE FORMAT SELECTION
//
// Used by the immediate generator.
// ============================================================

`define IMM_SEL_WIDTH      3

`define IMM_I_TYPE         3'd0
`define IMM_S_TYPE         3'd1
`define IMM_B_TYPE         3'd2
`define IMM_U_TYPE         3'd3
`define IMM_J_TYPE         3'd4


// ============================================================
// ALU INPUT A MULTIPLEXER
// ============================================================

`define ALU_SRC_A_WIDTH    2

`define ALU_SRC_A_RS1      2'd0
`define ALU_SRC_A_PC       2'd1
`define ALU_SRC_A_ZERO     2'd2


// ============================================================
// ALU INPUT B MULTIPLEXER
// ============================================================

`define ALU_SRC_B_WIDTH    2

`define ALU_SRC_B_RS2      2'd0
`define ALU_SRC_B_IMM      2'd1
`define ALU_SRC_B_FOUR     2'd2


// ============================================================
// REGISTER WRITEBACK MULTIPLEXER
// ============================================================

`define WB_SEL_WIDTH       2

`define WB_ALU             2'd0
`define WB_MEMORY          2'd1
`define WB_PC_PLUS_4       2'd2


// ============================================================
// NEXT-PC MULTIPLEXER
// ============================================================

`define PC_SEL_WIDTH       2

`define PC_PLUS_4          2'd0
`define PC_BRANCH          2'd1
`define PC_JAL             2'd2
`define PC_JALR            2'd3


// ============================================================
// MEMORY ACCESS SIZE
// ============================================================

`define MEM_ACCESS_WIDTH   2

`define MEM_BYTE           2'd0
`define MEM_HALFWORD       2'd1
`define MEM_WORD           2'd2

// ============================================================
// MULTICYCLE ALU INPUT A MULTIPLEXER
// ============================================================

`define MC_ALU_SRC_A_WIDTH       2

`define MC_ALU_A_PC              2'd0
`define MC_ALU_A_INSTRUCTION_PC  2'd1
`define MC_ALU_A_AREG            2'd2
`define MC_ALU_A_ZERO            2'd3


// ============================================================
// MULTICYCLE ALU INPUT B MULTIPLEXER
// ============================================================

`define MC_ALU_SRC_B_WIDTH       2

`define MC_ALU_B_BREG            2'd0
`define MC_ALU_B_IMM             2'd1
`define MC_ALU_B_FOUR            2'd2
`define MC_ALU_B_ZERO            2'd3


// ============================================================
// MULTICYCLE WRITEBACK MULTIPLEXER
// ============================================================

`define MC_WB_SEL_WIDTH          2

`define MC_WB_ALUOUT             2'd0
`define MC_WB_MDR                2'd1
`define MC_WB_PC_PLUS_4          2'd2


// ============================================================
// MULTICYCLE PC SOURCE MULTIPLEXER
// ============================================================

`define MC_PC_SRC_WIDTH          2

`define MC_PC_ALU                2'd0
`define MC_PC_ALU_MASKED         2'd1

`endif