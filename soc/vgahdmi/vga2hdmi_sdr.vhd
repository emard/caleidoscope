--------------------------------------------------------------------------------
-- Engineer:		Mike Field <hamster@snap.net.nz>
-- Description:	Converts VGA signals into DVID bitstreams.
--
--	'clk' should be 5x clk_pixel.
--
--	'blank' should be asserted during the non-display 
--	portions of the frame
--------------------------------------------------------------------------------
-- See: http://hamsterworks.co.nz/mediawiki/index.php/Dvid_test
--		http://hamsterworks.co.nz/mediawiki/index.php/FPGA_Projects
--
-- Copyright (c) 2012 Mike Field <hamster@snap.net.nz>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vga2hdmi_sdr is
	Generic (
		-- C_shift_clock_synchronizer: boolean := true; -- try to get out_clock in sync with clk_pixel
		C_depth	: integer := 8
	);
	Port (
		clk       : in	STD_LOGIC;
		clk_pixel : in	STD_LOGIC;
		red_p     : in	STD_LOGIC_VECTOR (C_depth-1 downto 0);
		green_p   : in	STD_LOGIC_VECTOR (C_depth-1 downto 0);
		blue_p    : in	STD_LOGIC_VECTOR (C_depth-1 downto 0);
		blank     : in	STD_LOGIC;
		hsync     : in	STD_LOGIC;
		vsync     : in	STD_LOGIC;
		red_sdr	  : out STD_LOGIC;
		green_sdr : out STD_LOGIC;
		blue_sdr  : out STD_LOGIC;
		clock_sdr : out STD_LOGIC
	);
end;

architecture Behavioral of vga2hdmi_sdr is

	signal encoded_red, encoded_green, encoded_blue : std_logic_vector(9 downto 0);
	signal latched_red, latched_green, latched_blue : std_logic_vector(9 downto 0) := (others => '0');
	signal shift_red, shift_green, shift_blue       : std_logic_vector(9 downto 0) := (others => '0');
	signal not_blank: std_logic;
	constant C_shift_clock_initial: std_logic_vector(9 downto 0) := "0000011111";
	-- signal shift_clock : std_logic_vector(9 downto 0) := C_shift_clock_initial;
	signal shift_clock : std_logic_vector(9 downto 0) := "0011111000";
	signal R_shift_clock_off_sync: std_logic := '0';
	signal R_shift_clock_synchronizer: std_logic_vector(7 downto 0) := (others => '0');


	constant c_red   : std_logic_vector(1 downto 0) := (others => '0');
	constant c_green : std_logic_vector(1 downto 0) := (others => '0');
	signal   c_blue	 : std_logic_vector(1 downto 0);

	signal	red_d	: STD_LOGIC_VECTOR (7 downto 0);
	signal	green_d	: STD_LOGIC_VECTOR (7 downto 0);
	signal	blue_d	: STD_LOGIC_VECTOR (7 downto 0);

        component tmds_encoder_v
        port
        (
          clk     : in  std_logic;
          VD      : in  std_logic_vector(7 downto 0);
          CD      : in  std_logic_vector(1 downto 0);
          VDE     : in  std_logic;
          TMDS    : out std_logic_vector(9 downto 0)
        );
        end component;
begin	
	c_blue <= vsync & hsync;
	
	red_d(7 downto 8-C_depth)   <= red_p(C_depth-1 downto 0);
	green_d(7 downto 8-C_depth) <= green_p(C_depth-1 downto 0);
	blue_d(7 downto 8-C_depth)  <= blue_p(C_depth-1 downto 0);
	-- fill vacant low bits with value repeated (so min/max value is always 0 or 255)
	G_bits: for i in 8-C_depth-1 downto 0 generate
		red_d(i)   <= red_p(0);
		green_d(i) <= green_p(0);
		blue_d(i)  <= blue_p(0);
	end generate;
	
	not_blank <= not blank;

	u21 : tmds_encoder_v PORT MAP(clk => clk_pixel, VD => red_d,   CD => c_red,   VDE => not_blank, TMDS => encoded_red);
	u22 : tmds_encoder_v PORT MAP(clk => clk_pixel, VD => green_d, CD => c_green, VDE => not_blank, TMDS => encoded_green);
	u23 : tmds_encoder_v PORT MAP(clk => clk_pixel, VD => blue_d,  CD => c_blue,  VDE => not_blank, TMDS => encoded_blue);

	-- G_shift_clock_synchronizer: if C_shift_clock_synchronizer generate
	-- sampler verifies is shift_clock state synchronous with pixel_clock
	process(clk_pixel)
	begin
		if rising_edge(clk_pixel) then
			-- does 0 to 1 transition at bits 5 downto 4 happen at rising_edge of clk_pixel?
			-- if shift_clock = C_shift_clock_initial then
			if shift_clock(5 downto 4) = C_shift_clock_initial(5 downto 4) then -- same as above line but simplified 
				R_shift_clock_off_sync <= '0';
			else
				R_shift_clock_off_sync <= '1';
			end if;
		end if;
	end process;
	-- every N cycles of clk_shift: signal to skip 1 cycle in order to get in sync
	process(clk)
	begin
		if rising_edge(clk) then
			if R_shift_clock_off_sync = '1' then
				if R_shift_clock_synchronizer(R_shift_clock_synchronizer'high) = '1' then
					R_shift_clock_synchronizer <= (others => '0');
				else
					R_shift_clock_synchronizer <= R_shift_clock_synchronizer + 1;
				end if;
			else
				R_shift_clock_synchronizer <= (others => '0');
			end if;
		end if;
	end process;
	-- end generate; -- shift_clock_synchronizer

	process(clk_pixel)
	begin
		if rising_edge(clk_pixel) then 
			latched_red   <= encoded_red;
			latched_green <= encoded_green;
			latched_blue  <= encoded_blue;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then 
		-- if shift_clock = "0000011111" then
		if shift_clock(5 downto 4) = C_shift_clock_initial(5 downto 4) then -- same as above line but simplified 
			shift_red   <= latched_red;
			shift_green <= latched_green;
			shift_blue  <= latched_blue;
		else
			shift_red   <= "0" & shift_red	(9 downto 1);
			shift_green <= "0" & shift_green(9 downto 1);
			shift_blue  <= "0" & shift_blue (9 downto 1);
		end if;
		if R_shift_clock_synchronizer(R_shift_clock_synchronizer'high) = '0' then
			shift_clock <= shift_clock(0) & shift_clock(9 downto 1);
		end if;
		end if; -- rising edge
	end process;

	-- output ready for SDR vendor primitives
	red_sdr   <= shift_red(0);
	green_sdr <= shift_green(0);
	blue_sdr  <= shift_blue(0);
	clock_sdr <= shift_clock(0);

end Behavioral;
