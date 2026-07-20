`include "definitions.vh"

module data_memory #(
    parameter MEM_WORDS = 1024
) (
    input  wire                         i_clk,
    input  wire                         i_we,
    input  wire [`DATA_WIDTH-1:0]       i_data,
    input  wire [`ADDR_WIDTH-1:0]       i_addr,
    output wire [`DATA_WIDTH-1:0]       o_data,
    input wire [3:0] i_byte_enable
);

    localparam WORD_ADDR_WIDTH = $clog2(MEM_WORDS);

    reg [`DATA_WIDTH-1:0] memory [0:MEM_WORDS-1];
    wire [WORD_ADDR_WIDTH-1:0] word_addr;

    integer i;

    // The CPU supplies a byte address. Drop bits [1:0] to obtain
    // a word address, then retain only enough bits for this RAM.
    assign word_addr = i_addr[WORD_ADDR_WIDTH+1:2];

    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            memory[i] = {`DATA_WIDTH{1'b0}};
        end

        $readmemh("data.hex", memory);
    end

    // Synchronous word write.
   always @(posedge i_clk) begin

     if (i_we) begin
    if (i_byte_enable[0])
        memory[word_addr][7:0] <= i_data[7:0];

    if (i_byte_enable[1])
        memory[word_addr][15:8] <= i_data[15:8];

    if (i_byte_enable[2])
        memory[word_addr][23:16] <= i_data[23:16];

    if (i_byte_enable[3])
        memory[word_addr][31:24] <= i_data[31:24];
end
   end
    // Asynchronous word read.
    assign o_data = memory[word_addr];

endmodule