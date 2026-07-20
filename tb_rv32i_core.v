`timescale 1ns/1ps

module tb_rv32i_core;

    reg  i_clk;
    reg  i_rst;
    wire o_halt;

    integer cycle_count;

    rv32i_core dut (
        .i_clk  (i_clk),
        .i_rst  (i_rst),
        .o_halt (o_halt)
    );

    // 100 MHz clock
    initial begin
        i_clk = 1'b0;
        forever #5 i_clk = ~i_clk;
    end

    initial begin
        i_rst       = 1'b1;
        cycle_count = 0;

        // Hold reset for two clock cycles
        #20;
        i_rst = 1'b0;

        while ((o_halt !== 1'b1) && (cycle_count < 500)) begin
            @(posedge i_clk);
            #1;

            cycle_count = cycle_count + 1;

            $display(
                "Cycle=%0d PC=%08h INST=%08h ALU=%08h",
                cycle_count,
                dut.pc,
                dut.instruc,
                dut.alu_result
            );
        end

        $display("--------------------------------");

        if (o_halt === 1'b1) begin
            $display("CPU HALTED SUCCESSFULLY");
            $display("Cycles    = %0d", cycle_count);
            $display("PC        = %08h", dut.pc);
            $display("INST      = %08h", dut.instruc);
            $display("x2        = %08h", dut.reg_inst.registers[2]);
            $display("x3        = %08h", dut.reg_inst.registers[3]);
            $display("memory[0] = %08h", dut.data_inst.memory[0]);

            if (dut.data_inst.memory[0] === 32'h00000037) begin
                $display("FIBONACCI TEST PASSED");
            end
            else begin
                $display("FIBONACCI TEST FAILED");
                $display("Expected memory[0] = 00000037");
                $display("Actual   memory[0] = %08h",
                         dut.data_inst.memory[0]);
            end
        end
        else begin
            $display("ERROR: CPU TIMEOUT");
            $display("PC   = %08h", dut.pc);
            $display("INST = %08h", dut.instruc);
        end

        $display("--------------------------------");

        $stop;
    end

endmodule