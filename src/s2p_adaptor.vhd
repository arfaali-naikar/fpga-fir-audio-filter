library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity s2p_adaptor is
port(
-- Control Signals
CLOCK_50: in std_logic ;
RST_N: in std_logic;
-- serial interface "clock"
AUD_BCLK: in std_logic;
-- Core Side - two parallel interfaces for input and output
ADCDAT: out std_logic_vector(15 downto 0);
DACDAT: in std_logic_vector(15 downto 0);
DACrdy: out std_logic;
ADCrdy: in std_logic;
DACstb: in std_logic;
ADCstb: out std_logic;
-- Audio Side in MASTER mode
-- serial data out
AUD_DACDAT: out std_logic;
-- serial data in
AUD_ADCDAT: in std_logic;
-- strobe for input
AUD_ADCLRCK: in std_logic;
-- strobe for output
AUD_DACLRCK: in std_logic
);
end entity;

architecture rtl of s2p_adaptor is

-- Internal Signals
--Bit slicing for integer to take only 16bit data
signal countIP: integer range 15 downto -1 ;
signal countOP: integer range 15 downto -1 ;
signal old_BCLK : std_logic;
signal old_AUD_DACLRCK : std_logic;
signal ADCstbSignal : std_logic;
--signal DACstbSignal : std_logic;
signal DACrdySignal : std_logic;

begin

process (CLOCK_50)
variable bit_ADC: integer;
begin
if (rising_edge(CLOCK_50)) then

if (RST_N = '0') then
old_BCLK <= '0';
countIP <= 15;
countOP <= 15;
ADCstbSignal <= '0';
--BCLK input

else
-- needed for change detection on
old_BCLK <= AUD_BCLK;
--old_AUD_DACLRCK <= AUD_DACLRCK;

------------------------------------- Input Channel ------------------------------------
--rising edge of AUD_BCLK protocol bit of the packet
if (old_BCLK = '0' AND AUD_BCLK = '1') then
-- condition for the start of the protocol
if (AUD_ADCLRCK = '1') then
-- load the bit counter
countIP <= 14;
-- read the first channel one bit interface
ADCDAT(15) <= AUD_ADCDAT;
-- condition for the data bits of the left
elsif(countIP >= 0) then
ADCDAT(countIP) <= AUD_ADCDAT;
-- advance the bit counter
countIP <= countIP - 1;
-- condition for the strobe of ADC parallel
if (countIP = 0) then
ADCstbSignal <= '1';
end if;
end if;
end if;
-- condition to drop the ADC strobe
if (ADCstbSignal = '1') then
ADCstbSignal <= '0';
end if;

-------------------------------------Output Channel -------------------------------------
--start condition
if(DACstb = '1') then
countOP <= 14; -- load the bit counter
AUD_DACDAT <= DACDAT(15); -- read the first bit of the packet
elsif (old_BCLK = '1' AND AUD_BCLK = '0' AND countOP >= 0) then -- each following falling edge
AUD_DACDAT <= DACDAT(countOP); -- produce DAC serial data bit
countOP <= countOP - 1;
end if;
if (countOP = 0) then
DACrdySignal <= '1'; -- condition for loading DAC parallel register
end if;
--if(DACstb = '1' AND DACrdySignal = '1') then
-- ready to receive the data from FIR filter
--DACrdy2 <= '0';
--end if;
end if;
----------------------------------- end sync design ------------------------------------
end if;
end process;

ADCstb <= ADCstbSignal;
DACrdy <= DACrdySignal;

end rtl;
