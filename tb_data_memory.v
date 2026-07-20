`timescale 1ns/1ps

`define DATA_WIDTH 32

module tb_data_memory;

    localparam MEM_WORDS = 1024;

    reg i_clk;
    reg i_we;
    reg [`DATA_WIDTH-1:0] i_data;
    reg [31:0] i_addr;
    wire [`DATA_WIDTH-1:0] o_data;

    integer errors;

    data_memory #(
        .MEM_WORDS(MEM_WORDS)
    ) dut (
        .i_clk(i_clk),
        .i_we(i_we),
        .i_data(i_data),
        .i_addr(i_addr),
        .o_data(o_data)
    );

    // Clock generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    task check_read;
        input [31:0] addr;
        input [31:0] expected;
        begin
            i_addr = addr;
            #1; // because read is asynchronous

            if (o_data !== expected) begin
                $display("FAIL: addr = %h, expected = %h, got = %h",
                         addr, expected, o_data);
                errors = errors + 1;
            end else begin
                $display("PASS: addr = %h, data = %h", addr, o_data);
            end
        end
    endtask

    task write_word;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(negedge i_clk);
            i_addr = addr;
            i_data = data;
            i_we   = 1'b1;

            @(posedge i_clk);
            #1;

            i_we = 1'b0;
        end
    endtask

    initial begin
        errors = 0;

        i_we   = 0;
        i_data = 0;
        i_addr = 0;

        // Wait for initial block and $readmemh to finish
        #10;

        $display("---- Checking data.hex preload ----");

        check_read(32'h00000000, 32'h6c6c6548);
        check_read(32'h00000004, 32'h6f77206f);
        check_read(32'h00000008, 32'h21646c72);
        check_read(32'h0000000c, 32'h00000a0d);

        check_read(32'h00000024, 32'h00000014);
        check_read(32'h00000028, 32'h74786554);
        check_read(32'h00000030, 32'he0000000);

        $display("---- Checking zero-initialized area ----");

        check_read(32'h00000048, 32'h00000000); // word 18, should be zero
        check_read(32'h00000100, 32'h00000000);

        $display("---- Checking write/read ----");

        write_word(32'h00000040, 32'hdeadbeef);
        check_read(32'h00000040, 32'hdeadbeef);

        write_word(32'h00000044, 32'h12345678);
        check_read(32'h00000044, 32'h12345678);

        $display("---- Checking last valid word ----");

        write_word(32'h00000ffc, 32'hcafebabe); // 1023 * 4 = 4092 = 0xffc
        check_read(32'h00000ffc, 32'hcafebabe);

        $display("---- Final result ----");

        if (errors == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("TEST FAILED: %0d errors", errors);
        end

        $finish;
    end

endmodule