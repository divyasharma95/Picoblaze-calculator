----------------------------------------------------------------------------------
-- Name: Ethan Kho
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project7vhd is
port(
		clk50: in std_logic;
		pushbutton: in std_logic_vector(7 downto 0);
		sliderswitches: in std_logic_vector(7 downto 0);
		seg7: out std_logic_vector(7 downto 0);
		anode: out std_logic_vector(3 downto 0)
		);
end project7vhd;

architecture Behavioral of project7vhd is


-- signal from picoblaze---

signal address : std_logic_vector(9 downto 0);
signal instruction : std_logic_vector(17 downto 0);
signal port_id_signal : std_logic_vector( 7 downto 0);
signal write_strobe_signal : std_logic;
signal out_port_signal : std_logic_vector( 7 downto 0);
signal read_strobe_signal : std_logic;
signal in_port_signal : std_logic_vector( 7 downto 0);
signal interrupt_ack_signal : std_logic;
signal reset :std_logic;
--- signal from this code-----
signal dig1,dig2,dig3,dig4: std_logic_vector(3 downto 0):="0000"; --signal from debounce to 7seg
signal HEX: STD_LOGIC_VECTOR (3 downto 0); --input for 7seg
signal intclk: std_logic :='0'; --- internal clk signal
signal leds_reg : std_logic_vector(7 downto 0);
signal in_port : std_logic_vector( 7 downto 0);

component kcpsm3 is
    Port (      address : out std_logic_vector(9 downto 0);
            instruction : in std_logic_vector(17 downto 0);
                port_id : out std_logic_vector(7 downto 0);
           write_strobe : out std_logic;
               out_port : out std_logic_vector(7 downto 0);
            read_strobe : out std_logic;
                in_port : in std_logic_vector(7 downto 0);
              interrupt : in std_logic;
          interrupt_ack : out std_logic;
                  reset : in std_logic; 
                    clk : in std_logic);
    end component;
	 
component PROJ7 is 
    Port (      address : in std_logic_vector(9 downto 0);
            instruction : out std_logic_vector(17 downto 0);
                    clk : in std_logic);
    end component;

begin
processor: kcpsm3
port map(
	address => address,
	instruction => instruction,
	port_id => port_id_signal,
	write_strobe => write_strobe_signal,
	out_port => out_port_signal,
	read_strobe => read_strobe_signal,
	in_port => in_port_signal,
	interrupt => pushbutton(3),
	interrupt_ack => interrupt_ack_signal,
	reset => reset,
	clk => INTCLK
);

-- choose the input based on the portid. use case as for additional input in the future
readmux: process(port_id_signal,sliderswitches,in_port,pushbutton)
begin
	case port_id_signal is
		when x"00" => in_port <= sliderswitches;
		when x"01" => in_port <= pushbutton;
	   when others => in_port <= x"5a";
	end case;
end process readmux;
leds_reg <= out_port_signal when rising_edge(clk50) and (port_id_signal=x"00") and (write_strobe_signal='1');
in_port_signal <= in_port when rising_edge(clk50);

---------------50 Mhz to 1khz clock----------------
divclk:process(clk50)
variable counter:integer:=0;
begin
   if clk50'event and clk50='1' then  
		counter:=counter+1;
		if counter=50000 then
			intclk<= not intclk;
			counter:=0;
		end if;
	end if;
end process divclk;
----------------------------------------------------
-----------------------------------------------------

progrom : PROJ7 port map (address => address, 
									instruction => instruction,
									clk=>INTCLK);


----for 7 segment display-----
Process(intclk,leds_reg) 
variable c: integer range 0 to 3; 
begin 
dig1<=leds_reg(3)&leds_reg(2)&leds_reg(1)&leds_reg(0);
dig2<=leds_reg(7)&leds_reg(6)&leds_reg(5)&leds_reg(4);
If intclk'event and intclk='1' then 
	if c= 3 then
		c:=0;
	else	
		c:=c+1;
	end if;

case c is
	when 0 => anode<="1110";
		HEX<=dig1;
	when 1 => anode<="1101";
		HEX<=dig2;
	when 2 => anode<="1011";
		HEX<=dig3;
	when 3 => anode<="0111";
		HEX<=dig4;
	end case;
end if;
end process;
--HEX-to-seven-segment decoder
--   HEX:   in    STD_LOGIC_VECTOR (3 downto 0);
--   seg7:   out   STD_LOGIC_VECTOR (7 downto 0);
-- 
-- segment encoinputg
--      0
--     ---  
--  5 |   | 1
--     ---   <- 6
--  4 |   | 2
--     ---
--      3
   
    with HEX SELect
   seg7<="11111001" when "0001",   --1
         "10100100" when "0010",   --2
         "10110000" when "0011",   --3
         "10011001" when "0100",   --4
         "10010010" when "0101",   --5
         "10000010" when "0110",   --6
         "11111000" when "0111",   --7
         "10000000" when "1000",   --8
         "10010000" when "1001",   --9
         "10001000" when "1010",   --A
         "10000011" when "1011",   --b
         "11000110" when "1100",   --C
         "10100001" when "1101",   --d
         "10000110" when "1110",   --E
         "10001110" when "1111",   --F
         "11000000" when others;   --0


end Behavioral;

