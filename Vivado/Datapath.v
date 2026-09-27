`timescale 1ns / 1ps

// ============================================================
// DATAPATH - 2-D 5/3 DWT
//
// Input:
//   300 x 332 grayscale image
//
// Horizontal stage:
//   Image -> H + L
//
// Vertical stage:
//   H -> HH + HL
//   L -> LH + LL
//
// This module is the DATAPATH.
// Control/sequencing is handled by controlunit.v.
//
// ============================================================

module Datapath #(
    parameter IMAGE_ROWS = 300,
    parameter IMAGE_COLS = 332,

    parameter HALF_ROWS = IMAGE_ROWS / 2,
    parameter HALF_COLS = IMAGE_COLS / 2
)(
    input wire clk,
    input wire rst,

    // ========================================================
    // IMAGE MEMORY LOAD
    // ========================================================

    input wire        load_en,
    input wire [16:0] load_addr,
    input wire [7:0]  load_data,

    // ========================================================
    // HORIZONTAL DWT CONTROL
    // ========================================================

    input wire        horizontal_en,
    input wire [8:0]  horizontal_row,
    input wire [7:0]  horizontal_col,

    // ========================================================
    // VERTICAL DWT CONTROL
    // ========================================================

    input wire        vertical_en,
    input wire [7:0]  vertical_row,
    input wire [7:0]  vertical_col,

    // ========================================================
    // OUTPUTS
    // ========================================================

    output reg signed [15:0] hh_out,
    output reg signed [15:0] hl_out,
    output reg signed [15:0] lh_out,

    // LL needs 17 bits
    output reg signed [16:0] ll_out,

    output reg signed [15:0] h_out,
    output reg signed [15:0] l_out,

    output reg horizontal_valid,
    output reg vertical_valid
);


    // ========================================================
    // MEMORIES
    // ========================================================

    // Original image
    reg [7:0] image_mem
        [0:IMAGE_ROWS*IMAGE_COLS-1];

    // Horizontal high-pass
    reg signed [15:0] H
        [0:IMAGE_ROWS*HALF_COLS-1];

    // Horizontal low-pass
    reg signed [15:0] L
        [0:IMAGE_ROWS*HALF_COLS-1];


    // ========================================================
    // HORIZONTAL TEMPORARY VALUES
    // ========================================================

    reg signed [15:0] hp_xm1;
    reg signed [15:0] hp_x0;
    reg signed [15:0] hp_xp1;

    reg signed [15:0] lp_xm1;
    reg signed [15:0] lp_x0;
    reg signed [15:0] lp_xp1;
    reg signed [15:0] lp_xp2;
    reg signed [15:0] lp_xp3;

    reg signed [15:0] horizontal_h;
    reg signed [15:0] horizontal_l;


    // ========================================================
    // VERTICAL TEMPORARY VALUES
    // ========================================================

    reg signed [15:0] h_xm1;
    reg signed [15:0] h_x0;
    reg signed [15:0] h_xp1;
    reg signed [15:0] h_xp2;
    reg signed [15:0] h_xp3;

    reg signed [15:0] l_xm1;
    reg signed [15:0] l_x0;
    reg signed [15:0] l_xp1;
    reg signed [15:0] l_xp2;
    reg signed [15:0] l_xp3;


    // ========================================================
    // VERTICAL RESULTS
    // ========================================================

    reg signed [15:0] vertical_hh;
    reg signed [15:0] vertical_hl;
    reg signed [15:0] vertical_lh;

    // LL requires 17 bits
    reg signed [16:0] vertical_ll;


    // ========================================================
    // ADDRESSES
    // ========================================================

    integer image_base;
    integer h_base;


    // ========================================================
    // HORIZONTAL COMBINATIONAL DATAPATH
    // ========================================================

    always @(*) begin

        hp_xm1 = 16'sd0;
        hp_x0  = 16'sd0;
        hp_xp1 = 16'sd0;

        lp_xm1 = 16'sd0;
        lp_x0  = 16'sd0;
        lp_xp1 = 16'sd0;
        lp_xp2 = 16'sd0;
        lp_xp3 = 16'sd0;

        horizontal_h = 16'sd0;
        horizontal_l = 16'sd0;

        image_base =
            horizontal_row * IMAGE_COLS;


        // ====================================================
        // HIGH-PASS
        //
        // H[n] =
        // -x[2n-1] + 2*x[2n] - x[2n+1]
        // ====================================================

        if (horizontal_col == 0)
            hp_xm1 =
                {8'd0, image_mem[image_base + 1]};
        else
            hp_xm1 =
                {8'd0,
                 image_mem[
                    image_base +
                    2*horizontal_col - 1
                 ]};

        hp_x0 =
            {8'd0,
             image_mem[
                image_base +
                2*horizontal_col
             ]};

        if ((2*horizontal_col + 1) >= IMAGE_COLS)
            hp_xp1 =
                {8'd0,
                 image_mem[
                    image_base +
                    IMAGE_COLS - 2
                 ]};
        else
            hp_xp1 =
                {8'd0,
                 image_mem[
                    image_base +
                    2*horizontal_col + 1
                 ]};

        horizontal_h =
            -hp_xm1
            + (hp_x0 <<< 1)
            - hp_xp1;


        // ====================================================
        // LOW-PASS
        //
        // L[n] =
        // -x[2n-1]
        // +2*x[2n]
        // +6*x[2n+1]
        // +2*x[2n+2]
        // -x[2n+3]
        // ====================================================

        if (horizontal_col == 0)
            lp_xm1 =
                {8'd0, image_mem[image_base + 2]};
        else
            lp_xm1 =
                {8'd0,
                 image_mem[
                    image_base +
                    2*horizontal_col - 1
                 ]};

        lp_x0 =
            {8'd0,
             image_mem[
                image_base +
                2*horizontal_col
             ]};

        lp_xp1 =
            {8'd0,
             image_mem[
                image_base +
                2*horizontal_col + 1
             ]};

        if ((2*horizontal_col + 2) >= IMAGE_COLS)
            lp_xp2 =
                {8'd0,
                 image_mem[
                    image_base +
                    IMAGE_COLS - 2
                 ]};
        else
            lp_xp2 =
                {8'd0,
                 image_mem[
                    image_base +
                    2*horizontal_col + 2
                 ]};

        if ((2*horizontal_col + 3) >= IMAGE_COLS)
            lp_xp3 =
                {8'd0,
                 image_mem[
                    image_base +
                    IMAGE_COLS - 3
                 ]};
        else
            lp_xp3 =
                {8'd0,
                 image_mem[
                    image_base +
                    2*horizontal_col + 3
                 ]};

        horizontal_l =
            -lp_xm1
            + (lp_x0 <<< 1)
            + (lp_xp1 * 16'sd6)
            + (lp_xp2 <<< 1)
            - lp_xp3;

    end


    // ========================================================
    // VERTICAL COMBINATIONAL DATAPATH
    // ========================================================

    always @(*) begin

        h_xm1 = 16'sd0;
        h_x0  = 16'sd0;
        h_xp1 = 16'sd0;
        h_xp2 = 16'sd0;
        h_xp3 = 16'sd0;

        l_xm1 = 16'sd0;
        l_x0  = 16'sd0;
        l_xp1 = 16'sd0;
        l_xp2 = 16'sd0;
        l_xp3 = 16'sd0;

        vertical_hh = 16'sd0;
        vertical_hl = 16'sd0;
        vertical_lh = 16'sd0;
        vertical_ll = 17'sd0;

        h_base = vertical_col;


        // ====================================================
        // H -> HH
        // ====================================================

        if (vertical_row == 0)
            h_xm1 =
                H[
                    HALF_COLS +
                    h_base
                ];
        else
            h_xm1 =
                H[
                    (2*vertical_row - 1)
                    * HALF_COLS
                    + h_base
                ];

        h_x0 =
            H[
                (2*vertical_row)
                * HALF_COLS
                + h_base
            ];

        if ((2*vertical_row + 1) >= IMAGE_ROWS)
            h_xp1 =
                H[
                    (IMAGE_ROWS - 2)
                    * HALF_COLS
                    + h_base
                ];
        else
            h_xp1 =
                H[
                    (2*vertical_row + 1)
                    * HALF_COLS
                    + h_base
                ];

        vertical_hh =
            -h_xm1
            + (h_x0 <<< 1)
            - h_xp1;


        // ====================================================
        // H -> HL
        // ====================================================

        if (vertical_row == 0)
            h_xm1 =
                H[
                    2 * HALF_COLS
                    + h_base
                ];
        else
            h_xm1 =
                H[
                    (2*vertical_row - 1)
                    * HALF_COLS
                    + h_base
                ];

        h_x0 =
            H[
                (2*vertical_row)
                * HALF_COLS
                + h_base
            ];

        h_xp1 =
            H[
                (2*vertical_row + 1)
                * HALF_COLS
                + h_base
            ];

        if ((2*vertical_row + 2) >= IMAGE_ROWS)
            h_xp2 =
                H[
                    (IMAGE_ROWS - 2)
                    * HALF_COLS
                    + h_base
                ];
        else
            h_xp2 =
                H[
                    (2*vertical_row + 2)
                    * HALF_COLS
                    + h_base
                ];

        if ((2*vertical_row + 3) >= IMAGE_ROWS)
            h_xp3 =
                H[
                    (IMAGE_ROWS - 3)
                    * HALF_COLS
                    + h_base
                ];
        else
            h_xp3 =
                H[
                    (2*vertical_row + 3)
                    * HALF_COLS
                    + h_base
                ];

        vertical_hl =
            -h_xm1
            + (h_x0 <<< 1)
            + (h_xp1 * 16'sd6)
            + (h_xp2 <<< 1)
            - h_xp3;


        // ====================================================
        // L -> LH
        // ====================================================

        if (vertical_row == 0)
            l_xm1 =
                L[
                    HALF_COLS +
                    h_base
                ];
        else
            l_xm1 =
                L[
                    (2*vertical_row - 1)
                    * HALF_COLS
                    + h_base
                ];

        l_x0 =
            L[
                (2*vertical_row)
                * HALF_COLS
                + h_base
            ];

        if ((2*vertical_row + 1) >= IMAGE_ROWS)
            l_xp1 =
                L[
                    (IMAGE_ROWS - 2)
                    * HALF_COLS
                    + h_base
                ];
        else
            l_xp1 =
                L[
                    (2*vertical_row + 1)
                    * HALF_COLS
                    + h_base
                ];

        vertical_lh =
            -l_xm1
            + (l_x0 <<< 1)
            - l_xp1;


        // ====================================================
        // L -> LL
        // ====================================================

        if (vertical_row == 0)
            l_xm1 =
                L[
                    2 * HALF_COLS
                    + h_base
                ];
        else
            l_xm1 =
                L[
                    (2*vertical_row - 1)
                    * HALF_COLS
                    + h_base
                ];

        l_x0 =
            L[
                (2*vertical_row)
                * HALF_COLS
                + h_base
            ];

        l_xp1 =
            L[
                (2*vertical_row + 1)
                * HALF_COLS
                + h_base
            ];

        if ((2*vertical_row + 2) >= IMAGE_ROWS)
            l_xp2 =
                L[
                    (IMAGE_ROWS - 2)
                    * HALF_COLS
                    + h_base
                ];
        else
            l_xp2 =
                L[
                    (2*vertical_row + 2)
                    * HALF_COLS
                    + h_base
                ];

        if ((2*vertical_row + 3) >= IMAGE_ROWS)
            l_xp3 =
                L[
                    (IMAGE_ROWS - 3)
                    * HALF_COLS
                    + h_base
                ];
        else
            l_xp3 =
                L[
                    (2*vertical_row + 3)
                    * HALF_COLS
                    + h_base
                ];

        vertical_ll =
            -l_xm1
            + (l_x0 <<< 1)
            + (l_xp1 * 17'sd6)
            + (l_xp2 <<< 1)
            - l_xp3;

    end


    // ========================================================
    // SEQUENTIAL DATAPATH
    // ========================================================

    always @(posedge clk) begin

        if (rst) begin

            horizontal_valid <= 1'b0;
            vertical_valid   <= 1'b0;

            h_out  <= 16'sd0;
            l_out  <= 16'sd0;

            hh_out <= 16'sd0;
            hl_out <= 16'sd0;
            lh_out <= 16'sd0;
            ll_out <= 17'sd0;

        end

        else begin

            horizontal_valid <= 1'b0;
            vertical_valid   <= 1'b0;


            // ==================================================
            // LOAD IMAGE
            // ==================================================

            if (load_en) begin

                image_mem[load_addr] <= load_data;

            end


            // ==================================================
            // HORIZONTAL DWT
            // ==================================================

            if (horizontal_en) begin

                H[
                    horizontal_row * HALF_COLS
                    + horizontal_col
                ] <= horizontal_h;

                L[
                    horizontal_row * HALF_COLS
                    + horizontal_col
                ] <= horizontal_l;

                h_out <= horizontal_h;
                l_out <= horizontal_l;

                horizontal_valid <= 1'b1;

            end


            // ==================================================
            // VERTICAL DWT
            // ==================================================

            if (vertical_en) begin

                hh_out <= vertical_hh;
                hl_out <= vertical_hl;
                lh_out <= vertical_lh;
                ll_out <= vertical_ll;

                vertical_valid <= 1'b1;

            end

        end

    end

endmodule