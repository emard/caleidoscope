/* vga_driver.v

	DigitalCold's ARM Challenge VGA Implementation
		Freefull's graphics demo reimplemented on the BASYS2 hardware.
		Additional information at http://io.smashthestack.org/arm/digitalcold/
		All Verilog code written by DigitalCold (sorry for all the warnings).
		
	Released 4/25/13
*/

module vga_driver(CLK_25MHz, VS, HS, RED, GREEN, BLUE, HBLANK, VBLANK, BLANK, CURX, CURY, CLK_DATA, COLOR_DATA_IN);
	//##### IO declarations
	input CLK_25MHz;
	output VS;
	output HS;
	output [2:0] RED;
	output [2:0] GREEN;
	output [1:0] BLUE;
	output HBLANK;
	output VBLANK;
	output BLANK;

	reg VS = 0; //vsync
	reg HS = 0; //hsync

	//client connection I/O
	input [7:0] COLOR_DATA_IN;
	output CLK_DATA;
	output [9:0] CURX; 
	output [8:0] CURY;

	//##### Module constants (http://tinyvga.com/vga-timing/640x480@60Hz)
	parameter HDisplayArea = 640;  // horizontal display area
	parameter HLimit = 800;        // maximum horizontal amount (limit)
	parameter HFrontPorch = 16;    // h. front porch
	parameter HBackPorch = 48;     // h. back porch
	parameter HSyncWidth = 96;     // h. pulse width

	parameter VDisplayArea = 480;  // vertical display area
	parameter VLimit = 525;        // maximum vertical amount (limit)
	parameter VFrontPorch = 10;    // v. front porch
	parameter VBackPorch = 33;     // v. back porch
	parameter VSyncWidth = 2;      // v. pulse width   

	//##### Local variables
	wire CLK_25MHz;

	reg [9:0] CurHPos = 0; //maximum of HLimit (2^10 - 1 = 1023)
	reg [9:0] CurVPos = 0; //maximum of VLimit
	reg HBlank, VBlank, Blank = 0;

	reg [9:0] CurrentX = 0; //maximum of HDisplayArea
	reg [8:0] CurrentY = 0; //maximum of VDisplayArea (2^9 - 1 = 511)

	//##### Submodule declaration
	//clock_divider clk_div(.clk_in(CLK_50MHz), .clk_out(CLK_25MHz));

	//shifts the clock by half a period (negates it)
	//assign CLOCK_DATA = ~CLK_25MHz;
	//see timing diagrams for a better understanding of the reason for this
	clock_shift clk_shift(.clk_in(CLK_25MHz), .clk_out(CLK_DATA));

	//##### Procedural Code

	//simulate the vertical and horizontal positions
	always @(posedge CLK_25MHz) begin
		if(CurHPos < HLimit-1) begin
			CurHPos <= CurHPos + 1;
		end
		else begin
			CurHPos <= 0;
			
			if(CurVPos < VLimit-1)
				CurVPos <= CurVPos + 1;
			else
				CurVPos <= 0;
		end
	end

	//##### VGA Logic (http://tinyvga.com/vga-timing/640x480@60Hz)

	//HSync logic
	always @(posedge CLK_25MHz)
		if(CurHPos < HSyncWidth)
			HS <= 1;
		else
			HS <= 0;

	//VSync logic		
	always @(posedge CLK_25MHz)
		if(CurVPos < VSyncWidth)
			VS <= 1;
		else
			VS <= 0;

	//Horizontal logic		
	always @(posedge CLK_25MHz) 
		if((CurHPos >= HSyncWidth + HFrontPorch) && (CurHPos < HSyncWidth + HFrontPorch + HDisplayArea))
			HBlank <= 0;
		else
			HBlank <= 1;

	//Vertical logic
	always @(posedge CLK_25MHz)
		if((CurVPos >= VSyncWidth + VFrontPorch) && (CurVPos < VSyncWidth + VFrontPorch + VDisplayArea))
			VBlank <= 0;
		else
			VBlank <= 1;

	//Do not output any color information when we are in the vertical
	//or horizontal blanking areas. Set a boolean to keep track of this.
	always @(posedge CLK_25MHz)
		if(HBlank || VBlank)
			Blank <= 1;
		else
			Blank <= 0;

	//Keep track of the current "real" X position. This is the actual current X
	//pixel location abstracted away from all the timing details
	always @(posedge CLK_25MHz)
		if(HBlank)
			CurrentX <= 0;
		else
			CurrentX <= CurHPos - HSyncWidth - HFrontPorch;

	//Keep track of the current "real" Y position. This is the actual current Y
	//pixel location abstracted away from all the timing details
	always @(posedge CLK_25MHz) 
		if(VBlank)
			CurrentY <= 0;
		else
			CurrentY <= CurVPos - VSyncWidth - VFrontPorch;

	`ifdef DEBUG

	reg [7:0] Color = 0;

	//Nice VGA test pattern for possible screen debugging in the future
	always @(posedge CLK_25MHz) begin
		if(Blank) begin
			Color <= 0;
		end
		else begin
			//Color <= COLOR_DATA_IN

			//VGA test pattern
			if(CurrentY < 160)
				Color[7:5] <= 3'b111;
			else if(CurrentY < 320)
				Color[4:2] <= 3'b111;
			else
				Color[1:0] <= 2'b11;
		end
	end
	`endif

	//##### Combinatorial Code

	assign CURX = CurrentX;
	assign CURY = CurrentY;
	assign VBLANK = VBlank;
	assign HBLANK = HBlank;
	assign BLANK = Blank;

	`ifdef DEBUG
	assign RED = Color[7:5];
	assign GREEN = Color[4:2];
	assign BLUE = Color[1:0];
	`else
	//Respect VGA blanking areas. Do not drive color outputs when blanked (bad things may happen).
	assign RED = (Blank) ? 3'b000 : COLOR_DATA_IN[7:5];
	assign GREEN = (Blank) ? 3'b000 : COLOR_DATA_IN[4:2];
	assign BLUE = (Blank) ? 2'b00 : COLOR_DATA_IN[1:0];
	`endif
endmodule
