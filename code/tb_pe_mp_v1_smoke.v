`timescale 1ns/1ps
`default_nettype none

module tb_pe_mp_v1_smoke;
    reg         clk;
    reg         rst_n;
    reg         pe_en;
    reg [31:0]  dat_in_b;
    reg         in_b_lock;
    reg [1:0]   cpt_mode;
    reg [31:0]  dat_in_a;
    reg         dat_in_vld;
    reg [31:0]  dat_in_add;
    reg         dat_in_add_vld;
    wire [31:0] dat_out;
    wire        dat_out_vld;
    wire [31:0] out_a;
    wire        out_a_vld;

    integer errors;

    // Device under test. The smoke test keeps all stimulus at the PE boundary
    // so it checks the same interface that upper-level logic will drive.
    PE_MP_v1 dut (
        .pe_ckg         (clk),
        .tpu_rst_n      (rst_n),
        .pe_en          (pe_en),
        .dat_in_b       (dat_in_b),
        .in_b_lock      (in_b_lock),
        .cpt_mode       (cpt_mode),
        .dat_in_a       (dat_in_a),
        .dat_in_vld     (dat_in_vld),
        .dat_in_add     (dat_in_add),
        .dat_in_add_vld (dat_in_add_vld),
        .dat_out        (dat_out),
        .dat_out_vld    (dat_out_vld),
        .out_a          (out_a),
        .out_a_vld      (out_a_vld)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

`ifdef FSDB
    // Dump a full FSDB waveform when the testbench is compiled with +define+FSDB.
    // The normal smoke run does not enable this, so fast regression stays clean.
    initial begin
        $fsdbDumpfile("pe_mp_v1.fsdb");
        $fsdbDumpvars(0, tb_pe_mp_v1_smoke);
    end
`endif

    // Compare a 32-bit value and count errors instead of stopping at the first
    // failure. This gives a fuller picture when several modes are tested.
    task check32;
        input [1023:0] name;
        input [31:0]   got;
        input [31:0]   exp;
        begin
            if (got !== exp) begin
                $display("FAIL %0s got=%h exp=%h", name, got, exp);
                errors = errors + 1;
            end
        end
    endtask

    // One-bit checker for valid/bypass control signals.
    task check1;
        input [1023:0] name;
        input          got;
        input          exp;
        begin
            if (got !== exp) begin
                $display("FAIL %0s got=%b exp=%b", name, got, exp);
                errors = errors + 1;
            end
        end
    endtask

    // Clear input valids for one cycle between directed cases so each result
    // pulse is easy to attribute to one transaction.
    task idle_cycle;
        begin
            dat_in_vld     = 1'b0;
            dat_in_add_vld = 1'b0;
            dat_in_a       = 32'd0;
            dat_in_add     = 32'd0;
            @(posedge clk);
            #1;
        end
    endtask

    // Load the stationary B operand. PE_MP_v1 gives in_b_lock priority over
    // pe_en clearing, matching the intended preload behavior.
    task lock_b;
        input [1:0]  mode;
        input [31:0] value;
        begin
            cpt_mode  = mode;
            dat_in_b  = value;
            in_b_lock = 1'b1;
            @(posedge clk);
            #1;
            in_b_lock = 1'b0;
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 1'b0;
        pe_en = 1'b0;
        dat_in_b = 32'd0;
        in_b_lock = 1'b0;
        cpt_mode = 2'b00;
        dat_in_a = 32'd0;
        dat_in_vld = 1'b0;
        dat_in_add = 32'd0;
        dat_in_add_vld = 1'b0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        #1;

        // Bypass mode: when pe_en is low, PE forwards dat_in_add to dat_out
        // and keeps the A-forward path inactive.
        pe_en = 1'b0;
        dat_in_a = 32'h1234_5678;
        dat_in_add = 32'h8765_4321;
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b1;
        #1;
        check32("bypass dat_out", dat_out, 32'h8765_4321);
        check1 ("bypass dat_out_vld", dat_out_vld, 1'b1);
        check32("bypass out_a", out_a, 32'd0);
        check1 ("bypass out_a_vld", out_a_vld, 1'b0);
        @(posedge clk);
        #1;

        pe_en = 1'b1;
        dat_in_vld = 1'b0;
        dat_in_add_vld = 1'b0;

        // INT4 directed cases. The DUT follows the reference template and
        // expects negative operands to be sign-extended to 32 bits upstream.
        lock_b(2'b00, 32'h0000_0003);
        dat_in_a = 32'hFFFF_FFFE; // INT4 -2, sign-extended by upstream logic
        dat_in_add = 32'd5;
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b1;
        @(posedge clk);
        #1;
        check1 ("int4 vld", dat_out_vld, 1'b1);
        check32("int4 out", dat_out, 32'hFFFF_FFFF);

        idle_cycle();

        lock_b(2'b00, 32'hFFFF_FFFE); // INT4 -2, sign-extended by upstream logic
        dat_in_a = 32'hFFFF_FFFF;     // INT4 -1, sign-extended by upstream logic
        dat_in_add = 32'd3;
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b1;
        @(posedge clk);
        #1;
        check1 ("int4 neg neg vld", dat_out_vld, 1'b1);
        check32("int4 neg neg out", dat_out, 32'd5);

        idle_cycle();

        lock_b(2'b00, 32'hFFFF_FFF8); // INT4 -8, sign-extended by upstream logic
        dat_in_a = 32'h0000_0007;     // INT4 7
        dat_in_add = 32'd56;
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b1;
        @(posedge clk);
        #1;
        check1 ("int4 cancel vld", dat_out_vld, 1'b1);
        check32("int4 cancel out", dat_out, 32'd0);

        idle_cycle();

        // INT8 directed cases. The DUT follows the reference template and
        // expects negative operands to be sign-extended to 32 bits upstream.
        lock_b(2'b01, 32'hFFFF_FFFE); // INT8 -2, sign-extended by upstream logic
        dat_in_a = 32'h0000_0003;
        dat_in_add = 32'd10;
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b1;
        @(posedge clk);
        #1;
        check1 ("int8 vld", dat_out_vld, 1'b1);
        check32("int8 out", dat_out, 32'd4);

        idle_cycle();

        lock_b(2'b01, 32'hFFFF_FFFF); // INT8 -1, sign-extended by upstream logic
        dat_in_a = 32'hFFFF_FF80;     // INT8 -128, sign-extended by upstream logic
        dat_in_add = 32'hFFFF_FF80;   // -128
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b1;
        @(posedge clk);
        #1;
        check1 ("int8 edge vld", dat_out_vld, 1'b1);
        check32("int8 edge out", dat_out, 32'd0);

        idle_cycle();

        lock_b(2'b01, 32'h0000_007F); // INT8 127
        dat_in_a = 32'hFFFF_FFFE;     // INT8 -2, sign-extended by upstream logic
        dat_in_add = 32'd254;
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b1;
        @(posedge clk);
        #1;
        check1 ("int8 cancel vld", dat_out_vld, 1'b1);
        check32("int8 cancel out", dat_out, 32'd0);

        idle_cycle();

        // FP32 cases. dat_in_add_vld is driven only after the multiplier valid
        // appears, modeling the external controller's alignment responsibility.
        lock_b(2'b11, 32'h4000_0000); // FP32 2.0
        dat_in_a = 32'h3F80_0000;     // FP32 1.0
        dat_in_add = 32'd0;
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b0;
        @(posedge clk);
        #1;
        dat_in_vld = 1'b0;
        dat_in_add_vld = 1'b0;
        wait (dut.fp32_muti_vld === 1'b1);
        dat_in_add = 32'h4040_0000;   // FP32 3.0, externally aligned
        dat_in_add_vld = 1'b1;
        @(posedge clk);
        #1;
        check1 ("fp32 vld", dat_out_vld, 1'b1);
        check32("fp32 out", dat_out, 32'h40A0_0000); // 5.0
        dat_in_add_vld = 1'b0;

        idle_cycle();

        lock_b(2'b11, 32'h4040_0000); // FP32 3.0
        dat_in_a = 32'h4000_0000;     // FP32 2.0
        dat_in_add = 32'd0;
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b0;
        @(posedge clk);
        #1;
        dat_in_vld = 1'b0;
        wait (dut.fp32_muti_vld === 1'b1);
        dat_in_add = 32'h4080_0000;   // FP32 4.0
        dat_in_add_vld = 1'b1;
        @(posedge clk);
        #1;
        check1 ("fp32 2x3+4 vld", dat_out_vld, 1'b1);
        check32("fp32 2x3+4 out", dat_out, 32'h4120_0000); // 10.0
        dat_in_add_vld = 1'b0;

        idle_cycle();

        lock_b(2'b11, 32'h4000_0000); // FP32 2.0
        dat_in_a = 32'hBF80_0000;     // FP32 -1.0
        dat_in_add = 32'd0;
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b0;
        @(posedge clk);
        #1;
        dat_in_vld = 1'b0;
        wait (dut.fp32_muti_vld === 1'b1);
        dat_in_add = 32'h40A0_0000;   // FP32 5.0
        dat_in_add_vld = 1'b1;
        @(posedge clk);
        #1;
        check1 ("fp32 signed vld", dat_out_vld, 1'b1);
        check32("fp32 signed out", dat_out, 32'h4040_0000); // 3.0
        dat_in_add_vld = 1'b0;

        idle_cycle();

        // FP16 cases. The DUT converts FP16 operands to INT16, multiplies them,
        // converts the product to FP32, then adds the externally aligned FP32 addend.
        lock_b(2'b10, 32'h0000_C000); // FP16 -2.0
        dat_in_a = 32'h0000_4200;     // FP16 3.0
        dat_in_add = 32'd0;
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b0;
        @(posedge clk);
        #1;
        dat_in_vld = 1'b0;
        dat_in_add_vld = 1'b0;
        wait (dut.fp16_fix2fp_out_vld === 1'b1);
        dat_in_add = 32'h4120_0000;   // FP32 10.0, externally aligned
        dat_in_add_vld = 1'b1;
        @(posedge clk);
        #1;
        check1 ("fp16 vld", dat_out_vld, 1'b1);
        check32("fp16 out", dat_out, 32'h4080_0000); // 4.0
        dat_in_add_vld = 1'b0;

        idle_cycle();

        lock_b(2'b10, 32'h0000_4400); // FP16 4.0
        dat_in_a = 32'h0000_4000;     // FP16 2.0
        dat_in_add = 32'd0;
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b0;
        @(posedge clk);
        #1;
        dat_in_vld = 1'b0;
        wait (dut.fp16_fix2fp_out_vld === 1'b1);
        dat_in_add = 32'h3F80_0000;   // FP32 1.0
        dat_in_add_vld = 1'b1;
        @(posedge clk);
        #1;
        check1 ("fp16 2x4+1 vld", dat_out_vld, 1'b1);
        check32("fp16 2x4+1 out", dat_out, 32'h4110_0000); // 9.0
        dat_in_add_vld = 1'b0;

        idle_cycle();

        lock_b(2'b10, 32'h0000_4200); // FP16 3.0
        dat_in_a = 32'h0000_BC00;     // FP16 -1.0
        dat_in_add = 32'd0;
        dat_in_vld = 1'b1;
        dat_in_add_vld = 1'b0;
        @(posedge clk);
        #1;
        dat_in_vld = 1'b0;
        wait (dut.fp16_fix2fp_out_vld === 1'b1);
        dat_in_add = 32'h4100_0000;   // FP32 8.0
        dat_in_add_vld = 1'b1;
        @(posedge clk);
        #1;
        check1 ("fp16 signed vld", dat_out_vld, 1'b1);
        check32("fp16 signed out", dat_out, 32'h40A0_0000); // 5.0
        dat_in_add_vld = 1'b0;

        if (errors == 0) begin
            $display("PE_MP_v1 smoke PASS");
        end
        else begin
            $display("PE_MP_v1 smoke FAIL errors=%0d", errors);
        end
        $finish;
    end

endmodule

`default_nettype wire
