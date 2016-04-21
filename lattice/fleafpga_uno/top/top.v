/* top.v - Top level module
** EMARD
*/

module top
(
  input wire sys_clock, // onboard 25MHz clock
  inout wire Shield_reset,

  // SRAM
  output wire [18:0] SRAM_Addr, // SRAM address bus
  inout wire [7:0] SRAM_Data, // data bus to/from SRAM
  output wire SRAM_n_cs, SRAM_n_oe, SRAM_n_we,

  // UART0 (USB slave serial)
  output wire slave_tx_o,
  input wire slave_rx_i,

  // UART1 (Optional WiFi interface)
  output wire wifi_rx_i,
  input wire wifi_tx_o,

  // HDMI
  output wire LVDS_Red, LVDS_Green, LVDS_Blue, LVDS_ck,

  // PS2 interface
  inout wire PS2_clk1, PS2_data1,

  inout wire User_LED1,
  output wire User_LED2,
  input wire User_n_PB1,

  inout wire [15:0] GPIO_wordport, GPIO_pullup,

  inout wire [5:0] ADC_Comp_in, ADC_Error_out,

  // SPI1 to Flash ROM
  output wire spi1_mosi, spi1_clk, spi1_cs,
  input wire spi1_miso
);

  wire clk_25MHz, clk_50MHz, clk_125MHz, clkn_125MHz;

  wire [7:0] vga_r, vga_g, vga_b;
  wire vga_hsync, vga_vsync, vga_blank;
  // after edge enhancement effect filter
  wire [7:0] fx_vga_r, fx_vga_g, fx_vga_b;
  wire fx_vga_hsync, fx_vga_vsync, fx_vga_blank;
  // last stage of generic output -> input to vendor specific DDR buffers
  wire [1:0] red_ddr, green_ddr, blue_ddr, clock_ddr;

  clkgen clock_generator
  (
    .CLKI(sys_clock), // from onboard hardware
    .CLKOP(clk_125MHz), // HDMI DDR positive (phase 0)
    .CLKOS(clkn_125MHz), // HDMI DDR negative, (phase 180)
    .CLKOS2(clk_25MHz),
    .CLKOS3(clk_50MHz) // not used
  );
  
  caleidoscope generator
  (
    .CLK_25MHz(clk_25MHz),
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
    .clk(clk_25MHz),
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
    .clk_pixel(clk_25MHz),
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

  ddr_hdmi_out_xo2 flea_hdmi_out
  (
    .clk(clk_125MHz),
    .clk_n(clkn_125MHz),
    // generic input to DDR buffers
    .red_ddr(red_ddr),
    .green_ddr(green_ddr),
    .blue_ddr(blue_ddr),
    .clock_ddr(clock_ddr),
    // HDMI output from DDR buffers
    .red_s(LVDS_Red),
    .green_s(LVDS_Green),
    .blue_s(LVDS_Blue),
    .clock_s(LVDS_ck)
  );

endmodule
