`include "definitions.vh"


module alu(
    input wire [`ALU_OP_WIDTH-1:0] i_alu_op,
    input wire [`DATA_WIDTH-1:0] i_a,
    input wire [`DATA_WIDTH-1:0] i_b,
    output reg [`DATA_WIDTH-1:0] o_c

);

always @(*) begin
    case(i_alu_op) 

    `ALU_ADD: o_c=i_a+i_b;
    `ALU_SUB:o_c=i_a-i_b;
    `ALU_AND:o_c=i_a&i_b;
    `ALU_OR:o_c=i_a | i_b;
    `ALU_XOR: o_c=i_a ^ i_b;

    `ALU_SLT: begin
        if ($signed(i_a)<$signed(i_b)) begin
            o_c=1;
        
        end else begin
            o_c=0;
        end

    end
    
    `ALU_SLTU: begin
        if ((i_a)<(i_b)) begin
            o_c=1;
        
        end else begin
            o_c=0;
        end

    end
    `ALU_SLL: o_c=i_a<<i_b[`SHAMT_WIDTH-1:0];
    `ALU_SRL: o_c=i_a>>i_b[`SHAMT_WIDTH-1:0];
    `ALU_SRA: o_c=$signed(i_a)>>>i_b[`SHAMT_WIDTH-1:0];

    default: o_c=0;


    endcase
        
    
end

endmodule