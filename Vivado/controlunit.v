\`timescale 1ns / 1ps

// ============================================================
// CONTROL UNIT - 2-D 5/3 DWT
//
// Controls the Datapath:
//
//   1. Load input image
//   2. Horizontal DWT
//   3. Vertical DWT
//   4. Done
//
// Image:
//   300 x 332
//
// H/L:
//   300 x 166
//
// Final subbands:
//   150 x 166
//
// ============================================================

module controlunit #(
    parameter IMAGE_ROWS = 300,
    parameter IMAGE_COLS = 332,

    parameter HALF_ROWS = IMAGE_ROWS / 2,
    parameter HALF_COLS = IMAGE_COLS / 2
)(
    input wire clk,
    input wire rst,

    // ========================================================
    // CONTROL OUTPUTS TO DATAPATH
    // ========================================================

    output reg        load_en,
    output reg [16:0] load_addr,

    output reg        horizontal_en,
    output reg [8:0]  horizontal_row,
    output reg [7:0]  horizontal_col,

    output reg        vertical_en,
    output reg [7:0]  vertical_row,
    output reg [7:0]  vertical_col,

    // ========================================================
    // STATUS
    // ========================================================

    output reg busy,
    output reg done
);

    // ========================================================
    // STATE MACHINE
    // ========================================================

    localparam STATE_RESET      = 3'd0;
    localparam STATE_LOAD       = 3'd1;
    localparam STATE_HORIZONTAL = 3'd2;
    localparam STATE_VERTICAL   = 3'd3;
    localparam STATE_DONE       = 3'd4;

    reg [2:0] state;

    // ========================================================
    // COUNTERS
    // ========================================================

    reg [16:0] load_count;

    reg [8:0] horizontal_row_count;
    reg [7:0] horizontal_col_count;

    reg [7:0] vertical_row_count;
    reg [7:0] vertical_col_count;

    // ========================================================
    // STATE MACHINE
    // ========================================================

    always @(posedge clk) begin

        if (rst) begin

            state <= STATE_RESET;

            load_count <= 17'd0;

            horizontal_row_count <= 9'd0;
            horizontal_col_count <= 8'd0;

            vertical_row_count <= 8'd0;
            vertical_col_count <= 8'd0;

        end

        else begin

            case (state)

                // =================================================
                // RESET STATE
                // =================================================

                STATE_RESET: begin

                    load_count <= 17'd0;

                    horizontal_row_count <= 9'd0;
                    horizontal_col_count <= 8'd0;

                    vertical_row_count <= 8'd0;
                    vertical_col_count <= 8'd0;

                    state <= STATE_LOAD;

                end

                // =================================================
                // LOAD IMAGE
                //
                // Addresses:
                //
                // 0
                // 1
                // 2
                // ...
                // 99599
                //
                // One pixel per clock.
                // =================================================

                STATE_LOAD: begin

                    if (load_count ==
                        (IMAGE_ROWS*IMAGE_COLS - 1)) begin

                        load_count <= 17'd0;

                        horizontal_row_count <= 9'd0;
                        horizontal_col_count <= 8'd0;

                        state <= STATE_HORIZONTAL;

                    end

                    else begin

                        load_count <= load_count + 1'b1;

                    end

                end

                // =================================================
                // HORIZONTAL DWT
                //
                // Process:
                //
                // row = 0 ... 299
                // col = 0 ... 165
                //
                // One H/L pair per clock.
                // =================================================

                STATE_HORIZONTAL: begin

                    if ((horizontal_row_count ==
                         IMAGE_ROWS - 1) &&
                        (horizontal_col_count ==
                         HALF_COLS - 1)) begin

                        horizontal_row_count <= 9'd0;
                        horizontal_col_count <= 8'd0;

                        vertical_row_count <= 8'd0;
                        vertical_col_count <= 8'd0;

                        state <= STATE_VERTICAL;

                    end

                    else if (horizontal_col_count ==
                             HALF_COLS - 1) begin

                        horizontal_col_count <= 8'd0;

                        horizontal_row_count <=
                            horizontal_row_count + 1'b1;

                    end

                    else begin

                        horizontal_col_count <=
                            horizontal_col_count + 1'b1;

                    end

                end

                // =================================================
                // VERTICAL DWT
                //
                // Process:
                //
                // row = 0 ... 149
                // col = 0 ... 165
                //
                // One HH/HL/LH/LL group per clock.
                // =================================================

                STATE_VERTICAL: begin

                    if ((vertical_row_count ==
                         HALF_ROWS - 1) &&
                        (vertical_col_count ==
                         HALF_COLS - 1)) begin

                        state <= STATE_DONE;

                    end

                    else if (vertical_col_count ==
                             HALF_COLS - 1) begin

                        vertical_col_count <= 8'd0;

                        vertical_row_count <=
                            vertical_row_count + 1'b1;

                    end

                    else begin

                        vertical_col_count <=
                            vertical_col_count + 1'b1;

                    end

                end

                // =================================================
                // DONE
                // =================================================

                STATE_DONE: begin

                    state <= STATE_DONE;

                end

                default: begin

                    state <= STATE_RESET;

                end

            endcase

        end

    end

    // ========================================================
    // CONTROL OUTPUT DECODER
    // ========================================================

    always @(*) begin

        // ----------------------------------------------------
        // DEFAULTS
        // ----------------------------------------------------

        load_en = 1'b0;
        load_addr = 17'd0;

        horizontal_en = 1'b0;
        horizontal_row = 9'd0;
        horizontal_col = 8'd0;

        vertical_en = 1'b0;
        vertical_row = 8'd0;
        vertical_col = 8'd0;

        busy = 1'b0;
        done = 1'b0;

        // ====================================================
        // LOAD
        // ====================================================

        if (state == STATE_LOAD) begin

            load_en = 1'b1;

            load_addr = load_count;

            busy = 1'b1;

        end

        // ====================================================
        // HORIZONTAL
        // ====================================================

        else if (state == STATE_HORIZONTAL) begin

            horizontal_en = 1'b1;

            horizontal_row =
                horizontal_row_count;

            horizontal_col =
                horizontal_col_count;

            busy = 1'b1;

        end

        // ====================================================
        // VERTICAL
        // ====================================================

        else if (state == STATE_VERTICAL) begin

            vertical_en = 1'b1;

            vertical_row =
                vertical_row_count;

            vertical_col =
                vertical_col_count;

            busy = 1'b1;

        end

        // ====================================================
        // DONE
        // ====================================================

        else if (state == STATE_DONE) begin

            done = 1'b1;

        end

    end

endmodule