`timescale 1ns / 1ps

module IDWT_Datapath #(
    parameter IMAGE_ROWS = 300,
    parameter IMAGE_COLS = 332,

    parameter HALF_ROWS = IMAGE_ROWS / 2,
    parameter HALF_COLS = IMAGE_COLS / 2,

    parameter SUB_PIXELS = HALF_ROWS * HALF_COLS
)(
    input wire        clk,
    input wire        reset,

    input wire [3:0]  op,
    input wire [15:0] index,
    input wire [15:0] n
);

    // ============================================================
    // OPERATION CODES
    // ============================================================

    localparam V_LEFT  = 4'd1;
    localparam V_ODD   = 4'd2;
    localparam V_EVEN  = 4'd3;
    localparam V_RIGHT = 4'd4;

    localparam H_LEFT  = 4'd5;
    localparam H_ODD   = 4'd6;
    localparam H_EVEN  = 4'd7;
    localparam H_RIGHT = 4'd8;


    // ============================================================
    // DWT SUBBAND MEMORIES
    // ============================================================

    reg signed [15:0] HH [0:SUB_PIXELS-1];
    reg signed [15:0] HL [0:SUB_PIXELS-1];
    reg signed [15:0] LH [0:SUB_PIXELS-1];

    reg signed [16:0] LL [0:SUB_PIXELS-1];


    // ============================================================
    // VERTICAL IDWT OUTPUT MEMORIES
    //
    // HH + HL -> H
    // LH + LL -> L
    // ============================================================

    reg signed [31:0] Htmp [0:IMAGE_ROWS*HALF_COLS-1];
    reg signed [31:0] Ltmp [0:IMAGE_ROWS*HALF_COLS-1];


    // ============================================================
    // FINAL RECONSTRUCTED IMAGE
    // ============================================================

    reg signed [31:0] recon [0:IMAGE_ROWS*IMAGE_COLS-1];


    // ============================================================
    // TEMPORARY ARITHMETIC VARIABLES
    // ============================================================

    integer a;
    integer b;
    integer c;
    integer d;
    integer e;

    integer base;
    integer idx0;
    integer idx1;
    integer idx2;


    // ============================================================
    // LOAD DWT COEFFICIENT FILES
    // ============================================================

    initial begin

        $readmemh("HH_arch.hex", HH);
        $readmemh("HL_arch.hex", HL);
        $readmemh("LH_arch.hex", LH);
        $readmemh("LL_arch.hex", LL);

    end


    // ============================================================
    // COMBINATIONAL IDWT ARITHMETIC
    // ============================================================

    always @(*) begin

        a    = 0;
        b    = 0;
        c    = 0;
        d    = 0;
        e    = 0;

        base = 0;
        idx0 = 0;
        idx1 = 0;
        idx2 = 0;


        // ========================================================
        // VERTICAL LEFT BOUNDARY
        // ========================================================

        if (op == V_LEFT) begin

            idx0 = index;
            idx1 = HALF_COLS + index;
            idx2 = 2*HALF_COLS + index;

            // --------------------------------------------
            // H = IDWT(HH,HL)
            // --------------------------------------------

            // x[3]
            c = (HL[idx1]
               - HH[idx1]
               - HH[idx2]) / 8;

            // x[1]
            b = (2*HL[idx0]
               - 2*HH[idx0]
               - HH[idx1]
               + c) / 17;

            // x[0]
            a = b + HH[idx0] / 2;

            // x[2]
            d = (HH[idx1] + b + c) / 2;


            // --------------------------------------------
            // L = IDWT(LH,LL)
            // --------------------------------------------

            e = (LL[idx1]
               - LH[idx1]
               - LH[idx2]) / 8;

            // x[1]
            base = (2*LL[idx0]
                  - 2*LH[idx0]
                  - LH[idx1]
                  + e) / 17;

            // x[0]
            idx0 = base + LH[index] / 2;

            // x[2]
            idx1 = (LH[HALF_COLS + index]
                  + base
                  + e) / 2;

        end


        // ========================================================
        // VERTICAL ODD SAMPLE
        // ========================================================

        else if (op == V_ODD) begin

            idx0 = n*HALF_COLS + index;
            idx1 = (n+1)*HALF_COLS + index;

            // H odd sample
            a = (HL[idx0]
               - HH[idx0]
               - HH[idx1]) / 8;

            // L odd sample
            b = (LL[idx0]
               - LH[idx0]
               - LH[idx1]) / 8;

        end


        // ========================================================
        // VERTICAL EVEN SAMPLE
        // ========================================================

        else if (op == V_EVEN) begin

            idx0 = n*HALF_COLS + index;

            idx1 = (2*n-1)*HALF_COLS + index;
            idx2 = (2*n+1)*HALF_COLS + index;

            // H even sample
            a = (HH[idx0]
               + Htmp[idx1]
               + Htmp[idx2]) / 2;

            // L even sample
            b = (LH[idx0]
               + Ltmp[idx1]
               + Ltmp[idx2]) / 2;

        end


        // ========================================================
        // VERTICAL RIGHT BOUNDARY
        // ========================================================

        else if (op == V_RIGHT) begin

            idx0 = (HALF_ROWS-2)*HALF_COLS + index;
            idx1 = (HALF_ROWS-1)*HALF_COLS + index;

            // H[N-1]
            a = (HL[idx1]
               - 2*HH[idx1]) / 8;

            // H[N-2]
            b = (HH[idx1]
               + Htmp[(IMAGE_ROWS-3)*HALF_COLS + index]
               + a) / 2;


            // L[N-1]
            c = (LL[idx1]
               - 2*LH[idx1]) / 8;

            // L[N-2]
            d = (LH[idx1]
               + Ltmp[(IMAGE_ROWS-3)*HALF_COLS + index]
               + c) / 2;

        end


        // ========================================================
        // HORIZONTAL LEFT BOUNDARY
        // ========================================================

        else if (op == H_LEFT) begin

            base = index * HALF_COLS;

            // x[3]
            c = (Ltmp[base+1]
               - Htmp[base+1]
               - Htmp[base+2]) / 8;

            // x[1]
            b = (2*Ltmp[base]
               - 2*Htmp[base]
               - Htmp[base+1]
               + c) / 17;

            // x[0]
            a = b + Htmp[base] / 2;

            // x[2]
            d = (Htmp[base+1] + b + c) / 2;

        end


        // ========================================================
        // HORIZONTAL ODD SAMPLE
        // ========================================================

        else if (op == H_ODD) begin

            idx0 = index*HALF_COLS + n;
            idx1 = idx0 + 1;

            a = (Ltmp[idx0]
               - Htmp[idx0]
               - Htmp[idx1]) / 8;

        end


        // ========================================================
        // HORIZONTAL EVEN SAMPLE
        // ========================================================

        else if (op == H_EVEN) begin

            idx0 = index*HALF_COLS + n;

            a = (Htmp[idx0]
               + recon[index*IMAGE_COLS + 2*n-1]
               + recon[index*IMAGE_COLS + 2*n+1]) / 2;

        end


        // ========================================================
        // HORIZONTAL RIGHT BOUNDARY
        // ========================================================

        else if (op == H_RIGHT) begin

            base = index * HALF_COLS;

            idx0 = base + HALF_COLS - 1;

            // x[N-1]
            a = (Ltmp[idx0]
               - 2*Htmp[idx0]) / 8;

            // x[N-2]
            b = (Htmp[idx0]
               + recon[index*IMAGE_COLS + IMAGE_COLS-3]
               + a) / 2;

        end

    end


    // ============================================================
    // SEQUENTIAL STORAGE
    // ============================================================

    always @(posedge clk) begin

        if (reset) begin

            // Memories are initialized using $readmemh.
            // No reset clearing is required here.

        end

        else begin

            case (op)

                // =================================================
                // VERTICAL LEFT
                // =================================================

                V_LEFT: begin

                    Htmp[index]
                        <= a;

                    Htmp[HALF_COLS + index]
                        <= b;

                    Htmp[2*HALF_COLS + index]
                        <= d;

                    Htmp[3*HALF_COLS + index]
                        <= c;


                    Ltmp[index]
                        <= idx0;

                    Ltmp[HALF_COLS + index]
                        <= base;

                    Ltmp[2*HALF_COLS + index]
                        <= idx1;

                    Ltmp[3*HALF_COLS + index]
                        <= e;

                end


                // =================================================
                // VERTICAL ODD
                // =================================================

                V_ODD: begin

                    Htmp[(2*n+1)*HALF_COLS + index]
                        <= a;

                    Ltmp[(2*n+1)*HALF_COLS + index]
                        <= b;

                end


                // =================================================
                // VERTICAL EVEN
                // =================================================

                V_EVEN: begin

                    Htmp[(2*n)*HALF_COLS + index]
                        <= a;

                    Ltmp[(2*n)*HALF_COLS + index]
                        <= b;

                end


                // =================================================
                // VERTICAL RIGHT
                // =================================================

                V_RIGHT: begin

                    Htmp[(IMAGE_ROWS-2)*HALF_COLS + index]
                        <= b;

                    Htmp[(IMAGE_ROWS-1)*HALF_COLS + index]
                        <= a;


                    Ltmp[(IMAGE_ROWS-2)*HALF_COLS + index]
                        <= d;

                    Ltmp[(IMAGE_ROWS-1)*HALF_COLS + index]
                        <= c;

                end


                // =================================================
                // HORIZONTAL LEFT
                // =================================================

                H_LEFT: begin

                    recon[index*IMAGE_COLS]
                        <= a;

                    recon[index*IMAGE_COLS + 1]
                        <= b;

                    recon[index*IMAGE_COLS + 2]
                        <= d;

                    recon[index*IMAGE_COLS + 3]
                        <= c;

                end


                // =================================================
                // HORIZONTAL ODD
                // =================================================

                H_ODD: begin

                    recon[index*IMAGE_COLS + 2*n + 1]
                        <= a;

                end


                // =================================================
                // HORIZONTAL EVEN
                // =================================================

                H_EVEN: begin

                    recon[index*IMAGE_COLS + 2*n]
                        <= a;

                end


                // =================================================
                // HORIZONTAL RIGHT
                // =================================================

                H_RIGHT: begin

                    recon[index*IMAGE_COLS + IMAGE_COLS-2]
                        <= b;

                    recon[index*IMAGE_COLS + IMAGE_COLS-1]
                        <= a;

                end

            endcase

        end

    end

endmodule