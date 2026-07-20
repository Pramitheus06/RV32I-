`include "definitions.vh"

module branch_unit(
    input wire i_branch,
    input wire [2:0] i_branch_op,
    input wire [`DATA_WIDTH-1:0] i_a,
    input wire [`DATA_WIDTH-1:0] i_b,
    output reg o_branch_taken

);

always @(*) begin
    o_branch_taken=1'b0;
     if (i_branch) begin
    case (i_branch_op)
        `F3_BEQ: begin
            if(i_a==i_b) begin
                o_branch_taken=1'b1;
            end
            else o_branch_taken=1'b0;
        end
        `F3_BGE:  begin
            if($signed(i_a)>=$signed(i_b)) begin
                o_branch_taken=1'b1;
            end
            else o_branch_taken=1'b0;
        end
        `F3_BGEU:  begin
            if(i_a>=i_b) begin
                o_branch_taken=1'b1;
            end
            else o_branch_taken=1'b0;
        end
        `F3_BLT:  begin
            if($signed(i_a)<$signed(i_b)) begin
                o_branch_taken=1'b1;
            end
            else o_branch_taken=1'b0;
        end

        `F3_BLTU: begin
            if(i_a<i_b) begin
                o_branch_taken=1'b1;
            end
            else o_branch_taken=1'b0;
        end
        `F3_BNE:  begin
            if(i_a!=i_b) begin
                o_branch_taken=1'b1;
            end
            else o_branch_taken=1'b0;
        end
        default: o_branch_taken=1'b0;
    endcase
    end
end


endmodule