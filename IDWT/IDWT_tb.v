`timescale 1ns / 1ps

module IDWT_tb;

    parameter IMAGE_ROWS = 300;
    parameter IMAGE_COLS = 332;

    localparam TOTAL_PIXELS =
                    IMAGE_ROWS * IMAGE_COLS;


    // ============================================================
    // CLOCK / CONTROL
    // ============================================================

    reg clk;
    reg reset;
    reg start;

    wire done;


    // ============================================================
    // ORIGINAL IMAGE
    // ============================================================

    reg [7:0] input_ref [0:TOTAL_PIXELS-1];


    // ============================================================
    // COUNTERS
    // ============================================================

    integer i;
    integer errors;
    integer max_error;
    integer diff;


    // ============================================================
    // DUT
    // ============================================================

    IDWT_Top #(
        .IMAGE_ROWS(IMAGE_ROWS),
        .IMAGE_COLS(IMAGE_COLS)
    ) DUT (

        .clk(clk),
        .reset(reset),
        .start(start),

        .done(done)

    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;
    end

    always #5 clk = ~clk;


    // ============================================================
    // TEST
    // ============================================================

    initial begin

        // Load original image
        $readmemh("input_image.hex", input_ref);


        // Reset
        reset = 1'b1;
        start = 1'b0;

        repeat(3)
            @(posedge clk);

        reset = 1'b0;


        // Start IDWT
        @(posedge clk);
        start = 1'b1;

        @(posedge clk);
        start = 1'b0;


        // Wait until IDWT finishes
        wait(done);


        #1;


        // ========================================================
        // COMPARE
        // ========================================================

        errors   = 0;
        max_error = 0;


        for (i = 0; i < TOTAL_PIXELS; i = i + 1) begin

            diff = DUT.DP.recon[i] - input_ref[i];

            if (diff < 0)
                diff = -diff;


            if (diff != 0)
                errors = errors + 1;


            if (diff > max_error)
                max_error = diff;

        end


        // ========================================================
        // SAVE RECONSTRUCTED IMAGE
        // ========================================================

        $writememh(
            "reconstructed_image.hex",
            DUT.DP.recon
        );


        // ========================================================
        // RESULTS
        // ========================================================

        $display("");
        $display("==============================================");
        $display("             IDWT VERIFICATION");
        $display("==============================================");

        $display(
            "Image size              = %0d x %0d",
            IMAGE_ROWS,
            IMAGE_COLS
        );

        $display(
            "Total pixels            = %0d",
            TOTAL_PIXELS
        );

        $display(
            "Different pixels        = %0d",
            errors
        );

        $display(
            "Maximum absolute error  = %0d",
            max_error
        );


        if (errors == 0) begin

            $display("----------------------------------------------");
            $display("RESULT = 100%% EXACT MATCH");
            $display("----------------------------------------------");

        end

        else begin

            $display("----------------------------------------------");
            $display("RESULT = MISMATCH");
            $display("----------------------------------------------");

        end


        $display("==============================================");
        $display("");


        $finish;

    end

endmodule