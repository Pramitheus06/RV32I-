`timescale 1ns/1ps

module tb_rv32i_multicycle_core;

    reg i_clk;
    reg i_rst;
    wire o_halt;

    integer cycle_count;
    integer write_count;
    integer store_count;
    integer errors;
    integer index;

    reg [4:0]  expected_rd   [0:23];
    reg [31:0] expected_data [0:23];
    reg [31:0] expected_store_address [0:3];
    reg [3:0]  expected_store_enable  [0:3];

    rv32i_multicycle_core dut (
        .i_clk  (i_clk),
        .i_rst  (i_rst),
        .o_halt (o_halt)
    );

    always #5 i_clk = ~i_clk;

    task check;
        input condition;
        input [8*96-1:0] label;
        begin
            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL @ %0t: %0s", $time, label);
            end
        end
    endtask

    task initialise_expectations;
        begin
            expected_rd[0]  = 5'd1;  expected_data[0]  = 32'h00000005;
            expected_rd[1]  = 5'd2;  expected_data[1]  = 32'hfffffffd;
            expected_rd[2]  = 5'd3;  expected_data[2]  = 32'h00000002;
            expected_rd[3]  = 5'd4;  expected_data[3]  = 32'h00000008;
            expected_rd[4]  = 5'd5;  expected_data[4]  = 32'h0000000a;
            expected_rd[5]  = 5'd6;  expected_data[5]  = 32'h0000000f;
            expected_rd[6]  = 5'd7;  expected_data[6]  = 32'h00000014;
            expected_rd[7]  = 5'd8;  expected_data[7]  = 32'h00000001;
            expected_rd[8]  = 5'd9;  expected_data[8]  = 32'h00000000;
            expected_rd[9]  = 5'd10; expected_data[9]  = 32'h12345000;
            expected_rd[10] = 5'd11; expected_data[10] = 32'h00000028;
            expected_rd[11] = 5'd12; expected_data[11] = 32'h00000008;
            expected_rd[12] = 5'd13; expected_data[12] = 32'h00000005;
            expected_rd[13] = 5'd14; expected_data[13] = 32'hffffffff;
            expected_rd[14] = 5'd15; expected_data[14] = 32'hffffffff;
            expected_rd[15] = 5'd16; expected_data[15] = 32'h000000ff;
            expected_rd[16] = 5'd17; expected_data[16] = 32'h00000008;
            expected_rd[17] = 5'd18; expected_data[17] = 32'h00000012;
            expected_rd[18] = 5'd19; expected_data[18] = 32'h00000013;
            expected_rd[19] = 5'd20; expected_data[19] = 32'h00000070;
            expected_rd[20] = 5'd21; expected_data[20] = 32'h00000015;
            expected_rd[21] = 5'd22; expected_data[21] = 32'h00000088;
            expected_rd[22] = 5'd23; expected_data[22] = 32'h00000080;
            expected_rd[23] = 5'd24; expected_data[23] = 32'h00000018;

            expected_store_address[0] = 32'h00000000;
            expected_store_address[1] = 32'h00000004;
            expected_store_address[2] = 32'h00000005;
            expected_store_address[3] = 32'h00000006;

            expected_store_enable[0] = 4'b1111;
            expected_store_enable[1] = 4'b0001;
            expected_store_enable[2] = 4'b0010;
            expected_store_enable[3] = 4'b1100;
        end
    endtask

    always @(posedge i_clk) begin
        if (i_rst) begin
            cycle_count = 0;
        end
        else begin
            cycle_count = cycle_count + 1;

            if (dut.reg_write_enable) begin
                if (write_count >= 24) begin
                    errors = errors + 1;
                    $display("FAIL @ %0t: unexpected extra register write x%0d = %h",
                             $time, dut.rd_addr, dut.writeback_data);
                end
                else begin
                    if (dut.rd_addr !== expected_rd[write_count]) begin
                        errors = errors + 1;
                        $display("FAIL @ %0t: write %0d expected x%0d, got x%0d",
                                 $time, write_count,
                                 expected_rd[write_count], dut.rd_addr);
                    end

                    if (dut.writeback_data !== expected_data[write_count]) begin
                        errors = errors + 1;
                        $display("FAIL @ %0t: write %0d to x%0d expected %h, got %h",
                                 $time, write_count, dut.rd_addr,
                                 expected_data[write_count], dut.writeback_data);
                    end
                end
                write_count = write_count + 1;
            end

            if (dut.mem_write && !dut.misaligned) begin
                if (store_count >= 4) begin
                    errors = errors + 1;
                    $display("FAIL @ %0t: unexpected extra store to %h",
                             $time, dut.alu_out);
                end
                else begin
                    if (dut.alu_out !== expected_store_address[store_count]) begin
                        errors = errors + 1;
                        $display("FAIL @ %0t: store %0d expected address %h, got %h",
                                 $time, store_count,
                                 expected_store_address[store_count], dut.alu_out);
                    end

                    if (dut.byte_enable !== expected_store_enable[store_count]) begin
                        errors = errors + 1;
                        $display("FAIL @ %0t: store %0d expected byte enable %b, got %b",
                                 $time, store_count,
                                 expected_store_enable[store_count], dut.byte_enable);
                    end
                end
                store_count = store_count + 1;
            end
        end
    end

    always @(negedge i_clk) begin
        if (!i_rst && !o_halt)
            check(dut.pc[1:0] == 2'b00, "PC must remain word-aligned");
    end

    initial begin
        i_clk       = 1'b0;
        i_rst       = 1'b1;
        cycle_count = 0;
        write_count = 0;
        store_count = 0;
        errors      = 0;
        initialise_expectations;

        repeat (3) @(posedge i_clk);
        @(negedge i_clk);
        i_rst = 1'b0;

        wait (o_halt === 1'b1);
        repeat (2) @(posedge i_clk);
        #1;

        check(dut.controller_halt === 1'b1,
              "controller must settle in persistent HALT state");
        check(write_count == 24,
              "program must produce exactly 24 architectural register writes");
        check(store_count == 4,
              "program must execute exactly four stores");
        check(dut.pc == 32'h00000094,
              "PC after fetching final EBREAK must be 0x94");

        if (errors == 0)
            $display("PASS: full multicycle CPU test completed in %0d cycles", cycle_count);
        else
            $display("FAIL: full multicycle CPU test completed with %0d errors", errors);

        $finish;
    end

    initial begin
        repeat (500) @(posedge i_clk);
        $display("FAIL: CPU timeout after 500 clock cycles; pc=%h IR=%h state=%b",
                 dut.pc, dut.IR, dut.controller_inst.state);
        $finish;
    end

endmodule
