// 640x480 video display

// Emard:

// LICENSE=BSD

// some code taken from
// (c) fpga4fun.com & KNJN LLC 2013

////////////////////////////////////////////////////////////////////////
module vga2hdmi(
        input wire pixclk, /* 25 MHz */
        input wire clk_TMDS, /* 250 MHz (set to 0 for VGA-only) */
        input wire vga_hsync, vga_vsync, vga_blank,
        input wire [7:0] vga_r, vga_g, vga_b,
	output wire [2:0] tmds_out_rgb
);

// generate HDMI output, mixing with test picture if enabled
wire [9:0] TMDS_red, TMDS_green, TMDS_blue;

wire DrawArea = ~vga_blank;

TMDS_encoder_v encode_R
(
  .clk(pixclk),
  .VD(vga_r),
  .CD(2'b00),
  .VDE(DrawArea),
  .TMDS(TMDS_red)
);
TMDS_encoder_v encode_G
(
  .clk(pixclk),
  .VD(vga_g),
  .CD(2'b00),
  .VDE(DrawArea),
  .TMDS(TMDS_green)
);
TMDS_encoder_v encode_B
(
  .clk(pixclk),
  .VD(vga_b),
  .CD({vga_vsync, vga_hsync}),
  .VDE(DrawArea),
  .TMDS(TMDS_blue)
);

////////////////////////////////////////////////////////////////////////
reg [3:0] TMDS_mod10=0;  // modulus 10 counter
reg [9:0] TMDS_shift_red=0, TMDS_shift_green=0, TMDS_shift_blue=0;
reg TMDS_shift_load=0;
always @(posedge clk_TMDS) TMDS_shift_load <= (TMDS_mod10==4'd9);

always @(posedge clk_TMDS)
begin
	TMDS_shift_red   <= TMDS_shift_load ? TMDS_red   : TMDS_shift_red  [9:1];
	TMDS_shift_green <= TMDS_shift_load ? TMDS_green : TMDS_shift_green[9:1];
	TMDS_shift_blue  <= TMDS_shift_load ? TMDS_blue  : TMDS_shift_blue [9:1];
	TMDS_mod10 <= (TMDS_mod10==4'd9) ? 4'd0 : TMDS_mod10+4'd1;
end

// ******* HDMI OUTPUT ********
assign tmds_out_rgb = {TMDS_shift_red[0], TMDS_shift_green[0], TMDS_shift_blue[0]};
endmodule
