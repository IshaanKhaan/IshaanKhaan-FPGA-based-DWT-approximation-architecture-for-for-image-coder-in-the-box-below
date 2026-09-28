`timescale 1ns / 1ps

module IDWT_ControlUnit #(
    parameter IMAGE_ROWS = 300,
    parameter IMAGE_COLS = 332,
    parameter HALF_ROWS  = IMAGE_ROWS / 2,
    parameter HALF_COLS  = IMAGE_COLS / 2
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        start,

    output reg  [3:0]  op,
    output reg  [15:0] index,
    output reg  [15:0] n,
    output reg         done
);

    // ============================================================
    // STATES
    // ============================================================

    localparam S_IDLE  = 4'd0;

    // Vertical IDWT
    localparam S_V_LEFT  = 4'd1;
    localparam S_V_ODD   = 4'd2;
    localparam S_V_EVEN  = 4'd3;
    localparam S_V_RIGHT = 4'd4;

    // Horizontal IDWT
    localparam S_H_LEFT  = 4'd5;
    localparam S_H_ODD   = 4'd6;
    localparam S_H_EVEN  = 4'd7;
    localparam S_H_RIGHT = 4'd8;

    localparam S_DONE    = 4'd9;

    reg [3:0] state;


    // ============================================================
    // STATE MACHINE
    // ============================================================

    always @(posedge clk) begin

        if (reset) begin

            state <= S_IDLE;
            index <= 16'd0;
            n     <= 16'd0;
            done  <= 1'b0;

        end
        else begin

            done <= 1'b0;

            case (state)

                // ------------------------------------------------
                // IDLE
                // ------------------------------------------------
                S_IDLE: begin

                    if (start) begin
                        index <= 16'd0;
                        n     <= 16'd0;
                        state <= S_V_LEFT;
                    end

                end


                // =================================================
                // VERTICAL IDWT
                // =================================================

                S_V_LEFT: begin

                    n     <= 16'd1;
                    state <= S_V_ODD;

                end


                S_V_ODD: begin

                    state <= S_V_EVEN;

                end


                S_V_EVEN: begin

                    if (n == HALF_ROWS-2) begin
                        state <= S_V_RIGHT;
                    end
                    else begin
                        n     <= n + 1'b1;
                        state <= S_V_ODD;
                    end

                end


                S_V_RIGHT: begin

                    if (index == HALF_COLS-1) begin

                        // Vertical IDWT finished
                        index <= 16'd0;
                        n     <= 16'd0;
                        state <= S_H_LEFT;

                    end
                    else begin

                        index <= index + 1'b1;
                        n     <= 16'd0;
                        state <= S_V_LEFT;

                    end

                end


                // =================================================
                // HORIZONTAL IDWT
                // =================================================

                S_H_LEFT: begin

                    n     <= 16'd1;
                    state <= S_H_ODD;

                end


                S_H_ODD: begin

                    state <= S_H_EVEN;

                end


                S_H_EVEN: begin

                    if (n == HALF_COLS-2) begin
                        state <= S_H_RIGHT;
                    end
                    else begin
                        n     <= n + 1'b1;
                        state <= S_H_ODD;

                    end

                end


                S_H_RIGHT: begin

                    if (index == IMAGE_ROWS-1) begin
                        state <= S_DONE;
                    end
                    else begin

                        index <= index + 1'b1;
                        n     <= 16'd0;
                        state <= S_H_LEFT;

                    end

                end


                // =================================================
                // DONE
                // =================================================

                S_DONE: begin

                    done  <= 1'b1;
                    state <= S_DONE;

                end


                default: begin
                    state <= S_IDLE;
                end

            endcase

        end

    end


    // ============================================================
    // OPERATION DECODER
    // ============================================================

    always @(*) begin

        case (state)

            S_V_LEFT:  op = 4'd1;
            S_V_ODD:   op = 4'd2;
            S_V_EVEN:  op = 4'd3;
            S_V_RIGHT: op = 4'd4;

            S_H_LEFT:  op = 4'd5;
            S_H_ODD:   op = 4'd6;
            S_H_EVEN:  op = 4'd7;
            S_H_RIGHT: op = 4'd8;

            default:   op = 4'd0;

        endcase

    end

endmodule