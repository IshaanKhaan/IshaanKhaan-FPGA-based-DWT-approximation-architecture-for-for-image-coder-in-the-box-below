`timescale 1ns / 1ps

// ============================================================
// DWTarc - TOP LEVEL 2-D 5/3 DWT ARCHITECTURE
//
// Image:
//   300 x 332
//
// Horizontal:
//   H = 300 x 166
//   L = 300 x 166
//
// Vertical:
//   HH = 150 x 166
//   HL = 150 x 166
//   LH = 150 x 166
//   LL = 150 x 166
//
// Top-level design module.
// ============================================================

module DWTarc #(
    parameter IMAGE_ROWS = 300,
    parameter IMAGE_COLS = 332,

    parameter HALF_ROWS = IMAGE_ROWS / 2,
    parameter HALF_COLS = IMAGE_COLS / 2,

    parameter TOTAL_PIXELS = IMAGE_ROWS * IMAGE_COLS
)(
    input wire clk,
    input wire rst,

    // ========================================================
    // STATUS
    // ========================================================

    output wire busy,
    output wire done,

    // ========================================================
    // HORIZONTAL OUTPUTS
    // ========================================================

    output wire signed [15:0] h_out,
    output wire signed [15:0] l_out,

    output wire horizontal_valid,

    // ========================================================
    // FINAL OUTPUTS
    // ========================================================

    output wire signed [15:0] hh_out,
    output wire signed [15:0] hl_out,
    output wire signed [15:0] lh_out,

    // LL requires 17 bits
    output wire signed [16:0] ll_out,

    output wire vertical_valid
);


    // ========================================================
    // INPUT IMAGE MEMORY
    // ========================================================

    reg [7:0] input_image [0:TOTAL_PIXELS-1];


    // ========================================================
    // CONTROL UNIT SIGNALS
    // ========================================================

    wire        load_en;
    wire [16:0] load_addr;

    wire        horizontal_en;
    wire [8:0]  horizontal_row;
    wire [7:0]  horizontal_col;

    wire        vertical_en;
    wire [7:0]  vertical_row;
    wire [7:0]  vertical_col;


    // ========================================================
    // DATA SENT TO DATAPATH
    // ========================================================

    wire [7:0] load_data;

    assign load_data = input_image[load_addr];


    // ========================================================
    // LOAD INPUT IMAGE
    // ========================================================

    initial begin

        $readmemh("input_image.hex", input_image);

    end


    // ========================================================
    // CONTROL UNIT
    // ========================================================

    controlunit #(
        .IMAGE_ROWS(IMAGE_ROWS),
        .IMAGE_COLS(IMAGE_COLS),
        .HALF_ROWS(HALF_ROWS),
        .HALF_COLS(HALF_COLS)
    ) u_controlunit (

        .clk(clk),
        .rst(rst),

        // Image loading
        .load_en(load_en),
        .load_addr(load_addr),

        // Horizontal DWT
        .horizontal_en(horizontal_en),
        .horizontal_row(horizontal_row),
        .horizontal_col(horizontal_col),

        // Vertical DWT
        .vertical_en(vertical_en),
        .vertical_row(vertical_row),
        .vertical_col(vertical_col),

        // Status
        .busy(busy),
        .done(done)

    );


    // ========================================================
    // DATAPATH
    // ========================================================

    Datapath #(
        .IMAGE_ROWS(IMAGE_ROWS),
        .IMAGE_COLS(IMAGE_COLS),
        .HALF_ROWS(HALF_ROWS),
        .HALF_COLS(HALF_COLS)
    ) u_datapath (

        .clk(clk),
        .rst(rst),

        // Image loading
        .load_en(load_en),
        .load_addr(load_addr),
        .load_data(load_data),

        // Horizontal control
        .horizontal_en(horizontal_en),
        .horizontal_row(horizontal_row),
        .horizontal_col(horizontal_col),

        // Vertical control
        .vertical_en(vertical_en),
        .vertical_row(vertical_row),
        .vertical_col(vertical_col),

        // Horizontal outputs
        .h_out(h_out),
        .l_out(l_out),
        .horizontal_valid(horizontal_valid),

        // Final outputs
        .hh_out(hh_out),
        .hl_out(hl_out),
        .lh_out(lh_out),
        .ll_out(ll_out),

        .vertical_valid(vertical_valid)

    );

endmodule