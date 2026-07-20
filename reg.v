`include "definitions.vh"

module register_file (
    input  wire                          i_clk,
    input  wire                          i_rst,
    input  wire                          i_we,
    input  wire [`DATA_WIDTH-1:0]        i_write_data,
    input  wire [`REG_ADDR_WIDTH-1:0]    i_rd_addr,
    input  wire [`REG_ADDR_WIDTH-1:0]    i_rs1_addr,
    input  wire [`REG_ADDR_WIDTH-1:0]    i_rs2_addr,
    output wire [`DATA_WIDTH-1:0]        o_rs1_data,
    output wire [`DATA_WIDTH-1:0]        o_rs2_data
);

    reg [`DATA_WIDTH-1:0] registers [0:`NUM_REGISTERS-1];

    integer i;

    // Asynchronous active-high reset and synchronous register writes.
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            for (i = 0; i < `NUM_REGISTERS; i = i + 1) begin
                registers[i] <= {`DATA_WIDTH{1'b0}};
            end
        end
        else if (i_we && (i_rd_addr != {`REG_ADDR_WIDTH{1'b0}})) begin
            registers[i_rd_addr] <= i_write_data;
        end
    end

    // x0 is hardwired to zero. Reads are asynchronous.
    assign o_rs1_data =
        (i_rs1_addr == {`REG_ADDR_WIDTH{1'b0}})
        ? {`DATA_WIDTH{1'b0}}
        : registers[i_rs1_addr];

    assign o_rs2_data =
        (i_rs2_addr == {`REG_ADDR_WIDTH{1'b0}})
        ? {`DATA_WIDTH{1'b0}}
        : registers[i_rs2_addr];

endmodule