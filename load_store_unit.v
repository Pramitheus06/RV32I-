`include "definitions.vh"

module load_store_unit (
    input  wire [`DATA_WIDTH-1:0] i_address,
    input  wire [`FUNCT3_WIDTH-1:0] i_funct3,
    input  wire                     i_mem_read,
    input  wire                     i_mem_write,
    input  wire [`DATA_WIDTH-1:0] i_store_data,
    input  wire [`DATA_WIDTH-1:0] i_memory_word,

    output reg  [`DATA_WIDTH-1:0] o_load_data,
    output reg  [`DATA_WIDTH-1:0] o_store_data,
    output reg  [3:0]             o_byte_enable,
    output reg                    o_misaligned
);

always @(*) begin

     o_load_data   = {`DATA_WIDTH{1'b0}};
    o_store_data  = {`DATA_WIDTH{1'b0}};
    o_byte_enable = 4'b0000;
    o_misaligned  = 1'b0;
    if(i_mem_read ) begin

    case (i_funct3)
       `F3_LB : begin
        case (i_address[1:0])
            2'b00: o_load_data={{24{i_memory_word[7]}},i_memory_word[7:0]};
            2'b01: o_load_data={{24{i_memory_word[15]}},i_memory_word[15:8]};
            2'b10: o_load_data={{24{i_memory_word[23]}},i_memory_word[23:16]};
            2'b11: o_load_data={{24{i_memory_word[31]}},i_memory_word[31:24]};
            default:  o_load_data={{24{i_memory_word[7]}},i_memory_word[7:0]};
        endcase      
       end

        `F3_LBU : begin
        case (i_address[1:0])
            2'b00: o_load_data={{24{1'b0}},i_memory_word[7:0]};
            2'b01: o_load_data={{24{1'b0}},i_memory_word[15:8]};
            2'b10: o_load_data={{24{1'b0}},i_memory_word[23:16]};
            2'b11: o_load_data={{24{1'b0}},i_memory_word[31:24]};
            default:  o_load_data={{24{1'b0}},i_memory_word[7:0]};
        endcase      
       end

       
         `F3_LH: begin
            if (i_address[0] != 1'b0) begin
                o_misaligned = 1'b1;
            end
            else if (i_address[1] == 1'b0) begin
                o_load_data =
                    {{16{i_memory_word[15]}}, i_memory_word[15:0]};
            end
            else begin
                o_load_data =
                    {{16{i_memory_word[31]}}, i_memory_word[31:16]};
            end
        end

         `F3_LHU: begin
            if (i_address[0] != 1'b0) begin
                o_misaligned = 1'b1;
            end
            else if (i_address[1] == 1'b0) begin
                o_load_data =
                    {{16{1'b0}}, i_memory_word[15:0]};
            end
            else begin
                o_load_data =
                    {{16{1'b0}}, i_memory_word[31:16]};
            end
        end

         `F3_LW : begin
            if(i_address[1:0]!=2'b00) begin
                o_misaligned=1'b1;
            end
            else begin
                o_load_data=i_memory_word;
            end
      
          
       end

        default:  begin
            o_load_data = {`DATA_WIDTH{1'b0}};
        end
    endcase
    end

   else if(i_mem_write) begin
        case (i_funct3)
            `F3_SB: begin
                case (i_address[1:0])
                   2'b00 :begin
                    o_store_data={24'b0,i_store_data[7:0]};
                    o_byte_enable=4'b0001;
                   end
                    2'b01 :begin
                    o_store_data={16'b0,i_store_data[7:0],8'b0};
                    o_byte_enable=4'b0010;
                   end
                    2'b10 :begin
                    o_store_data={8'b0,i_store_data[7:0],16'b0};
                    o_byte_enable=4'b0100;
                   end
                    2'b11 :begin
                     o_store_data  = {i_store_data[7:0], 24'b0};
                    o_byte_enable=4'b1000;
                   end
                    
                endcase
            end

            `F3_SH: begin
                if(i_address[0]!=1'b0) begin
                    o_misaligned=1'b1;
                end

                else if (i_address[1]==1'b0) begin
                     o_store_data  = {16'b0, i_store_data[15:0]};
                o_byte_enable = 4'b0011;
                end
                else begin
                o_store_data  = {i_store_data[15:0], 16'b0};
                o_byte_enable = 4'b1100;
            end
            end


        `F3_SW: begin
            if (i_address[1:0] != 2'b00) begin
                o_misaligned = 1'b1;
            end
            else begin
                o_store_data  = i_store_data;
                o_byte_enable = 4'b1111;
            end
        end
            default:  begin
            o_store_data  = {`DATA_WIDTH{1'b0}};
            o_byte_enable = 4'b0000;
        end
        endcase
    end
    
end

endmodule