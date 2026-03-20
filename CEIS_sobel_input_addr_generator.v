module CEIS_sobel_input_addr_generator #(
    parameter IMG_W = 5,
    parameter IMG_H = 5,
    parameter ADDR_W = 8
)(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [ADDR_W-1:0] base_in_addr,   

    output reg pixel_valid,
    output reg [ADDR_W-1:0] pixel_addr,
    output reg [$clog2(IMG_H)-1:0] row,
    output reg [$clog2(IMG_W)-1:0] col
);

    reg done;
    wire [ADDR_W-1:0] offset;

    assign offset = row * IMG_W + col;

    always @(posedge clk) begin
        if (rst) begin
            row <= 0;
            col <= 0;
            pixel_addr <= 0;
            pixel_valid <= 0;
            done <= 0;
        end
        else if (enable && !done) begin
            pixel_valid <= 1'b1;
            pixel_addr <= base_in_addr + offset;

            if (col == IMG_W-1) begin
                col <= 0;
                if (row == IMG_H-1)
                    done <= 1'b1;
                else
                    row <= row + 1;
            end 
            else begin
                col <= col + 1;
            end
        end
        else begin
            pixel_valid <= 1'b0;
        end
    end

endmodule
