/* caleidoscope.v - Top caleidoscope generator module

	DigitalCold's ARM Challenge VGA Implementation
		Freefull's graphics demo reimplemented on the BASYS2 hardware.
		Additional information at http://io.smashthestack.org/arm/digitalcold/
		All Verilog code written by DigitalCold (sorry for all the warnings).
		WARNING: inexperienced Verilog programmer.
		
	Released 4/25/13
*/

module caleidoscope(CLK_25MHz, VS, HS, BLANK, RED, GREEN, BLUE, SWITCH);
	input CLK_25MHz;
	input [2:0] SWITCH;
	output VS; 
	output HS;
	output BLANK;
	output [2:0] RED;
	output [2:0] GREEN;
	output [1:0] BLUE;
	
	//these signals are exported by the vga_driver
	wire HBlank, VBlank;
	wire [9:0] CurrentX;
	wire [8:0] CurrentY;
	reg [7:0] DataIn = 0;
	
	vga_driver vga(
		.CLK_25MHz(CLK_25MHz),
		.VS(VS),
		.HS(HS),
		.RED(RED),
		.GREEN(GREEN),
		.BLUE(BLUE),
		.VBLANK(VBlank),
		.HBLANK(HBlank),
		.BLANK(BLANK),
		.CURX(CurrentX), 
		.CURY(CurrentY), 
		.COLOR_DATA_IN(DataIn)
	);

	//so many damn flip-flops
	reg [15:0] Time = 0;
	reg [15:0] TimeTri = 0;

	reg [23:0] TimeConst = 0;
	reg [1:0] ColorSel = 0;

	reg [31:0] pixel = 0;   //wasn't sure how much
	reg [7:0] pixelTri = 0; //gradient pixel version 

	reg [9:0] NewX;
	reg [8:0] NewY;
	reg [9:0] Xored;
	reg [15:0] Ysquared;

	//time simulation
	always @(posedge VBlank) begin
		if(SWITCH[2]) begin     //time "unlimited"
			if(SWITCH[1])        //2x speed using frame skipping
				Time <= Time + 2;
			else                 //normal
				Time <= Time + 1; 
		end
		else begin
			if(SWITCH[1])                 //2x speed with frame skipping (limited)
				Time <= (Time + 2) & 'hFF;
			else                          //normal (limited)
				Time <= (Time + 1) & 'hFF; 
		end
		
		if(SWITCH[0]) //stopped
			Time <= Time;
	end

	//turn time in to a triangle wave /\/\/\/\/\ (NOTICE negedge)
	always @(negedge VBlank) begin
		if(Time >= 'h80)
			TimeTri <= 'hFF - Time;
		else
			TimeTri <= Time;
	end

	//calculate the TimeConst to be used for this frame
	always @(posedge VBlank) begin
		TimeConst <= 'h200 - (TimeTri << 3);
	end

	//new scanline: calculate our new Y value
	always @(posedge HBlank) begin //the -1 is to remove mirroring ugliness
		NewY = (CurrentY < 240 ) ? CurrentY : 480 - CurrentY - 1; 
		Ysquared = NewY*NewY;
	end

	//new pixel: calculate our new X value and the pixel value
	// trigger on negative edge, when data are ready
	always @(negedge CLK_25MHz) begin
		NewX = (CurrentX < 320) ? CurrentX : 640 - CurrentX - 1;
		Xored = NewX ^ NewY;

		//Yuck, but it meets timing! Wahooo!
		pixel = ((TimeConst + Xored)*Xored + Ysquared) >> 8;
		ColorSel = (pixel >> 8) & 2'b11;
		pixel = pixel & 'hff;

		//Make the pixel turn in to a gradient
		if(pixel >= 'h80)
			pixelTri = 'hFF - pixel;
		else
			pixelTri = pixel;
		
		if(!ColorSel)
			DataIn = ((pixelTri) << 1) & 8'b11100000;
		else if(ColorSel == 1)
			DataIn = ((pixelTri) >> 2) & 5'b11100;
		else
			DataIn = ((pixelTri) >> 5) & 2'b11;
	end

endmodule
