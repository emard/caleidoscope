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

  wire clk_25MHz, clk_125MHz, clk_locked;
  clock ecp5_pll
  (
    .clkin_25MHz(clk_25mhz),
    .clk_25MHz(clk_25MHz),
    .clk_125MHz(clk_125MHz),
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

  wire [1:0] red_ddr, green_ddr, blue_ddr, clock_ddr;
  vga2hdmi_ddr
  #(
    // .C_phase_adjust(0),
    .C_depth(3) // 3-bit input
  )
  vga_to_ddr_hdmi
  (
    .clk_pixel(clk_25MHz),
    .clk(clk_125MHz),
    // VGA input (clk_pixel synchronous)
    .red_p(vga_r),
    .green_p(vga_g),
    .blue_p(vga_b),
    .vsync(vga_vsync),
    .hsync(vga_hsync),
    .blank(vga_blank),
    // generic output for generic DDR buffers
    .clock_ddr(clock_ddr),
    .red_ddr(red_ddr),
    .green_ddr(green_ddr),
    .blue_ddr(blue_ddr)
  );

  wire S_ddr_clock, S_ddr_red, S_ddr_green, S_ddr_blue;

  ODDRX1F ODDRX1F_clock(.D0(clock_ddr[0]), .D1(clock_ddr[1]), .Q(S_ddr_clock), .SCLK(clk_125MHz), .RST(0));
  ODDRX1F ODDRX1F_red(.D0(red_ddr[0]), .D1(red_ddr[1]), .Q(S_ddr_red), .SCLK(clk_125MHz), .RST(0));
  ODDRX1F ODDRX1F_green(.D0(green_ddr[0]), .D1(green_ddr[1]), .Q(S_ddr_green), .SCLK(clk_125MHz), .RST(0));
  ODDRX1F ODDRX1F_blue(.D0(blue_ddr[0]), .D1(blue_ddr[1]), .Q(S_ddr_blue), .SCLK(clk_125MHz), .RST(0));

/*
  assign gpdi_dp[3] = S_ddr_clock;
  assign gpdi_dp[2] = S_ddr_red;
  assign gpdi_dp[1] = S_ddr_green;
  assign gpdi_dp[0] = S_ddr_blue;
*/
  
  // fake differential: inverted inputs
  wire [1:0] S_clock_ddrn, red_ddrn, green_ddrn, blue_ddrn;
  assign S_clock_ddrn = ~clock_ddr;
  assign S_red_ddrn = ~red_ddr;
  assign S_green_ddrn = ~green_ddr;
  assign S_blue_ddrn = ~blue_ddr;

  wire S_ddr_clockn, S_ddr_redn, S_ddr_greenn, S_ddr_bluen;

  ODDRX1F ODDRX1F_clockn(.D0(S_clock_ddrn[0]), .D1(S_clock_ddrn[1]), .Q(S_ddr_clockn), .SCLK(clk_125MHz), .RST(0));
  ODDRX1F ODDRX1F_redn(.D0(S_red_ddrn[0]), .D1(S_red_ddrn[1]), .Q(S_ddr_redn), .SCLK(clk_125MHz), .RST(0));
  ODDRX1F ODDRX1F_greenn(.D0(S_green_ddrn[0]), .D1(S_green_ddrn[1]), .Q(S_ddr_greenn), .SCLK(clk_125MHz), .RST(0));
  ODDRX1F ODDRX1F_bluen(.D0(S_blue_ddrn[0]), .D1(S_blue_ddrn[1]), .Q(S_ddr_bluen), .SCLK(clk_125MHz), .RST(0));

/*
  assign gpdi_dn[3] = S_ddr_clockn;
  assign gpdi_dn[2] = S_ddr_redn;
  assign gpdi_dn[1] = S_ddr_greenn;
  assign gpdi_dn[0] = S_ddr_bluen;
*/

/*
  OBUFDS OBUFDS_clock(.I(S_ddr_clock), .O(gpdi_dp[3]), .OB(gpdi_dn[3]));
  OBUFDS OBUFDS_red  (.I(S_ddr_red),   .O(gpdi_dp[2]), .OB(gpdi_dn[2]));
  OBUFDS OBUFDS_green(.I(S_ddr_green), .O(gpdi_dp[1]), .OB(gpdi_dn[1]));
  OBUFDS OBUFDS_blue (.I(S_ddr_blue),  .O(gpdi_dp[0]), .OB(gpdi_dn[0]));
*/

/*
  OLVDS OLVDS_clock(.I(S_ddr_clock), .O(gpdi_dp[3]), .OB(gpdi_dn[3]));
  OLVDS OLVDS_red  (.I(S_ddr_red),   .O(gpdi_dp[2]), .OB(gpdi_dn[2]));
  OLVDS OLVDS_green(.I(S_ddr_green), .O(gpdi_dp[1]), .OB(gpdi_dn[1]));
  OLVDS OLVDS_blue (.I(S_ddr_blue),  .O(gpdi_dp[0]), .OB(gpdi_dn[0]));
*/
  // some LED visible indicators
  assign led[0] = btn;
  assign led[2] = vga_vsync;
  assign led[3] = vga_hsync;
  assign led[4] = vga_blank;
  assign led[7] = clk_locked;

endmodule
