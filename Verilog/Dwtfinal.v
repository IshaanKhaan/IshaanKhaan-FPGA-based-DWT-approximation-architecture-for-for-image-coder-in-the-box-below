timescale 1ns / 1ps

// ============================================================
// 2-D 5/3 DWT - BEHAVIORAL REFERENCE + H/L DIAGNOSTIC OUTPUT
//
// Input: input_image.hex
// Image: 300 x 332
// H/L:   300 x 166
// Final: 150 x 166
//
// Boundary conventions:
// HPF: x[-1] = x[1], x[N] = x[N-2]
// LPF: x[-1] = x[2], x[N] = x[N-2], x[N+1] = x[N-3]
// ============================================================

module hor_dwt;

    parameter IMAGE_ROWS = 300;
    parameter IMAGE_COLS = 332;
    parameter HALF_ROWS = IMAGE_ROWS / 2;
    parameter HALF_COLS = IMAGE_COLS / 2;
    parameter TOTAL_PIXELS = IMAGE_ROWS * IMAGE_COLS;
    parameter TOTAL_OUTPUTS = HALF_ROWS * HALF_COLS;

    reg [7:0] image_mem [0:TOTAL_PIXELS-1];

    reg signed [31:0] H  [0:IMAGE_ROWS*HALF_COLS-1];
    reg signed [31:0] L  [0:IMAGE_ROWS*HALF_COLS-1];

    reg signed [31:0] HH [0:TOTAL_OUTPUTS-1];
    reg signed [31:0] HL [0:TOTAL_OUTPUTS-1];
    reg signed [31:0] LH [0:TOTAL_OUTPUTS-1];
    reg signed [31:0] LL [0:TOTAL_OUTPUTS-1];

    integer row, col, n, base;
    integer xm1, x0, xp1;
    integer xm2, lp_x0, lp_xp1, lp_xp2, lp_xp3;

    initial begin
        $display("");
        $display("============================================");
        $display("2-D 5/3 DWT");
        $display("============================================");
        $display("IMAGE SIZE = %0d x %0d", IMAGE_ROWS, IMAGE_COLS);
        $display("TOTAL PIXELS = %0d", TOTAL_PIXELS);
        $display("H/L SIZE = %0d x %0d", IMAGE_ROWS, HALF_COLS);
        $display("FINAL SIZE = %0d x %0d", HALF_ROWS, HALF_COLS);

        $readmemh("input_image.hex", image_mem);

        $display("");
        $display("============================================");
        $display("FIRST 10 INPUT PIXELS");
        $display("============================================");
        for (n = 0; n < 10; n = n + 1)
            $display("%0d : %0d", n, image_mem[n]);

        // HORIZONTAL DWT
        for (row = 0; row < IMAGE_ROWS; row = row + 1) begin
            base = row * IMAGE_COLS;

            for (n = 0; n < HALF_COLS; n = n + 1) begin

                // HPF
                if (n == 0)
                    xm1 = image_mem[base + 1];
                else
                    xm1 = image_mem[base + 2*n - 1];

                x0 = image_mem[base + 2*n];

                if ((2*n + 1) >= IMAGE_COLS)
                    xp1 = image_mem[base + IMAGE_COLS - 2];
                else
                    xp1 = image_mem[base + 2*n + 1];

                H[row*HALF_COLS + n] =
                      -xm1 + (2*x0) - xp1;

                // LPF
                if (n == 0)
                    xm2 = image_mem[base + 2];
                else
                    xm2 = image_mem[base + 2*n - 1];

                lp_x0 = image_mem[base + 2*n];
                lp_xp1 = image_mem[base + 2*n + 1];

                if ((2*n + 2) >= IMAGE_COLS)
                    lp_xp2 = image_mem[base + IMAGE_COLS - 2];
                else
                    lp_xp2 = image_mem[base + 2*n + 2];

                if ((2*n + 3) >= IMAGE_COLS)
                    lp_xp3 = image_mem[base + IMAGE_COLS - 3];
                else
                    lp_xp3 = image_mem[base + 2*n + 3];

                L[row*HALF_COLS + n] =
                      -xm2
                    + (2*lp_x0)
                    + (6*lp_xp1)
                    + (2*lp_xp2)
                    - lp_xp3;
            end
        end

        $display("");
        $display("============================================");
        $display("HORIZONTAL 5/3 DWT");
        $display("============================================");
        $display("H SIZE = %0d x %0d", IMAGE_ROWS, HALF_COLS);
        $display("L SIZE = %0d x %0d", IMAGE_ROWS, HALF_COLS);

        $display("");
        $display("FIRST 10 HIGH-PASS VALUES");
        for (n = 0; n < 10; n = n + 1)
            $display("%0d : %0d", n, H[n]);

        $display("");
        $display("FIRST 10 LOW-PASS VALUES");
        for (n = 0; n < 10; n = n + 1)
            $display("%0d : %0d", n, L[n]);

        $writememh("H_vivado.hex", H);
        $writememh("L_vivado.hex", L);

        // VERTICAL DWT
        for (col = 0; col < HALF_COLS; col = col + 1) begin
            for (n = 0; n < HALF_ROWS; n = n + 1) begin

                // H -> HH : HPF
                if (n == 0)
                    xm1 = H[1*HALF_COLS + col];
                else
                    xm1 = H[(2*n - 1)*HALF_COLS + col];

                x0 = H[(2*n)*HALF_COLS + col];

                if ((2*n + 1) >= IMAGE_ROWS)
                    xp1 = H[(IMAGE_ROWS - 2)*HALF_COLS + col];
                else
                    xp1 = H[(2*n + 1)*HALF_COLS + col];

                HH[n*HALF_COLS + col] =
                      -xm1 + (2*x0) - xp1;

                // H -> HL : LPF
                if (n == 0)
                    xm2 = H[2*HALF_COLS + col];
                else
                    xm2 = H[(2*n - 1)*HALF_COLS + col];

                lp_x0 = H[(2*n)*HALF_COLS + col];
                lp_xp1 = H[(2*n + 1)*HALF_COLS + col];

                if ((2*n + 2) >= IMAGE_ROWS)
                    lp_xp2 = H[(IMAGE_ROWS - 2)*HALF_COLS + col];
                else
                    lp_xp2 = H[(2*n + 2)*HALF_COLS + col];

                if ((2*n + 3) >= IMAGE_ROWS)
                    lp_xp3 = H[(IMAGE_ROWS - 3)*HALF_COLS + col];
                else
                    lp_xp3 = H[(2*n + 3)*HALF_COLS + col];

                HL[n*HALF_COLS + col] =
                      -xm2
                    + (2*lp_x0)
                    + (6*lp_xp1)
                    + (2*lp_xp2)
                    - lp_xp3;

                // L -> LH : HPF
                if (n == 0)
                    xm1 = L[1*HALF_COLS + col];
                else
                    xm1 = L[(2*n - 1)*HALF_COLS + col];

                x0 = L[(2*n)*HALF_COLS + col];

                if ((2*n + 1) >= IMAGE_ROWS)
                    xp1 = L[(IMAGE_ROWS - 2)*HALF_COLS + col];
                else
                    xp1 = L[(2*n + 1)*HALF_COLS + col];

                LH[n*HALF_COLS + col] =
                      -xm1 + (2*x0) - xp1;

                // L -> LL : LPF
                if (n == 0)
                    xm2 = L[2*HALF_COLS + col];
                else
                    xm2 = L[(2*n - 1)*HALF_COLS + col];

                lp_x0 = L[(2*n)*HALF_COLS + col];
                lp_xp1 = L[(2*n + 1)*HALF_COLS + col];

                if ((2*n + 2) >= IMAGE_ROWS)
                    lp_xp2 = L[(IMAGE_ROWS - 2)*HALF_COLS + col];
                else
                    lp_xp2 = L[(2*n + 2)*HALF_COLS + col];

                if ((2*n + 3) >= IMAGE_ROWS)
                    lp_xp3 = L[(IMAGE_ROWS - 3)*HALF_COLS + col];
                else
                    lp_xp3 = L[(2*n + 3)*HALF_COLS + col];

                LL[n*HALF_COLS + col] =
                      -xm2
                    + (2*lp_x0)
                    + (6*lp_xp1)
                    + (2*lp_xp2)
                    - lp_xp3;
            end
        end

        $display("");
        $display("============================================");
        $display("FINAL 2-D DWT");
        $display("============================================");
        $display("HH SIZE = %0d x %0d", HALF_ROWS, HALF_COLS);
        $display("HL SIZE = %0d x %0d", HALF_ROWS, HALF_COLS);
        $display("LH SIZE = %0d x %0d", HALF_ROWS, HALF_COLS);
        $display("LL SIZE = %0d x %0d", HALF_ROWS, HALF_COLS);

        $display("");
        $display("FIRST 10 HH VALUES");
        for (n = 0; n < 10; n = n + 1)
            $display("%0d : %0d", n, HH[n]);

        $display("");
        $display("FIRST 10 HL VALUES");
        for (n = 0; n < 10; n = n + 1)
            $display("%0d : %0d", n, HL[n]);

        $display("");
        $display("FIRST 10 LH VALUES");
        for (n = 0; n < 10; n = n + 1)
            $display("%0d : %0d", n, LH[n]);

        $display("");
        $display("FIRST 10 LL VALUES");
        for (n = 0; n < 10; n = n + 1)
            $display("%0d : %0d", n, LL[n]);

        $writememh("HH_vivado.hex", HH);
        $writememh("HL_vivado.hex", HL);
        $writememh("LH_vivado.hex", LH);
        $writememh("LL_vivado.hex", LL);

        $display("");
        $display("============================================");
        $display("DWT COMPLETE");
        $display("============================================");
        $display("Output files:");
        $display("H_vivado.hex");
        $display("L_vivado.hex");
        $display("HH_vivado.hex");
        $display("HL_vivado.hex");
        $display("LH_vivado.hex");
        $display("LL_vivado.hex");

        $finish;
    end
endmodule