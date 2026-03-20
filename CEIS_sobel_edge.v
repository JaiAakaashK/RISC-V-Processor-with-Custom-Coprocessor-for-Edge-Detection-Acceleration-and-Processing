`timescale 1ns/1ps
`default_nettype none

module CEIS_sobel_edge #(
    parameter PIX_W   = 12,
    parameter IMG_W   = 640,
    parameter IMG_H   = 480,
    parameter ADDR_W  = 32
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               start,

    input  wire [ADDR_W-1:0]  base_in_addr,
    input  wire [ADDR_W-1:0]  base_out_addr,

    output wire [ADDR_W-1:0]  in_addr,
    input  wire [PIX_W-1:0]   in_pixel,

    output wire               out_valid,
    output wire [ADDR_W-1:0]  out_addr,
    output wire [PIX_W-1:0]   out_pixel
);


    wire in_valid;
    wire [$clog2(IMG_H)-1:0] in_row;
    wire [$clog2(IMG_W)-1:0] in_col;

    CEIS_sobel_input_addr_generator #(
        .IMG_W (IMG_W),
        .IMG_H (IMG_H),
        .ADDR_W(ADDR_W)
    ) u_in (
        .clk(clk),
        .rst(rst),
        .enable(start),
        .base_in_addr(base_in_addr),
        .pixel_valid(in_valid),
        .pixel_addr(in_addr),
        .row(in_row),
        .col(in_col)
    );

    reg [$clog2(IMG_H)-1:0] row_d1,row_d2,row_d3,row_d4,row_d5,row_d6,row_d7,row_d8;
    reg [$clog2(IMG_W)-1:0] col_d1,col_d2,col_d3,col_d4,col_d5,col_d6,col_d7,col_d8;

    always @(posedge clk) begin
        if (rst) begin
            row_d1<=0; row_d2<=0; row_d3<=0; row_d4<=0;
            row_d5<=0; row_d6<=0; row_d7<=0; row_d8<=0;

            col_d1<=0; col_d2<=0; col_d3<=0; col_d4<=0;
            col_d5<=0; col_d6<=0; col_d7<=0; col_d8<=0;
        end else begin
            row_d1<=in_row;
            row_d2<=row_d1;
            row_d3<=row_d2;
            row_d4<=row_d3;
            row_d5<=row_d4;
            row_d6<=row_d5;
            row_d7<=row_d6;
            row_d8<=row_d7;

            col_d1<=in_col;
            col_d2<=col_d1;
            col_d3<=col_d2;
            col_d4<=col_d3;
            col_d5<=col_d4;
            col_d6<=col_d5;
            col_d7<=col_d6;
            col_d8<=col_d7;
        end
    end


    wire [PIX_W-1:0] p1,p2,p3,p4,p5,p6,p7,p8,p9;

    CEIS_sobel_window_generator #(
        .PIX_W (PIX_W),
        .IMG_W (IMG_W)
    ) u_win (
        .clk(clk),
        .rst(rst),
        .pixel_valid(in_valid),
        .pixel_in(in_pixel),
        .p1(p1),.p2(p2),.p3(p3),
        .p4(p4),.p5(p5),.p6(p6),
        .p7(p7),.p8(p8),.p9(p9)
    );

    wire win_valid;
    assign win_valid =
        (row_d4 >= 2) &&
        (col_d4 >= 2) &&
        (row_d4 < IMG_H-1) &&
        (col_d4 < IMG_W-1);

    wire [PIX_W-1:0] pix_center_filtered;
    wire filter_valid;

    CEIS_sobel_gaussian_filter #(
        .PIX_W(PIX_W)
    ) g_sobel (
        .clk(clk),
        .rst(rst),
        .win_valid(win_valid),
        .p1(p1),.p2(p2),.p3(p3),
        .p4(p4),.p5(p5),.p6(p6),
        .p7(p7),.p8(p8),.p9(p9),
        .p_filtered(pix_center_filtered),
        .filter_valid(filter_valid)
    );
	 
    reg [PIX_W-1:0] p1_d,p2_d,p3_d,p4_d,p6_d,p7_d,p8_d,p9_d;

    always @(posedge clk) begin
        if(rst) begin
            p1_d<=0; p2_d<=0; p3_d<=0; p4_d<=0;
            p6_d<=0; p7_d<=0; p8_d<=0; p9_d<=0;
        end else begin
            p1_d<=p1; p2_d<=p2; p3_d<=p3; p4_d<=p4;
            p6_d<=p6; p7_d<=p7; p8_d<=p8; p9_d<=p9;
        end
    end

    wire sobel_valid_raw;

    CEIS_sobel_compute #(
        .PIX_W(PIX_W)
    ) u_sobel (
        .clk(clk),
        .rst(rst),
        .win_valid(filter_valid),
        .p1(p1_d),.p2(p2_d),.p3(p3_d),
        .p4(p4_d),.p5(pix_center_filtered),.p6(p6_d),
        .p7(p7_d),.p8(p8_d),.p9(p9_d),
        .sobel_valid(sobel_valid_raw),
        .edge_pixel(out_pixel),
        .grad_mag()
    );

    CEIS_sobel_output_addr_generator #(
        .IMG_W (IMG_W),
        .IMG_H (IMG_H),
        .ADDR_W(ADDR_W)
    ) u_out (
        .clk(clk),
        .rst(rst),
        .sobel_valid(sobel_valid_raw),   
        .base_out_addr(base_out_addr),
        .in_row(row_d8),                 
        .in_col(col_d8),
        .out_valid(out_valid),
        .out_addr(out_addr)
    );

endmodule

`default_nettype wire