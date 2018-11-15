// File ../../../../soc/vgahdmi/vga2hdmi_sdr.vhd translated with vhd2vl v3.0 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 2001

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002-2017 Larry Doolittle
//     http://doolittle.icarus.com/~larry/vhd2vl/
//   Modifications (C) 2017 Rodrigo A. Melo
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// The result of translation follows.  Its copyright status should be
// considered unchanged from the original VHDL.

//------------------------------------------------------------------------------
// Engineer:		Mike Field <hamster@snap.net.nz>
// Description:	Converts VGA signals into DVID bitstreams.
//
//	'clk' should be 5x clk_pixel.
//
//	'blank' should be asserted during the non-display 
//	portions of the frame
//------------------------------------------------------------------------------
// See: http://hamsterworks.co.nz/mediawiki/index.php/Dvid_test
//		http://hamsterworks.co.nz/mediawiki/index.php/FPGA_Projects
//
// Copyright (c) 2012 Mike Field <hamster@snap.net.nz>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// no timescale needed

// C_shift_clock_synchronizer: boolean := true; -- try to get out_clock in sync with clk_pixel

module vga2hdmi_sdr(
input wire clk,
input wire clk_pixel,
input wire [3 - 1:0] red_p,
input wire [3 - 1:0] green_p,
input wire [3 - 1:0] blue_p,
input wire blank,
input wire hsync,
input wire vsync,
output wire red_sdr,
output wire green_sdr,
output wire blue_sdr,
output wire clock_sdr
);


wire [9:0] encoded_red; wire [9:0] encoded_green; wire [9:0] encoded_blue;
reg [9:0] latched_red = 1'b0; reg [9:0] latched_green = 1'b0; reg [9:0] latched_blue = 1'b0;
reg [9:0] shift_red = 1'b0; reg [9:0] shift_green = 1'b0; reg [9:0] shift_blue = 1'b0;
wire not_blank;
parameter C_shift_clock_initial = 10'b0000011111;
reg [9:0] shift_clock = C_shift_clock_initial;
reg R_shift_clock_off_sync = 1'b0;
reg [7:0] R_shift_clock_synchronizer = 1'b0;
parameter c_red = 1'b0;
parameter c_green = 1'b0;
wire [1:0] c_blue;
wire [7:0] red_d;
wire [7:0] green_d;
wire [7:0] blue_d;

  assign c_blue = {vsync,hsync};
  assign red_d[7:8 - 3] = red_p[3 - 1:0];
  assign green_d[7:8 - 3] = green_p[3 - 1:0];
  assign blue_d[7:8 - 3] = blue_p[3 - 1:0];
  // fill vacant low bits with value repeated (so min/max value is always 0 or 255)
  genvar i;
  generate for (i=8 - 3 - 1; i >= 0; i = i - 1) begin
    assign red_d[i] = red_p[0];
    assign green_d[i] = green_p[0];
    assign blue_d[i] = blue_p[0];
  end
  endgenerate
  assign not_blank =  ~blank;
  tmds_encoder_v enc_r(
      .clk(clk_pixel),
    .VD(red_d),
    .CD(c_red),
    .VDE(not_blank),
    .TMDS(encoded_red));

  tmds_encoder_v enc_g(
      .clk(clk_pixel),
    .VD(green_d),
    .CD(c_green),
    .VDE(not_blank),
    .TMDS(encoded_green));

  tmds_encoder_v enc_b(
      .clk(clk_pixel),
    .VD(blue_d),
    .CD(c_blue),
    .VDE(not_blank),
    .TMDS(encoded_blue));

  // G_shift_clock_synchronizer: if C_shift_clock_synchronizer generate
  // sampler verifies is shift_clock state synchronous with pixel_clock
  always @(posedge clk_pixel) begin
    // does 0 to 1 transition at bits 5 downto 4 happen at rising_edge of clk_pixel?
    // if shift_clock = C_shift_clock_initial then
    if(shift_clock[5:4] == C_shift_clock_initial[5:4]) begin
      // same as above line but simplified 
      R_shift_clock_off_sync <= 1'b0;
    end
    else begin
      R_shift_clock_off_sync <= 1'b1;
    end
  end

  // every N cycles of clk_shift: signal to skip 1 cycle in order to get in sync
  always @(posedge clk) begin
    if(R_shift_clock_off_sync == 1'b1) begin
      if(R_shift_clock_synchronizer[(7)] == 1'b1) begin
        R_shift_clock_synchronizer <= {8{1'b0}};
      end
      else begin
        R_shift_clock_synchronizer <= R_shift_clock_synchronizer + 1;
      end
    end
    else begin
      R_shift_clock_synchronizer <= {8{1'b0}};
    end
  end

  // end generate; -- shift_clock_synchronizer
  always @(posedge clk_pixel) begin
    latched_red <= encoded_red;
    latched_green <= encoded_green;
    latched_blue <= encoded_blue;
  end

  always @(posedge clk) begin
    // if shift_clock = "0000011111" then
    if(shift_clock[5:4] == C_shift_clock_initial[5:4]) begin
      // same as above line but simplified 
      shift_red <= latched_red;
      shift_green <= latched_green;
      shift_blue <= latched_blue;
    end
    else begin
      shift_red <= {1'b0,shift_red[9:1]};
      shift_green <= {1'b0,shift_green[9:1]};
      shift_blue <= {1'b0,shift_blue[9:1]};
    end
    if(R_shift_clock_synchronizer[(7)] == 1'b0) begin
      shift_clock <= {shift_clock[0],shift_clock[9:1]};
    end
  end

  // output ready for SDR vendor primitives
  assign red_sdr = shift_red[0];
  assign green_sdr = shift_green[0];
  assign blue_sdr = shift_blue[0];
  assign clock_sdr = shift_clock[0];

endmodule
