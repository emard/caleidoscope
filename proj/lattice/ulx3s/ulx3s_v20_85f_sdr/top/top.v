/* top.v - Top level module
** EMARD
*/

module top
(
  input clk_25mhz,
  output [7:0] led,
  output [3:0] gpdi_dp, gpdi_dn,
  input btn,
  output wifi_gpio0
);

  // Tie GPIO0, keep board from rebooting
  assign wifi_gpio0 = 1'b1;

  wire clk_25MHz_out, clk_250MHz, clk_locked;
  clk_25_125_250_25_83 ecp5_pll
  (
    .CLKI(clk_25mhz),
    .CLKOS2(clk_25MHz_out),
    .CLKOS(clk_250MHz)
  );

  wire [2:0] vga_r, vga_g, vga_b;
  wire vga_hsync, vga_vsync, vga_blank;
  caleidoscope generator
  (
    .CLK_25MHz(clk_25MHz_out),
    .RED(vga_r),
    .GREEN(vga_g),
    .BLUE(vga_b),
    .VS(vga_vsync),
    .HS(vga_hsync),
    .BLANK(vga_blank),
    .SWITCH(3'b100)
  );
  
  // debug
  //assign vga_r = 1;
  //assign vga_g = 3;
  //assign vga_b = 2;

  // last stage of generic output -> input to vendor specific DDR buffers
  wire red_sdr, green_sdr, blue_sdr, clock_sdr;
  vga2hdmi_sdr
  #(
    .C_depth(3) // 8-bit input
  )
  vga_to_sdr_hdmi
  (
    .clk_pixel(clk_25MHz_out),
    .clk(clk_250MHz),
    // VGA input (clk_pixel synchronous)
    .red_p(vga_r),
    .green_p(vga_g),
    .blue_p(vga_b),
    .blank(vga_blank),
    .hsync(vga_hsync),
    .vsync(vga_vsync),
    // generic output for generic SDR buffers
    .red_sdr(red_sdr),
    .green_sdr(green_sdr),
    .blue_sdr(blue_sdr),
    .clock_sdr(clock_sdr)
  );

  OBUFDS OBUFDS_clock(.I(clock_sdr), .O(gpdi_dp[3]), .OB(gpdi_dn[3]));
  OBUFDS OBUFDS_red  (.I(red_sdr),   .O(gpdi_dp[2]), .OB(gpdi_dn[2]));
  OBUFDS OBUFDS_green(.I(green_sdr), .O(gpdi_dp[1]), .OB(gpdi_dn[1]));
  OBUFDS OBUFDS_blue (.I(blue_sdr),  .O(gpdi_dp[0]), .OB(gpdi_dn[0]));
  
  assign led[0] = btn;
  assign led[2] = vga_vsync;
  assign led[3] = vga_hsync;
  assign led[7] = clk_locked;

endmodule
