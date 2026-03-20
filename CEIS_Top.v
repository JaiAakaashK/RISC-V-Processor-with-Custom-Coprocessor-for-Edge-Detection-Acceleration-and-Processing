`timescale 1ns/1ps
`default_nettype none

module CEIS_Top #(
    parameter IMG_W     = 640,
    parameter IMG_H     = 480,
    parameter PIX_W     = 12,
    parameter MEM_WORDS = 8192
)(
    input wire clk,
    input wire reset    
);

localparam IMG_PIXELS = IMG_W * IMG_H;   
localparam BUSY_CNT_W = 19;
localparam PIPE_LAT   = 32;


reg [31:0] cpu_mem [0:MEM_WORDS-1];

wire [31:0] mem_addr;
wire [31:0] mem_wdata;
wire  [3:0] mem_wmask;
wire [31:0] mem_rdata;
wire        mem_rstrb;
wire        mem_rbusy = 1'b0;
wire        mem_wbusy = 1'b0;
wire [12:0] cpu_widx  = mem_addr[14:2];
reg  [31:0] cpu_rdata_q;
assign mem_rdata = cpu_rdata_q;

always @(posedge clk) begin
    if (|mem_wmask) begin
        if (mem_wmask[0]) cpu_mem[cpu_widx][ 7: 0] <= mem_wdata[ 7: 0];
        if (mem_wmask[1]) cpu_mem[cpu_widx][15: 8] <= mem_wdata[15: 8];
        if (mem_wmask[2]) cpu_mem[cpu_widx][23:16] <= mem_wdata[23:16];
        if (mem_wmask[3]) cpu_mem[cpu_widx][31:24] <= mem_wdata[31:24];
    end
    if (mem_rstrb)
        cpu_rdata_q <= cpu_mem[cpu_widx];
end

reg [PIX_W-1:0] sobel_in_mem  [0:IMG_PIXELS-1];
reg [PIX_W-1:0] sobel_out_mem [0:IMG_PIXELS-1];


wire        sobel_enable;
wire [31:0] sobel_in_base_cpu;
wire [31:0] sobel_out_base_cpu;
wire        sobel_busy;
wire [31:0] sobel_in_base  = 32'h0;
wire [31:0] sobel_out_base = 32'h0;
reg [BUSY_CNT_W-1:0] busy_cnt;
reg                  sobel_running;
assign sobel_busy = sobel_running | sobel_enable;

always @(posedge clk) begin
    if (!reset) begin
        busy_cnt      <= {BUSY_CNT_W{1'b0}};
        sobel_running <= 1'b0;
    end else begin
        if (sobel_enable && !sobel_running) begin
            busy_cnt      <= {BUSY_CNT_W{1'b0}};
            sobel_running <= 1'b1;
        end else if (sobel_running) begin
            if (busy_cnt == (IMG_PIXELS + PIPE_LAT - 1))
                sobel_running <= 1'b0;
            else
                busy_cnt <= busy_cnt + 1'b1;
        end
    end
end
wire [31:0]      sobel_rd_addr;
wire [31:0]      sobel_wr_addr;
wire [PIX_W-1:0] sobel_out_pix;
wire             sobel_out_valid;
wire [PIX_W-1:0] sobel_in_pix = sobel_in_mem[sobel_rd_addr[18:0]];

always @(posedge clk)
    if (sobel_out_valid)
        sobel_out_mem[sobel_wr_addr[18:0]] <= sobel_out_pix;


CEIS_sobel_rvcore cpu (
    .clk            (clk),
    .reset          (reset),
    .mem_addr       (mem_addr),
    .mem_wdata      (mem_wdata),
    .mem_wmask      (mem_wmask),
    .mem_rdata      (mem_rdata),
    .mem_rstrb      (mem_rstrb),
    .mem_rbusy      (mem_rbusy),
    .mem_wbusy      (mem_wbusy),
    .sobel_busy     (sobel_busy),
    .sobel_enable   (sobel_enable),
    .sobel_in_addr  (sobel_in_base_cpu),
    .sobel_out_addr (sobel_out_base_cpu)
);

CEIS_sobel_edge #(
    .PIX_W  (PIX_W),
    .IMG_W  (IMG_W),
    .IMG_H  (IMG_H),
    .ADDR_W (32)
) u_sobel (
    .clk           (clk),
    .rst           (~reset),
    .start         (sobel_running),
    .base_in_addr  (sobel_in_base),
    .base_out_addr (sobel_out_base),
    .in_addr       (sobel_rd_addr),
    .in_pixel      (sobel_in_pix),
    .out_valid     (sobel_out_valid),
    .out_addr      (sobel_wr_addr),
    .out_pixel     (sobel_out_pix)
);

endmodule
`default_nettype wire