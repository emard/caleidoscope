// (c) fpga4fun.com & KNJN LLC 2013

////////////////////////////////////////////////////////////////////////
module DVI_test
(
	input pixclk,  // 25MHz
	input shiftclk, // 250MHz
	output hsync, vsync, blank,
	output red_sdr, green_sdr, blue_sdr, clock_sdr
);

////////////////////////////////////////////////////////////////////////
assign clk_TMDS = shiftclk;

////////////////////////////////////////////////////////////////////////
reg [7:0] red, green, blue;
reg [9:0] CounterX, CounterY;
reg hSync, vSync, Blank;
always @(posedge pixclk) Blank <= (CounterX>=640) || (CounterY>=480);

always @(posedge pixclk) CounterX <= (CounterX==799) ? 0 : CounterX+1;
always @(posedge pixclk) if(CounterX==799) CounterY <= (CounterY==524) ? 0 : CounterY+1;

always @(posedge pixclk) hSync <= (CounterX>=656) && (CounterX<752);
always @(posedge pixclk) vSync <= (CounterY>=490) && (CounterY<492);

////////////////
wire [7:0] W = {8{CounterX[7:0]==CounterY[7:0]}};
wire [7:0] A = {8{CounterX[7:5]==3'h2 && CounterY[7:5]==3'h2}};
// reg [7:0] red, green, blue;
always @(posedge pixclk) red <= ({CounterX[5:0] & {6{CounterY[4:3]==~CounterX[4:3]}}, 2'b00} | W) & ~A;
always @(posedge pixclk) green <= (CounterX[7:0] & {8{CounterY[6]}} | W) & ~A;
always @(posedge pixclk) blue <= CounterY[7:0] | W | A;

////////////////////////////////////////////////////////////////////////
wire [9:0] TMDS_red, TMDS_green, TMDS_blue;
tmds_encoder_v encode_R(.clk(pixclk), .VD(red  ), .CD(2'b00)        , .BLANK(Blank), .TMDS(TMDS_red));
tmds_encoder_v encode_G(.clk(pixclk), .VD(green), .CD(2'b00)        , .BLANK(Blank), .TMDS(TMDS_green));
tmds_encoder_v encode_B(.clk(pixclk), .VD(blue ), .CD({vSync,hSync}), .BLANK(Blank), .TMDS(TMDS_blue));

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

assign red_sdr = TMDS_shift_red[0];
assign green_sdr = TMDS_shift_green[0];
assign blue_sdr = TMDS_shift_blue[0];
assign clock_sdr = pixclk;
assign hsync = hSync;
assign vsync = vSync;
assign blank = Blank;
endmodule

////////////////////////////////////////////////////////////////////////
