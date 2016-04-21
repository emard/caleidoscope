/* top.v - Top level module
** EMARD
*/

module top
(
  input wire clk_50MHz,
  input wire [4:1] SW,
  output wire [2:0] TMDS_in_P, TMDS_in_N, TMDS_out_P, TMDS_out_N,
  output wire TMDS_in_CLK_P, TMDS_in_CLK_N, TMDS_out_CLK_P, TMDS_out_CLK_N,
  output wire [7:0] LEDS
);

  wire clk_25MHz, clk_100MHz, clk_250MHz;
  wire [2:0] tmds_signal_rgb;
  wire [7:0] vga_r, vga_g, vga_b;
  wire vga_hsync, vga_vsync, vga_blank;
  // after edge enhancement effect filter
  wire [7:0] fx_vga_r, fx_vga_g, fx_vga_b;
  wire fx_vga_hsync, fx_vga_vsync, fx_vga_blank;

  assign LEDS = 8'hAA;

  pll_50M_100M_25M_250M clock_generator
  (
    .CLK_IN1(clk_50MHz),
    .CLK_OUT1(clk_100MHz), // not used
    .CLK_OUT2(clk_25MHz),
    .CLK_OUT3(clk_250MHz)
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
    .SWITCH(SW[3:1])
  );

  edge_enhance filter
  (
    .clk(clk_25MHz),
    .enable_feature(SW[4]),
    
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

  vga2hdmi vga_to_hdmi(
    .pixclk(clk_25MHz),
    .pixclk_x10(clk_250MHz),
    .vga_r(fx_vga_r),
    .vga_g(fx_vga_g),
    .vga_b(fx_vga_b),
    .vga_hsync(fx_vga_hsync),
    .vga_vsync(fx_vga_vsync),
    .vga_blank(fx_vga_blank),
    .tmds_out_rgb(tmds_signal_rgb)
  );

  hdmi_out_xc6 hdmi1
  (
    .tmds_in_clk(clk_25MHz),
    .tmds_out_clk_p(TMDS_out_CLK_P),
    .tmds_out_clk_n(TMDS_out_CLK_N),
    .tmds_in_rgb(tmds_signal_rgb),
    .tmds_out_rgb_p(TMDS_out_P),
    .tmds_out_rgb_n(TMDS_out_N)
  );

  hdmi_out_xc6 hdmi2
  (
    .tmds_in_clk(clk_25MHz),
    .tmds_out_clk_p(TMDS_in_CLK_P),
    .tmds_out_clk_n(TMDS_in_CLK_N),
    .tmds_in_rgb(tmds_signal_rgb),
    .tmds_out_rgb_p(TMDS_in_P),
    .tmds_out_rgb_n(TMDS_in_N)
  );

endmodule
