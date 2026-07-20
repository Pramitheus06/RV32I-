`timescale 1ns/1ps
`include "definitions.vh"

module tb_load_store_unit;

    reg  [`DATA_WIDTH-1:0]  i_address;
    reg  [`FUNCT3_WIDTH-1:0] i_funct3;
    reg                      i_mem_read;
    reg                      i_mem_write;
    reg  [`DATA_WIDTH-1:0]  i_store_data;
    reg  [`DATA_WIDTH-1:0]  i_memory_word;

    wire [`DATA_WIDTH-1:0]  o_load_data;
    wire [`DATA_WIDTH-1:0]  o_store_data;
    wire [3:0]              o_byte_enable;
    wire                    o_misaligned;

    integer pass_count;
    integer fail_count;

    load_store_unit dut (
        .i_address     (i_address),
        .i_funct3      (i_funct3),
        .i_mem_read    (i_mem_read),
        .i_mem_write   (i_mem_write),
        .i_store_data  (i_store_data),
        .i_memory_word (i_memory_word),

        .o_load_data   (o_load_data),
        .o_store_data  (o_store_data),
        .o_byte_enable (o_byte_enable),
        .o_misaligned  (o_misaligned)
    );

    task check_load;
        input [`DATA_WIDTH-1:0] address;
        input [`FUNCT3_WIDTH-1:0] funct3;
        input [`DATA_WIDTH-1:0] expected_data;
        input expected_misaligned;

        begin
            i_address   = address;
            i_funct3    = funct3;
            i_mem_read  = 1'b1;
            i_mem_write = 1'b0;

            #1;

            if ((o_load_data === expected_data) &&
                (o_misaligned === expected_misaligned)) begin

                pass_count = pass_count + 1;

                $display(
                    "PASS LOAD: addr=%h funct3=%b data=%h misaligned=%b",
                    address,
                    funct3,
                    o_load_data,
                    o_misaligned
                );
            end
            else begin
                fail_count = fail_count + 1;

                $display(
                    "FAIL LOAD: addr=%h funct3=%b data=%h expected=%h misaligned=%b expected_misaligned=%b",
                    address,
                    funct3,
                    o_load_data,
                    expected_data,
                    o_misaligned,
                    expected_misaligned
                );
            end
        end
    endtask

    task check_store;
        input [`DATA_WIDTH-1:0] address;
        input [`FUNCT3_WIDTH-1:0] funct3;
        input [`DATA_WIDTH-1:0] store_value;
        input [`DATA_WIDTH-1:0] expected_store_data;
        input [3:0] expected_byte_enable;
        input expected_misaligned;

        begin
            i_address    = address;
            i_funct3     = funct3;
            i_store_data = store_value;
            i_mem_read   = 1'b0;
            i_mem_write  = 1'b1;

            #1;

            if ((o_store_data === expected_store_data) &&
                (o_byte_enable === expected_byte_enable) &&
                (o_misaligned === expected_misaligned)) begin

                pass_count = pass_count + 1;

                $display(
                    "PASS STORE: addr=%h funct3=%b data=%h byte_enable=%b misaligned=%b",
                    address,
                    funct3,
                    o_store_data,
                    o_byte_enable,
                    o_misaligned
                );
            end
            else begin
                fail_count = fail_count + 1;

                $display(
                    "FAIL STORE: addr=%h funct3=%b data=%h expected_data=%h byte_enable=%b expected_enable=%b misaligned=%b expected_misaligned=%b",
                    address,
                    funct3,
                    o_store_data,
                    expected_store_data,
                    o_byte_enable,
                    expected_byte_enable,
                    o_misaligned,
                    expected_misaligned
                );
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        i_address     = 32'b0;
        i_funct3      = 3'b0;
        i_mem_read    = 1'b0;
        i_mem_write   = 1'b0;
        i_store_data  = 32'b0;

        // Memory bytes:
        // byte 3 = 80
        // byte 2 = FF
        // byte 1 = 7F
        // byte 0 = 01
        i_memory_word = 32'h80FF7F01;

        #1;

        $display("========================================");
        $display("LOAD TESTS");
        $display("========================================");

        // LB tests
        check_load(32'h00000000, `F3_LB,  32'h00000001, 1'b0);
        check_load(32'h00000001, `F3_LB,  32'h0000007F, 1'b0);
        check_load(32'h00000002, `F3_LB,  32'hFFFFFFFF, 1'b0);
        check_load(32'h00000003, `F3_LB,  32'hFFFFFF80, 1'b0);

        // LBU tests
        check_load(32'h00000000, `F3_LBU, 32'h00000001, 1'b0);
        check_load(32'h00000001, `F3_LBU, 32'h0000007F, 1'b0);
        check_load(32'h00000002, `F3_LBU, 32'h000000FF, 1'b0);
        check_load(32'h00000003, `F3_LBU, 32'h00000080, 1'b0);

        // LH tests
        check_load(32'h00000000, `F3_LH,  32'h00007F01, 1'b0);
        check_load(32'h00000002, `F3_LH,  32'hFFFF80FF, 1'b0);

        // Misaligned LH
        check_load(32'h00000001, `F3_LH,  32'h00000000, 1'b1);

        // LHU tests
        check_load(32'h00000000, `F3_LHU, 32'h00007F01, 1'b0);
        check_load(32'h00000002, `F3_LHU, 32'h000080FF, 1'b0);

        // LW tests
        check_load(32'h00000000, `F3_LW,  32'h80FF7F01, 1'b0);

        // Misaligned LW
        check_load(32'h00000002, `F3_LW,  32'h00000000, 1'b1);

        $display("========================================");
        $display("STORE TESTS");
        $display("========================================");

        // SB tests: only i_store_data[7:0] = AA is stored
        check_store(
            32'h00000000,
            `F3_SB,
            32'h123456AA,
            32'h000000AA,
            4'b0001,
            1'b0
        );

        check_store(
            32'h00000001,
            `F3_SB,
            32'h123456AA,
            32'h0000AA00,
            4'b0010,
            1'b0
        );

        check_store(
            32'h00000002,
            `F3_SB,
            32'h123456AA,
            32'h00AA0000,
            4'b0100,
            1'b0
        );

        check_store(
            32'h00000003,
            `F3_SB,
            32'h123456AA,
            32'hAA000000,
            4'b1000,
            1'b0
        );

        // SH lower halfword
        check_store(
            32'h00000000,
            `F3_SH,
            32'h1234ABCD,
            32'h0000ABCD,
            4'b0011,
            1'b0
        );

        // SH upper halfword
        check_store(
            32'h00000002,
            `F3_SH,
            32'h1234ABCD,
            32'hABCD0000,
            4'b1100,
            1'b0
        );

        // Misaligned SH
        check_store(
            32'h00000001,
            `F3_SH,
            32'h1234ABCD,
            32'h00000000,
            4'b0000,
            1'b1
        );

        // SW aligned
        check_store(
            32'h00000000,
            `F3_SW,
            32'h1234ABCD,
            32'h1234ABCD,
            4'b1111,
            1'b0
        );

        // SW misaligned
        check_store(
            32'h00000002,
            `F3_SW,
            32'h1234ABCD,
            32'h00000000,
            4'b0000,
            1'b1
        );

        i_mem_read  = 1'b0;
        i_mem_write = 1'b0;

        $display("========================================");
        $display("TEST SUMMARY");
        $display("Passed = %0d", pass_count);
        $display("Failed = %0d", fail_count);

        if (fail_count == 0)
            $display("ALL LOAD/STORE UNIT TESTS PASSED");
        else
            $display("LOAD/STORE UNIT TEST FAILED");

        $display("========================================");

        $stop;
    end

endmodule