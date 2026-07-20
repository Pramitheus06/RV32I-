`timescale 1ns/1ps

module tb_register_file;

    parameter DATA_WIDTH = 32;

    reg                   clk;
    reg                   rst;
    reg                   we;
    reg  [DATA_WIDTH-1:0] rd;
    reg  [4:0]            rd_addr;
    reg  [4:0]            rs1_addr;
    reg  [4:0]            rs2_addr;

    wire [DATA_WIDTH-1:0] o_rs1;
    wire [DATA_WIDTH-1:0] o_rs2;

    integer test_count;
    integer error_count;


    // Instantiate register file
    register_file dut (
        .clk      (clk),
        .rst      (rst),
        .we       (we),
        .rd       (rd),
        .rd_addr  (rd_addr),
        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .o_rs1    (o_rs1),
        .o_rs2    (o_rs2)
    );


    // 10 ns clock period
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end


    // Write value into a register
    task write_register;
        input [4:0] address;
        input [DATA_WIDTH-1:0] data;

        begin
            // Set signals before the active clock edge
            @(negedge clk);

            we      = 1'b1;
            rd_addr = address;
            rd      = data;

            // Write occurs here
            @(posedge clk);
            #1;

            we      = 1'b0;
            rd_addr = 5'd0;
            rd      = 32'd0;
        end
    endtask


    // Check both read ports
    task check_registers;
        input [4:0] address1;
        input [DATA_WIDTH-1:0] expected1;

        input [4:0] address2;
        input [DATA_WIDTH-1:0] expected2;

        begin
            rs1_addr = address1;
            rs2_addr = address2;

            // Reads are asynchronous, so no clock edge is needed
            #1;

            test_count = test_count + 1;

            if ((o_rs1 !== expected1) ||
                (o_rs2 !== expected2)) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] Test %0d at time %0t",
                    test_count,
                    $time
                );

                $display(
                    "       rs1=x%0d, expected=%h, received=%h",
                    address1,
                    expected1,
                    o_rs1
                );

                $display(
                    "       rs2=x%0d, expected=%h, received=%h",
                    address2,
                    expected2,
                    o_rs2
                );
            end
            else begin
                $display(
                    "[PASS] Test %0d: x%0d=%h, x%0d=%h",
                    test_count,
                    address1,
                    o_rs1,
                    address2,
                    o_rs2
                );
            end
        end
    endtask


    // Main test sequence
    initial begin

        test_count = 0;
        error_count = 0;

        rst      = 1'b0;
        we       = 1'b0;
        rd       = 32'd0;
        rd_addr  = 5'd0;
        rs1_addr = 5'd0;
        rs2_addr = 5'd0;


        $display("========================================");
        $display("Starting RV32I Register File Testbench");
        $display("========================================");


        // --------------------------------------------------
        // Test 1: Reset
        // --------------------------------------------------

        $display("\nTesting reset...");

        rst = 1'b1;
        #2;

        check_registers(
            5'd1,  32'd0,
            5'd31, 32'd0
        );

        rst = 1'b0;


        // --------------------------------------------------
        // Test 2: Write and read x1
        // --------------------------------------------------

        $display("\nTesting write to x1...");

        write_register(
            5'd1,
            32'h1234_5678
        );

        check_registers(
            5'd1, 32'h1234_5678,
            5'd0, 32'h0000_0000
        );


        // --------------------------------------------------
        // Test 3: Write and read two registers
        // --------------------------------------------------

        $display("\nTesting simultaneous reads...");

        write_register(
            5'd2,
            32'hABCD_EF01
        );

        write_register(
            5'd5,
            32'hDEAD_BEEF
        );

        check_registers(
            5'd2, 32'hABCD_EF01,
            5'd5, 32'hDEAD_BEEF
        );


        // --------------------------------------------------
        // Test 4: Highest register x31
        // --------------------------------------------------

        $display("\nTesting x31...");

        write_register(
            5'd31,
            32'hFFFF_FFFF
        );

        check_registers(
            5'd31, 32'hFFFF_FFFF,
            5'd1,  32'h1234_5678
        );


        // --------------------------------------------------
        // Test 5: Overwrite a register
        // --------------------------------------------------

        $display("\nTesting register overwrite...");

        write_register(
            5'd1,
            32'hCAFE_BABE
        );

        check_registers(
            5'd1, 32'hCAFE_BABE,
            5'd2, 32'hABCD_EF01
        );


        // --------------------------------------------------
        // Test 6: Attempt to write x0
        // --------------------------------------------------

        $display("\nTesting protected x0 register...");

        write_register(
            5'd0,
            32'hFFFF_1234
        );

        check_registers(
            5'd0, 32'h0000_0000,
            5'd1, 32'hCAFE_BABE
        );


        // --------------------------------------------------
        // Test 7: No write when write-enable is zero
        // --------------------------------------------------

        $display("\nTesting disabled write...");

        @(negedge clk);

        we      = 1'b0;
        rd_addr = 5'd2;
        rd      = 32'h1111_1111;

        @(posedge clk);
        #1;

        check_registers(
            5'd2, 32'hABCD_EF01,
            5'd5, 32'hDEAD_BEEF
        );


        // --------------------------------------------------
        // Test 8: Asynchronous reset clears registers
        // --------------------------------------------------

        $display("\nTesting asynchronous reset...");

        rs1_addr = 5'd1;
        rs2_addr = 5'd31;

        #1;

        rst = 1'b1;

        // Do not wait for a clock edge
        #1;

        check_registers(
            5'd1,  32'h0000_0000,
            5'd31, 32'h0000_0000
        );

        rst = 1'b0;


        // --------------------------------------------------
        // Final result
        // --------------------------------------------------

        $display("\n========================================");

        if (error_count == 0) begin
            $display(
                "ALL %0d TESTS PASSED",
                test_count
            );
        end
        else begin
            $display(
                "%0d OF %0d TESTS FAILED",
                error_count,
                test_count
            );
        end

        $display("========================================");

        #10;
        $stop;
    end


endmodule