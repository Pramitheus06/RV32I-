`include "definitions.vh"

module instruction_memory #(
    parameter MEM_WORDS = 1024
) (
    input  wire [`ADDR_WIDTH-1:0] i_addr,
    output wire [`INST_WIDTH-1:0] o_inst
);

    localparam WORD_ADDR_WIDTH = $clog2(MEM_WORDS);

    reg [`INST_WIDTH-1:0] memory [0:MEM_WORDS-1];
    wire [WORD_ADDR_WIDTH-1:0] word_addr;

    integer i;

    // Instructions are addressed by byte address, but stored as words.
    assign word_addr = i_addr[WORD_ADDR_WIDTH+1:2];

    initial begin
        // Fill unused locations with canonical RV32I NOPs.
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            memory[i] = `NOP_INSTRUCTION;
        end

        $readmemh("instruction.hex", memory);
    end

    // Combinational instruction fetch.
    assign o_inst = memory[word_addr];

endmodule