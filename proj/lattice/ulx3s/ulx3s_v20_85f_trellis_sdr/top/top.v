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

  wire clk_25MHz, clk_250MHz, clk_locked;
  clock ecp5_pll
  (
    .clkin_25MHz(clk_25mhz), // lowercase clk_25mhz is input clock, used only here
    .clk_25MHz(clk_25MHz), // uppericase clk_25MHz is output clock, used in rest of design
    .clk_250MHz(clk_250MHz),
    .locked(clk_locked)
  );

  wire [2:0] vga_r, vga_g, vga_b;
  wire vga_hsync, vga_vsync, vga_blank;

  // prjtrellis creates different picture than diamond:
  caleidoscope generator
  (
    .CLK_25MHz(clk_25MHz),
    .RED(vga_r),
    .GREEN(vga_g), // works for prjtrells if used alone
    .BLUE(vga_b),
    .VS(vga_vsync),
    .HS(vga_hsync),
    .BLANK(vga_blank),
    .SWITCH(3'b100)
  );
  
  // debug: 
  // if commented out some of above .RED(vga_r) .GREEN(vga_g) .BLUE(vga_b)
  // optionally uncomment corresponding channels below:
  // this fills full screen with the same color
  //assign vga_r = 1;
  //assign vga_g = 3;
  //assign vga_b = 2;

  wire red_sdr, green_sdr, blue_sdr, clock_sdr;
  vga2hdmi_sdr
  #(
    .C_phase_adjust(0),
    .C_depth(3) // 3-bit input
  )
  vga_to_sdr_hdmi
  (
    .clk_pixel(clk_25MHz),
    .clk(clk_250MHz),
    // VGA input (clk_pixel synchronous)
    .red_p(vga_r),
    .green_p(vga_g),
    .blue_p(vga_b),
    .vsync(vga_vsync),
    .hsync(vga_hsync),
    .blank(vga_blank),
    // generic output for generic SDR buffers
    .clock_sdr(clock_sdr),
    .red_sdr(red_sdr),
    .green_sdr(green_sdr),
    .blue_sdr(blue_sdr)
  );

  // This module converts VGA to DVI using clock domain crossing
  // it works for diamond and trellis
  OBUFDS OBUFDS_clock(.I(clock_sdr), .O(gpdi_dp[3]), .OB(gpdi_dn[3]));
  OBUFDS OBUFDS_red  (.I(red_sdr),   .O(gpdi_dp[2]), .OB(gpdi_dn[2]));
  OBUFDS OBUFDS_green(.I(green_sdr), .O(gpdi_dp[1]), .OB(gpdi_dn[1]));
  OBUFDS OBUFDS_blue (.I(blue_sdr),  .O(gpdi_dp[0]), .OB(gpdi_dn[0]));

  // This module generates DVI signal from the same clock domain
  // color test picture should appear.
  // this works for diamond and prjtrellis
  /*
  wire red_sdr_test, green_sdr_test, blue_sdr_test, clock_sdr_test;
  DVI_test testpicture
  (
    .pixclk(clk_25MHz),
    .shiftclk(clk_250MHz),
    .red_sdr(red_sdr_test),
    .green_sdr(green_sdr_test),
    .blue_sdr(blue_sdr_test),
    .clock_sdr(clock_sdr_test),
    .vsync(vga_vsync),
    .hsync(vga_hsync),
    .blank(vga_blank)
  );
  OBUFDS OBUFDS_clock(.I(clock_sdr_test), .O(gpdi_dp[3]), .OB(gpdi_dn[3]));
  OBUFDS OBUFDS_red  (.I(red_sdr_test),   .O(gpdi_dp[2]), .OB(gpdi_dn[2]));
  OBUFDS OBUFDS_green(.I(green_sdr_test), .O(gpdi_dp[1]), .OB(gpdi_dn[1]));
  OBUFDS OBUFDS_blue (.I(blue_sdr_test),  .O(gpdi_dp[0]), .OB(gpdi_dn[0]));
  */

  // some LED visible indicators
  assign led[0] = btn;
  assign led[2] = vga_vsync;
  assign led[3] = vga_hsync;
  assign led[4] = vga_blank;
  assign led[7] = clk_locked;

endmodule
