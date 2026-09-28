`timescale 1ns / 1ps

module IDWT_Top #(
    parameter IMAGE_ROWS = 300,
    parameter IMAGE_COLS = 332
)(
    input  wire clk,
    input  wire reset,
    input  wire start,

    output wire done
);

    localparam HALF_ROWS = IMAGE_ROWS / 2;
    localparam HALF_COLS = IMAGE_COLS / 2;


    // ============================================================
    // CONTROL SIGNALS
    // ============================================================

    wire [3:0]  op;
    wire [15:0] index;
    wire [15:0] n;


    // ============================================================
    // CONTROL UNIT
    // ============================================================

    IDWT_ControlUnit #(
        .IMAGE_ROWS(IMAGE_ROWS),
        .IMAGE_COLS(IMAGE_COLS),
        .HALF_ROWS(HALF_ROWS),
        .HALF_COLS(HALF_COLS)
    ) CU (

        .clk(clk),
        .reset(reset),
        .start(start),

        .op(op),
        .index(index),
        .n(n),

        .done(done)

    );


    // ============================================================
    // DATAPATH
    // ============================================================

    IDWT_Datapath #(
        .IMAGE_ROWS(IMAGE_ROWS),
        .IMAGE_COLS(IMAGE_COLS),
        .HALF_ROWS(HALF_ROWS),
        .HALF_COLS(HALF_COLS)
    ) DP (

        .clk(clk),
        .reset(reset),

        .op(op),
        .index(index),
        .n(n)

    );

endmodule