`timescale 1ns/1ps
`include "definitions.vh"

module tb_multicycle_controller;

    localparam STATE_IF   = 5'b00001;
    localparam STATE_ID   = 5'b00010;
    localparam STATE_EXE  = 5'b00100;
    localparam STATE_MEM  = 5'b01000;
    localparam STATE_WB   = 5'b10000;
    localparam STATE_HALT = 5'b11111;

    reg i_clk;
    reg i_rst;
    reg i_illegal_instruction;
    reg i_ecall;
    reg i_ebreak;
    reg i_misaligned;
    reg i_branch_taken;
    reg [`OPCODE_WIDTH-1:0] i_opcode;
    reg [`ALU_OP_WIDTH-1:0] i_dec_alu_op;

    wire o_pc_write;
    wire o_ir_write;
    wire o_instruction_pc_write;
    wire o_mem_write;
    wire o_reg_write;
    wire [`ALU_OP_WIDTH-1:0] o_alu_op;
    wire [`MC_ALU_SRC_A_WIDTH-1:0] o_alu_src_a;
    wire [`MC_ALU_SRC_B_WIDTH-1:0] o_alu_src_b;
    wire [`MC_WB_SEL_WIDTH-1:0] o_wb_sel;
    wire [`MC_PC_SRC_WIDTH-1:0] o_pc_source;
    wire o_halt;
    wire o_a_write;
    wire o_b_write;
    wire o_aluout_write;
    wire o_mem_read;
    wire o_mdr_write;

    integer checks;
    integer errors;

    multicycle_controller dut (
        .i_clk                    (i_clk),
        .i_rst                    (i_rst),
        .i_illegal_instruction    (i_illegal_instruction),
        .i_ecall                  (i_ecall),
        .i_ebreak                 (i_ebreak),
        .i_misaligned             (i_misaligned),
        .i_branch_taken           (i_branch_taken),
        .i_opcode                 (i_opcode),
        .i_dec_alu_op             (i_dec_alu_op),
        .o_pc_write               (o_pc_write),
        .o_ir_write               (o_ir_write),
        .o_instruction_pc_write   (o_instruction_pc_write),
        .o_mem_write              (o_mem_write),
        .o_reg_write              (o_reg_write),
        .o_alu_op                 (o_alu_op),
        .o_alu_src_a              (o_alu_src_a),
        .o_alu_src_b              (o_alu_src_b),
        .o_wb_sel                 (o_wb_sel),
        .o_pc_source              (o_pc_source),
        .o_halt                   (o_halt),
        .o_a_write                (o_a_write),
        .o_b_write                (o_b_write),
        .o_aluout_write           (o_aluout_write),
        .o_mem_read               (o_mem_read),
        .o_mdr_write              (o_mdr_write)
    );

    task check;
        input condition;
        input [8*96-1:0] label;
        begin
            checks = checks + 1;
            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL @ %0t: %0s", $time, label);
            end
        end
    endtask

    task step;
        begin
            #5 i_clk = 1'b1;
            #1;
            #4 i_clk = 1'b0;
        end
    endtask

    task clear_inputs;
        begin
            i_illegal_instruction = 1'b0;
            i_ecall               = 1'b0;
            i_ebreak              = 1'b0;
            i_misaligned          = 1'b0;
            i_branch_taken        = 1'b0;
            i_opcode              = `OP_ALU;
            i_dec_alu_op          = `ALU_ADD;
        end
    endtask

    task reset_to_if;
        begin
            clear_inputs;
            i_rst = 1'b1;
            step;

            check(dut.state === STATE_IF,
                  "reset must place controller in IF");
            check(o_ir_write === 1'b1,
                  "IF must enable instruction-register write");
            check(o_instruction_pc_write === 1'b1,
                  "IF must save the current instruction PC");
            check(o_pc_write === 1'b1,
                  "IF must enable sequential PC update");
            check(o_alu_src_a === `MC_ALU_A_PC,
                  "IF ALU-A source must be PC");
            check(o_alu_src_b === `MC_ALU_B_FOUR,
                  "IF ALU-B source must be four");
            check(o_alu_op === `ALU_ADD,
                  "IF ALU operation must be ADD");
            check(o_pc_source === `MC_PC_ALU,
                  "IF PC source must be ALU result");

            i_rst = 1'b0;
            #1;
        end
    endtask

    initial begin
        #10000;
        $display("FAIL: testbench timeout at t=%0t, state=%b, next_state=%b",
                 $time, dut.state, dut.next_state);
        $finish;
    end

    task enter_execute;
        input [`OPCODE_WIDTH-1:0] opcode_value;
        input [`ALU_OP_WIDTH-1:0] alu_operation;
        begin
            reset_to_if;
            i_opcode     = opcode_value;
            i_dec_alu_op = alu_operation;

            step;
            check(dut.state === STATE_ID,
                  "IF must transition to ID");
            check(o_a_write === 1'b1 && o_b_write === 1'b1,
                  "ID must capture both register operands");
            check(o_pc_write === 1'b0 && o_reg_write === 1'b0 &&
                  o_mem_write === 1'b0,
                  "ID must not produce architectural side effects");

            step;
            check(dut.state === STATE_EXE,
                  "normal ID must transition to EXE");
        end
    endtask

    task check_halt_outputs;
        begin
            check(dut.state === STATE_HALT,
                  "controller must be in HALT");
            check(o_halt === 1'b1,
                  "HALT state must assert o_halt");
            check(o_pc_write === 1'b0 && o_ir_write === 1'b0 &&
                  o_mem_write === 1'b0 && o_reg_write === 1'b0 &&
                  o_mdr_write === 1'b0,
                  "HALT must suppress all architectural writes");
        end
    endtask

    initial begin
        i_clk  = 1'b0;
        i_rst  = 1'b0;
        checks = 0;
        errors = 0;
        clear_inputs;

`ifdef DUMP_VCD
        $dumpfile("tb_multicycle_controller.vcd");
        $dumpvars(0, tb_multicycle_controller);
`endif

        // Register-register ALU instruction.
        enter_execute(`OP_ALU, `ALU_SUB);
        check(o_alu_src_a === `MC_ALU_A_AREG,
              "OP_ALU must select A register");
        check(o_alu_src_b === `MC_ALU_B_BREG,
              "OP_ALU must select B register");
        check(o_alu_op === `ALU_SUB && o_aluout_write === 1'b1,
              "OP_ALU must use decoded operation and capture result");
        step;
        check(dut.state === STATE_WB,
              "OP_ALU EXE must transition to WB");
        check(o_reg_write === 1'b1 && o_wb_sel === `MC_WB_ALUOUT,
              "OP_ALU WB must write ALUOut");
        step;
        check(dut.state === STATE_IF,
              "OP_ALU WB must return to IF");

        // Immediate ALU instruction.
        enter_execute(`OP_ALUI, `ALU_XOR);
        check(o_alu_src_a === `MC_ALU_A_AREG &&
              o_alu_src_b === `MC_ALU_B_IMM,
              "OP_ALUI must select A register and immediate");
        check(o_alu_op === `ALU_XOR && o_aluout_write === 1'b1,
              "OP_ALUI must use decoded operation and capture result");
        step;
        check(o_reg_write === 1'b1 && o_wb_sel === `MC_WB_ALUOUT,
              "OP_ALUI WB must write ALUOut");

        // AUIPC.
        enter_execute(`OP_AUIPC, `ALU_ADD);
        check(o_alu_src_a === `MC_ALU_A_INSTRUCTION_PC &&
              o_alu_src_b === `MC_ALU_B_IMM &&
              o_aluout_write === 1'b1,
              "AUIPC must add immediate to saved instruction PC");
        step;
        check(o_reg_write === 1'b1 && o_wb_sel === `MC_WB_ALUOUT,
              "AUIPC WB must write ALUOut");

        // LUI.
        enter_execute(`OP_LUI, `ALU_ADD);
        check(o_alu_src_a === `MC_ALU_A_ZERO &&
              o_alu_src_b === `MC_ALU_B_IMM &&
              o_aluout_write === 1'b1,
              "LUI must pass the immediate through the ALU");
        step;
        check(o_reg_write === 1'b1 && o_wb_sel === `MC_WB_ALUOUT,
              "LUI WB must write ALUOut");

        // Untaken branch.
        enter_execute(`OP_BRANCH, `ALU_ADD);
        i_branch_taken = 1'b0;
        #1;
        check(o_alu_src_a === `MC_ALU_A_INSTRUCTION_PC &&
              o_alu_src_b === `MC_ALU_B_IMM,
              "branch must calculate target from saved instruction PC");
        check(o_pc_write === 1'b0,
              "untaken branch must not write PC");
        step;
        check(dut.state === STATE_IF,
              "branch must return directly to IF");

        // Taken branch.
        enter_execute(`OP_BRANCH, `ALU_ADD);
        i_branch_taken = 1'b1;
        #1;
        check(o_pc_write === 1'b1 && o_pc_source === `MC_PC_ALU,
              "taken branch must write ALU target into PC");
        step;
        check(dut.state === STATE_IF,
              "taken branch must return to IF");

        // Aligned load.
        enter_execute(`OP_LOAD, `ALU_ADD);
        check(o_alu_src_a === `MC_ALU_A_AREG &&
              o_alu_src_b === `MC_ALU_B_IMM &&
              o_aluout_write === 1'b1,
              "load EXE must calculate and capture effective address");
        i_misaligned = 1'b0;
        step;
        check(dut.state === STATE_MEM,
              "load EXE must transition to MEM");
        check(o_mem_read === 1'b1 && o_mdr_write === 1'b1,
              "aligned load MEM must read and capture MDR");
        step;
        check(dut.state === STATE_WB,
              "aligned load MEM must transition to WB");
        check(o_reg_write === 1'b1 && o_wb_sel === `MC_WB_MDR,
              "load WB must write MDR");
        step;
        check(dut.state === STATE_IF,
              "load WB must return to IF");

        // Misaligned load.
        enter_execute(`OP_LOAD, `ALU_ADD);
        i_misaligned = 1'b1;
        step;
        check(dut.state === STATE_MEM,
              "misaligned load must still enter MEM");
        check(o_mem_read === 1'b1 && o_mdr_write === 1'b0,
              "misaligned load must preserve intent but not capture MDR");
        step;
        check_halt_outputs;
        step;
        check_halt_outputs;

        // Aligned store.
        enter_execute(`OP_STORE, `ALU_ADD);
        check(o_alu_src_a === `MC_ALU_A_AREG &&
              o_alu_src_b === `MC_ALU_B_IMM &&
              o_aluout_write === 1'b1,
              "store EXE must calculate and capture effective address");
        i_misaligned = 1'b0;
        step;
        check(dut.state === STATE_MEM,
              "store EXE must transition to MEM");
        check(o_mem_write === 1'b1 && o_reg_write === 1'b0,
              "aligned store MEM must assert only memory write");
        step;
        check(dut.state === STATE_IF,
              "aligned store MEM must return to IF");

        // Misaligned store.
        enter_execute(`OP_STORE, `ALU_ADD);
        i_misaligned = 1'b1;
        step;
        check(dut.state === STATE_MEM,
              "misaligned store must still enter MEM");
        check(o_mem_write === 1'b1,
              "misaligned store must preserve store intent for LSU");
        step;
        check_halt_outputs;

        // JAL.
        enter_execute(`OP_JAL, `ALU_ADD);
        check(o_alu_src_a === `MC_ALU_A_INSTRUCTION_PC &&
              o_alu_src_b === `MC_ALU_B_IMM,
              "JAL must calculate target from saved instruction PC");
        check(o_pc_write === 1'b1 && o_pc_source === `MC_PC_ALU &&
              o_reg_write === 1'b1 &&
              o_wb_sel === `MC_WB_PC_PLUS_4,
              "JAL must update PC and write link register");
        step;
        check(dut.state === STATE_IF,
              "JAL must return directly to IF");

        // JALR.
        enter_execute(`OP_JALR, `ALU_ADD);
        check(o_alu_src_a === `MC_ALU_A_AREG &&
              o_alu_src_b === `MC_ALU_B_IMM,
              "JALR must calculate target from A register and immediate");
        check(o_pc_write === 1'b1 &&
              o_pc_source === `MC_PC_ALU_MASKED &&
              o_reg_write === 1'b1 &&
              o_wb_sel === `MC_WB_PC_PLUS_4,
              "JALR must write masked PC target and link register");
        step;
        check(dut.state === STATE_IF,
              "JALR must return directly to IF");

        // FENCE is treated as a NOP by this controller.
        enter_execute(`OP_FENCE, `ALU_ADD);
        check(o_pc_write === 1'b0 && o_reg_write === 1'b0 &&
              o_mem_write === 1'b0 && o_aluout_write === 1'b0,
              "FENCE must not produce architectural writes");
        step;
        check(dut.state === STATE_IF,
              "FENCE must return directly to IF");

        // ECALL detected in ID.
        reset_to_if;
        i_opcode = `OP_SYSTEM;
        i_ecall  = 1'b1;
        step;
        check(dut.state === STATE_ID,
              "ECALL must first reach ID");
        step;
        check_halt_outputs;

        // EBREAK detected in ID.
        reset_to_if;
        i_opcode = `OP_SYSTEM;
        i_ebreak = 1'b1;
        step;
        step;
        check_halt_outputs;

        // Illegal instruction detected in ID.
        reset_to_if;
        i_opcode = 7'b0000000;
        i_illegal_instruction = 1'b1;
        step;
        step;
        check_halt_outputs;

        // Unexpected opcode that reaches EXE must also halt.
        enter_execute(7'b0000000, `ALU_ADD);
        check(o_pc_write === 1'b0 && o_reg_write === 1'b0 &&
              o_mem_write === 1'b0,
              "unexpected EXE opcode must have no side effects");
        step;
        check_halt_outputs;

        // Reset must recover from HALT.
        i_rst = 1'b1;
        step;
        check(dut.state === STATE_IF && o_halt === 1'b0,
              "reset must recover controller from HALT");
        i_rst = 1'b0;

        if (errors == 0)
            $display("PASS: %0d controller checks completed", checks);
        else
            $display("FAIL: %0d of %0d controller checks failed",
                     errors, checks);

        $finish;
    end

endmodule