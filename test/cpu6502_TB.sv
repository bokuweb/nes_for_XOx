/**********************************************************************
* $Id$
*//**
* @file
* @brief
* @version  1.0
* @date
* @author
*
** Copyright(C) 2013, All rights reserved.
*
***********************************************************************/

`timescale 1ps / 1ps

module cpu6502_tb;
    `include "defines.vh"
    `include "cpu6502.vh"

    //Internal signals declarations:
    logic clk           = 0;
    logic reset         = 0;
    logic [7:0]din      = 0;
    logic irq           = 0;
    logic nmi           = 0;
    logic rdy           = 0;
    logic we;
    logic [15:0]adr;
    logic [7:0]dout;

    /* sample program */
    bit [0:127][7:0] PROM =
        {
            8'h78, 8'ha2, 8'hff, 8'h9a, 8'ha9, 8'h00, 8'h8d, 8'h00, 8'h20, 8'h8d, 8'h01, 8'h20, 8'ha9, 8'h3f, 8'h8d, 8'h06,
            8'h20, 8'ha9, 8'h00, 8'h8d, 8'h06, 8'h20, 8'ha2, 8'h00, 8'ha0, 8'h10, 8'hbd, 8'h51, 8'h80, 8'h8d, 8'h07, 8'h20,
            8'he8, 8'h88, 8'hd0, 8'hf6, 8'ha9, 8'h21, 8'h8d, 8'h06, 8'h20, 8'ha9, 8'hc9, 8'h8d, 8'h06, 8'h20, 8'ha2, 8'h00,
            8'ha0, 8'h0d, 8'hbd, 8'h61, 8'h80, 8'h8d, 8'h07, 8'h20, 8'he8, 8'h88, 8'hd0, 8'hf6, 8'ha9, 8'h00, 8'h8d, 8'h05,
            8'h20, 8'h8d, 8'h05, 8'h20, 8'ha9, 8'h08, 8'h8d, 8'h00, 8'h20, 8'ha9, 8'h1e, 8'h8d, 8'h01, 8'h20, 8'h4c, 8'h4e,
            8'h80, 8'h0f, 8'h00, 8'h10, 8'h20, 8'h0f, 8'h06, 8'h16, 8'h26, 8'h0f, 8'h08, 8'h18, 8'h28, 8'h0f, 8'h0a, 8'h1a,
            8'h2a, 8'h48, 8'h45, 8'h4c, 8'h4c, 8'h4f, 8'h2c, 8'h20, 8'h57, 8'h4f, 8'h52, 8'h4c, 8'h44, 8'h21, 8'h00, 8'h00,
            8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00
        };

    parameter STEP = 10;

    // Unit Under Test port map
    cpu6502 UUT (
        .*
    );

    initial begin
        forever begin
            #(STEP * 0.5) clk = !clk;
        end
    end

    initial begin
        #STEP reset = 1'b1;
        #STEP reset = 1'b0;
    end

    initial begin
        forever begin
            @(negedge clk) begin
                if(adr >= 16'h8000) begin
                    din = PROM[adr[6:0]];
                end
            end
        end
    end
endmodule
