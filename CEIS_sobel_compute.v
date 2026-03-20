module CEIS_sobel_compute #(
    parameter PIX_W = 12
)(
    input  wire clk,
    input  wire rst,
    input  wire win_valid,

    input  wire [PIX_W-1:0] p1,p2,p3,
    input  wire [PIX_W-1:0] p4,p5,p6,
    input  wire [PIX_W-1:0] p7,p8,p9,

    output reg  sobel_valid,
    output reg  [PIX_W-1:0] edge_pixel,
    output reg  [PIX_W+3:0] grad_mag
);

    reg signed [PIX_W+2:0] gx_s1, gy_s1;
    reg valid_s1;

    always @(posedge clk) begin
        if (rst) begin
            gx_s1    <= 0;
            gy_s1    <= 0;
            valid_s1 <= 0;
        end else begin
            valid_s1 <= win_valid;
            gx_s1 <= (p3 + p9) + (p6 << 1) - ((p1 + p7) + (p4 << 1));
            gy_s1 <= (p1 + p3) + (p2 << 1) - ((p7 + p9) + (p8 << 1));
        end
    end

    reg [PIX_W+2:0] abs_gx_s2, abs_gy_s2;
    reg valid_s2;

    always @(posedge clk) begin
        if (rst) begin
            abs_gx_s2 <= 0;
            abs_gy_s2 <= 0;
            valid_s2  <= 0;
        end else begin
            valid_s2  <= valid_s1;
            abs_gx_s2 <= gx_s1[PIX_W+2] ? (~gx_s1 + 1'b1) : gx_s1;
            abs_gy_s2 <= gy_s1[PIX_W+2] ? (~gy_s1 + 1'b1) : gy_s1;
        end
    end

    wire [PIX_W+3:0] mag_comb = abs_gx_s2 + abs_gy_s2;

    always @(posedge clk) begin
        if (rst) begin
            sobel_valid <= 0;
            grad_mag    <= 0;
            edge_pixel  <= 0;
        end else begin
            sobel_valid <= valid_s2;
            grad_mag    <= mag_comb;

            if (valid_s2) begin
                if (mag_comb > 8'd255)
                    edge_pixel <= 8'hFF;
                else
                    edge_pixel <= mag_comb[7:0];
            end else begin
                edge_pixel <= 0;
            end
        end
    end

endmodule