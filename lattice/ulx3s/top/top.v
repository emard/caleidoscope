/* top.v - Top level module
** EMARD
*/

module top
(
  input wire clk_25mhz, // onboard 25MHz clock
  
  // BTN
  input wire [6:0] btn;
  
  // keep board running
  output wire wifi_gpio0;

  // HDMI
  output wire [3:0] gpdi_dp, gpdi_dn
);

  wire clk_25MHz_out, clk_100MHz, clk_125MHz, clkn_125MHz;

  wire [7:0] vga_r, vga_g, vga_b;
  wire vga_hsync, vga_vsync, vga_blank;
  // after edge enhancement effect filter
  wire [7:0] fx_vga_r, fx_vga_g, fx_vga_b;
  wire fx_vga_hsync, fx_vga_vsync, fx_vga_blank;
  // last stage of generic output -> input to vendor specific DDR buffers
  wire [1:0] red_ddr, green_ddr, blue_ddr, clock_ddr;
  
  assign wifi_gpio0 = btn[0]; // keeps board running

  clk_25_100_125_25 clock_generator
  (
    .CLKI(clk_25mhz), // from onboard hardware
    .CLKOP(clk_125MHz), // HDMI DDR positive (phase 0)
    .CLKOS(clkn_125MHz), // HDMI DDR negative, (phase 180)
    .CLKOS2(clk_25MHz_out), // not used
    .CLKOS3(clk_100MHz) // not used
  );
  
  caleidoscope generator
  (
    .CLK_25MHz(clk_25MHz_out),
    .RED(vga_r[7:5]),
    .GREEN(vga_g[7:5]),
    .BLUE(vga_b[7:6]),
    .VS(vga_vsync),
    .HS(vga_hsync),
    .BLANK(vga_blank),
    .SWITCH(3'b100)
  );

  edge_enhance filter
  (
    .clk(clk_25MHz_out),
    .enable_feature(1'b1),
    
    .in_blank(vga_blank),
    .in_hsync(vga_hsync),
    .in_vsync(vga_vsync),
    .in_red(vga_r),
    .in_green(vga_g),
    .in_blue(vga_b),

    .out_blank(fx_vga_blank),
    .out_hsync(fx_vga_hsync),
    .out_vsync(fx_vga_vsync),
    .out_red(fx_vga_r),
    .out_green(fx_vga_g),
    .out_blue(fx_vga_b)    
  );

  vga2hdmi_ddr
  #(
    .C_depth(8) // 8-bit input
  )
  vga_to_ddr_hdmi
  (
    .clk_pixel(clk_25MHz_out),
    .clk(clk_125MHz),
    // VGA input (clk_pixel synchronous)
    .red_p(fx_vga_r),
    .green_p(fx_vga_g),
    .blue_p(fx_vga_b),
    .blank(fx_vga_blank),
    .hsync(fx_vga_hsync),
    .vsync(fx_vga_vsync),
    // generic output for vendor-specific DDR buffers
    .red_ddr(red_ddr),
    .green_ddr(green_ddr),
    .blue_ddr(blue_ddr),
    .clock_ddr(clock_ddr)
  );

  ddr_hdmi_out_ecp5 ulx3s_hdmi_out
  (
    .clk(clk_125MHz),
    // generic input to DDR buffers
    .red_ddr(red_ddr),
    .green_ddr(green_ddr),
    .blue_ddr(blue_ddr),
    .clock_ddr(clock_ddr),
    // HDMI output from DDR buffers
    .gpdi_dp(gpdi_dp),
    .gpdi_dn(gpdi_dn)
  );

endmodule
