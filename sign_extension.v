`include "definitions.vh"

module sign_extension(
    input wire [`INST_WIDTH-1:0] i_inst,
    input wire [`OPCODE_WIDTH-1:0] i_opcode,
    output reg [`INST_WIDTH-1:0] o_imm

);

always @(*) begin
    case (i_opcode)
        `OP_LOAD,`OP_ALUI,`OP_JALR: begin
            if (i_inst[31]==1'b1) begin
             o_imm = {20'hFFFFF, i_inst[31:20]}; 
             end else begin 
            o_imm = {20'h00000, i_inst[31:20]}; 
             end
        end 
        `OP_STORE : begin
            if (i_inst[31]==1'b1) begin
             o_imm = {20'hFFFFF, i_inst[31:25],i_inst[11:7]}; 
             end else begin 
            o_imm = {20'h00000, i_inst[31:25],i_inst[11:7]}; 
             end
            
        end
        `OP_AUIPC,`OP_LUI : begin           
             o_imm = { i_inst[31:12],12'h000};  
            
        end
        `OP_BRANCH: begin
            if (i_inst[31]==1'b1) begin
             o_imm = {19'hFFFFF, i_inst[31],i_inst[7],i_inst[30:25],i_inst[11:8],1'b0}; 
             end else begin 
           o_imm = {19'h0000, i_inst[31],i_inst[7],i_inst[30:25],i_inst[11:8],1'b0}; 
             end
        end
        `OP_JAL: begin 
            if (i_inst[31] == 1'b1) begin
                 o_imm = {{11{i_inst[31]}}, i_inst[31], i_inst[19:12], i_inst[20], i_inst[30:21], 1'b0}; 
                 end else begin
                     o_imm = {{11{i_inst[31]}}, i_inst[31], i_inst[19:12], i_inst[20], i_inst[30:21], 1'b0}; 
                     end 
        end

        

        default:o_imm = {`DATA_WIDTH{1'b0}}; 
    endcase
    
end



endmodule