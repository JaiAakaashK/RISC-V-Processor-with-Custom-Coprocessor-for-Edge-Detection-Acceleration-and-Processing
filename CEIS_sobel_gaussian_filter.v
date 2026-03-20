module CEIS_sobel_gaussian_filter #(
	parameter PIX_W =12
)(
	input wire clk,rst,win_valid,
   input wire [PIX_W-1:0] p1,p2,p3,
   input wire [PIX_W-1:0] p4,p5,p6,
   input wire [PIX_W-1:0] p7,p8,p9,
	output reg [PIX_W-1:0] p_filtered,
	output reg filter_valid);
	
	
	reg[PIX_W+3:0] sum_r1,sum_r2,sum_r3,sum;
	reg valid_1,valid_2;
	
	
	always @(posedge clk)begin
		if(rst)begin
			p_filtered<=0;
			filter_valid<=0;
		end
		
		else if (win_valid)begin
			p_filtered<=((p1+(p2<<1)+p3+(p4<<1)+(p5<<2)+(p6<<1)+p7+(p8<<1)+p9)>>4);
			filter_valid<=1'b1;
		end
		else begin
			filter_valid<=1'b0;  
		end
	end
	
endmodule