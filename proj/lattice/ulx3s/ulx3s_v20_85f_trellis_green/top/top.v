/* top.v - Top level module
** EMARD
*/

module top
(
  input clk_pin,
  output [7:0] led_pin,
  output [3:0] gpdi_dp_pin, gpdi_dn_pin,
  input btn_pin,
  output gpio0_pin
);

  wire clk;
  wire [7:0] led;
  wire [3:0] gpdi_dp, gpdi_dn;
  wire btn;
  wire gpio0;

  (* LOC="G2" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("INPUT")) clk_buf (.B(clk_pin), .O(clk));

  (* LOC="R1" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("INPUT")) btn_buf (.B(btn_pin), .O(btn));

  (* LOC="B2" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) led_buf_0 (.B(led_pin[0]), .I(led[0]));
  (* LOC="C2" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) led_buf_1 (.B(led_pin[1]), .I(led[1]));
  (* LOC="C1" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) led_buf_2 (.B(led_pin[2]), .I(led[2]));
  (* LOC="D2" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) led_buf_3 (.B(led_pin[3]), .I(led[3]));

  (* LOC="D1" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) led_buf_4 (.B(led_pin[4]), .I(led[4]));
  (* LOC="E2" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) led_buf_5 (.B(led_pin[5]), .I(led[5]));
  (* LOC="E1" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) led_buf_6 (.B(led_pin[6]), .I(led[6]));
  (* LOC="H3" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) led_buf_7 (.B(led_pin[7]), .I(led[7]));


  (* LOC="A16" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) gpdi_buf_dp0 (.B(gpdi_dp_pin[0]), .I(gpdi_dp[0]));
  (* LOC="B16" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) gpdi_buf_dn0 (.B(gpdi_dn_pin[0]), .I(gpdi_dn[0]));

  (* LOC="A14" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) gpdi_buf_dp1 (.B(gpdi_dp_pin[1]), .I(gpdi_dp[1]));
  (* LOC="C14" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) gpdi_buf_dn1 (.B(gpdi_dn_pin[1]), .I(gpdi_dn[1]));

  (* LOC="A12" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) gpdi_buf_dp2 (.B(gpdi_dp_pin[2]), .I(gpdi_dp[2]));
  (* LOC="A13" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) gpdi_buf_dn2 (.B(gpdi_dn_pin[2]), .I(gpdi_dn[2]));

  (* LOC="A17" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) gpdi_buf_dp3 (.B(gpdi_dp_pin[3]), .I(gpdi_dp[3]));
  (* LOC="B18" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) gpdi_buf_dn3 (.B(gpdi_dn_pin[3]), .I(gpdi_dn[3]));


  (* LOC="L2" *) (* IO_TYPE="LVCMOS33" *)
  TRELLIS_IO #(.DIR("OUTPUT")) gpio0_buf (.B(gpio0_pin), .I(gpio0));

  // Tie GPIO0, keep board from rebooting
  assign gpio0 = 1'b1;

  wire clk_25MHz, clk_250MHz, clk_locked;
  clock
  clock_instance
  (
    .clkin_25MHz(clk),
    .clk_25MHz(clk_25MHz),
    .clk_250MHz(clk_250MHz),
    .locked(clk_locked)
  );

  wire [2:0] vga_r, vga_g, vga_b;
  wire vga_hsync, vga_vsync, vga_blank;

  /*
  caleidoscope generator
  (
    .CLK_25MHz(clk_25MHz),
    .RED(vga_r),
    .GREEN(vga_g),
    .BLUE(vga_b),
    .VS(vga_vsync),
    .HS(vga_hsync),
    .BLANK(vga_blank),
    .SWITCH(3'b100)
  );
  */

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

  assign vga_r = 0;
  assign vga_g = 1;
  assign vga_b = 0;

  // last stage of generic output -> input to vendor specific DDR buffers
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
    .red_sdr(red_sdr),
    .green_sdr(green_sdr),
    .blue_sdr(blue_sdr),
    .clock_sdr(clock_sdr)
  );

  // This module converts VGA to DVI using clock domain crossing
  // it should generate green scren.
  // it works for diamond but nor for trellis
  //OBUFDS OBUFDS_clock(.I(clock_sdr), .O(gpdi_dp[3]), .OB(gpdi_dn[3]));
  //OBUFDS OBUFDS_red  (.I(red_sdr),   .O(gpdi_dp[2]), .OB(gpdi_dn[2]));
  OBUFDS OBUFDS_green(.I(green_sdr), .O(gpdi_dp[1]), .OB(gpdi_dn[1])); // trellis: GARBAGE on green channel
  //OBUFDS OBUFDS_blue (.I(blue_sdr),  .O(gpdi_dp[0]), .OB(gpdi_dn[0]));

  // This module generates DVI signal from the same clock domain
  // color test picture should appear.
  // this works for prjtrellis
  OBUFDS OBUFDS_clock(.I(clock_sdr_test), .O(gpdi_dp[3]), .OB(gpdi_dn[3]));
  OBUFDS OBUFDS_red  (.I(red_sdr_test),   .O(gpdi_dp[2]), .OB(gpdi_dn[2]));
  //OBUFDS OBUFDS_green(.I(green_sdr_test), .O(gpdi_dp[1]), .OB(gpdi_dn[1]));
  OBUFDS OBUFDS_blue (.I(blue_sdr_test),  .O(gpdi_dp[0]), .OB(gpdi_dn[0]));

  // some LED visible indicators
  assign led[0] = btn;
  assign led[2] = vga_vsync;
  assign led[3] = vga_hsync;
  assign led[4] = vga_blank;
  assign led[7] = clk_locked;

endmodule
