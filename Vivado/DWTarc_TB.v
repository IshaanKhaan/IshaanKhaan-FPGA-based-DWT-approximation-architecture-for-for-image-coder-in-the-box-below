`timescale 1ns / 1ps

// ============================================================
// DWT ARCHITECTURE TESTBENCH
//
// Simulation only.
//
// This testbench is NOT synthesized and is NOT part of the
// FPGA bitstream.
//
// It verifies the complete DWTarc architecture:
//
//                  DWTarc
//                     |
//              +------+------ +
//              |             |
//          Datapath      controlunit
//
// The testbench:
//   1. Runs the DWTarc hardware
//   2. Captures H and L coefficients
//   3. Captures HH, HL, LH and LL coefficients
//   4. Writes the architecture outputs to HEX files
//
// MATLAB will perform the final comparison against the
// MATLAB golden-reference coefficients.
//
// No Dwtfinal.v files are used here.
// ============================================================


module DWTarc_tb;

    // ========================================================
    // PARAMETERS
    // ========================================================

    parameter IMAGE_ROWS = 300;
    parameter IMAGE_COLS = 332;

    parameter HALF_ROWS = IMAGE_ROWS / 2;
    parameter HALF_COLS = IMAGE_COLS / 2;

    parameter TOTAL_PIXELS =
        IMAGE_ROWS * IMAGE_COLS;

    parameter HORIZONTAL_SIZE =
        IMAGE_ROWS * HALF_COLS;

    parameter OUTPUT_SIZE =
        HALF_ROWS * HALF_COLS;


    // ========================================================
    // CLOCK AND RESET
    // ========================================================

    reg clk;
    reg rst;


    // ========================================================
    // DUT STATUS
    // ========================================================

    wire busy;
    wire done;


    // ========================================================
    // DUT HORIZONTAL OUTPUTS
    // ========================================================

    wire signed [15:0] h_out;
    wire signed [15:0] l_out;

    wire horizontal_valid;


    // ========================================================
    // DUT FINAL OUTPUTS
    // ========================================================

    wire signed [15:0] hh_out;
    wire signed [15:0] hl_out;
    wire signed [15:0] lh_out;

    // LL is 17-bit
    wire signed [16:0] ll_out;

    wire vertical_valid;


    // ========================================================
    // ARCHITECTURE OUTPUT MEMORY
    // ========================================================

    reg signed [15:0]
        H_arch [0:HORIZONTAL_SIZE-1];

    reg signed [15:0]
        L_arch [0:HORIZONTAL_SIZE-1];

    reg signed [15:0]
        HH_arch [0:OUTPUT_SIZE-1];

    reg signed [15:0]
        HL_arch [0:OUTPUT_SIZE-1];

    reg signed [15:0]
        LH_arch [0:OUTPUT_SIZE-1];

    reg signed [16:0]
        LL_arch [0:OUTPUT_SIZE-1];


    // ========================================================
    // COUNTERS
    // ========================================================

    integer h_count;
    integer v_count;

    integer i;


    // ========================================================
    // CLOCK
    // ========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // ========================================================
    // DUT
    // ========================================================

    DWTarc #(
        .IMAGE_ROWS(IMAGE_ROWS),
        .IMAGE_COLS(IMAGE_COLS),
        .HALF_ROWS(HALF_ROWS),
        .HALF_COLS(HALF_COLS),
        .TOTAL_PIXELS(TOTAL_PIXELS)
    ) dut (

        .clk(clk),
        .rst(rst),

        .busy(busy),
        .done(done),

        .h_out(h_out),
        .l_out(l_out),
        .horizontal_valid(horizontal_valid),

        .hh_out(hh_out),
        .hl_out(hl_out),
        .lh_out(lh_out),
        .ll_out(ll_out),
        .vertical_valid(vertical_valid)

    );


    // ========================================================
    // MAIN TEST
    // ========================================================

    initial begin

        // ----------------------------------------------------
        // Initialize
        // ----------------------------------------------------

        rst = 1'b1;

        h_count = 0;
        v_count = 0;


        // ----------------------------------------------------
        // Hold reset
        // ----------------------------------------------------

        #20;

        rst = 1'b0;


        // ----------------------------------------------------
        // Wait until DWT architecture completes
        // ----------------------------------------------------

        wait(done == 1'b1);

        #10;


        // ====================================================
        // DISPLAY ARCHITECTURE INFORMATION
        // ====================================================

        $display("");
        $display("============================================");
        $display("DWT ARCHITECTURE SIMULATION");
        $display("============================================");

        $display("");
        $display("IMAGE SIZE   = %0d x %0d",
                 IMAGE_ROWS, IMAGE_COLS);

        $display("H/L SIZE     = %0d x %0d",
                 IMAGE_ROWS, HALF_COLS);

        $display("FINAL SIZE   = %0d x %0d",
                 HALF_ROWS, HALF_COLS);

        $display("H/L COEFFS    = %0d",
                 HORIZONTAL_SIZE);

        $display("FINAL COEFFS  = %0d",
                 OUTPUT_SIZE);

        $display("");


        // ====================================================
        // FIRST 10 H
        // ====================================================

        $display("FIRST 10 ARCHITECTURE H VALUES");

        for (i = 0; i < 10; i = i + 1)
            $display("%0d : %0d",
                     i,
                     H_arch[i]);


        // ====================================================
        // FIRST 10 L
        // ====================================================

        $display("");

        $display("FIRST 10 ARCHITECTURE L VALUES");

        for (i = 0; i < 10; i = i + 1)
            $display("%0d : %0d",
                     i,
                     L_arch[i]);


        // ====================================================
        // FIRST 10 HH
        // ====================================================

        $display("");

        $display("FIRST 10 ARCHITECTURE HH VALUES");

        for (i = 0; i < 10; i = i + 1)
            $display("%0d : %0d",
                     i,
                     HH_arch[i]);


        // ====================================================
        // FIRST 10 HL
        // ====================================================

        $display("");

        $display("FIRST 10 ARCHITECTURE HL VALUES");

        for (i = 0; i < 10; i = i + 1)
            $display("%0d : %0d",
                     i,
                     HL_arch[i]);


        // ====================================================
        // FIRST 10 LH
        // ====================================================

        $display("");

        $display("FIRST 10 ARCHITECTURE LH VALUES");

        for (i = 0; i < 10; i = i + 1)
            $display("%0d : %0d",
                     i,
                     LH_arch[i]);


        // ====================================================
        // FIRST 10 LL
        // ====================================================

        $display("");

        $display("FIRST 10 ARCHITECTURE LL VALUES");

        for (i = 0; i < 10; i = i + 1)
            $display("%0d : %0d",
                     i,
                     LL_arch[i]);


        // ====================================================
        // WRITE ARCHITECTURE OUTPUTS
        // ====================================================

        $display("");
        $display("============================================");
        $display("WRITING ARCHITECTURE OUTPUT FILES");
        $display("============================================");

        $writememh("H_arch.hex", H_arch);
        $display("H_arch.hex  : %0d coefficients",
                 HORIZONTAL_SIZE);

        $writememh("L_arch.hex", L_arch);
        $display("L_arch.hex  : %0d coefficients",
                 HORIZONTAL_SIZE);

        $writememh("HH_arch.hex", HH_arch);
        $display("HH_arch.hex : %0d coefficients",
                 OUTPUT_SIZE);

        $writememh("HL_arch.hex", HL_arch);
        $display("HL_arch.hex : %0d coefficients",
                 OUTPUT_SIZE);

        $writememh("LH_arch.hex", LH_arch);
        $display("LH_arch.hex : %0d coefficients",
                 OUTPUT_SIZE);

        $writememh("LL_arch.hex", LL_arch);
        $display("LL_arch.hex : %0d coefficients",
                 OUTPUT_SIZE);


        // ====================================================
        // COMPLETION STATUS
        // ====================================================

        $display("");
        $display("============================================");
        $display("DWT ARCHITECTURE OUTPUT GENERATION COMPLETE");
        $display("============================================");

        $display("");
        $display("Generated files:");
        $display("  H_arch.hex");
        $display("  L_arch.hex");
        $display("  HH_arch.hex");
        $display("  HL_arch.hex");
        $display("  LH_arch.hex");
        $display("  LL_arch.hex");

        $display("");
        $display("Final verification will be performed in MATLAB.");
        $display("");


        // ====================================================
        // FINISH
        // ====================================================

        $finish;

    end


    // ========================================================
    // CAPTURE H/L
    // ========================================================

    always @(posedge clk) begin

        #1;

        if (horizontal_valid) begin

            H_arch[h_count] = h_out;
            L_arch[h_count] = l_out;

            h_count = h_count + 1;

        end

    end


    // ========================================================
    // CAPTURE FINAL OUTPUTS
    // ========================================================

    always @(posedge clk) begin

        #1;

        if (vertical_valid) begin

            HH_arch[v_count] = hh_out;
            HL_arch[v_count] = hl_out;
            LH_arch[v_count] = lh_out;
            LL_arch[v_count] = ll_out;

            v_count = v_count + 1;

        end

    end

endmodule