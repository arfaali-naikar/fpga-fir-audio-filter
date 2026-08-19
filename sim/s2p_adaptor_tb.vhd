LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY s2p_vhd_tst IS
END s2p_vhd_tst;

ARCHITECTURE s2p_arch OF s2p_vhd_tst IS

COMPONENT s2p_adaptor is
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
end COMPONENT;

--right side of instant value needs to be declared since we dont know those values
SIGNAL ADCDAT: std_logic_vector(15 downto 0);
SIGNAL DACDAT: std_logic_vector(15 downto 0);
SIGNAL DACrdy: std_logic;
SIGNAL ADCrdy: std_logic;
SIGNAL DACstb: std_logic;
SIGNAL ADCstb: std_logic;

-- Audio Side in MASTER mode
SIGNAL AUD_DACDAT: std_logic; -- serial data out
SIGNAL AUD_ADCDAT: std_logic; -- serial data in
SIGNAL AUD_ADCLRCK: std_logic; -- strobe for input
SIGNAL AUD_DACLRCK: std_logic; -- strobe for output
SIGNAL AUD_BCLK: std_logic; -- serial interface "clock"

-- Control Signals
SIGNAL CLOCK_50: std_logic ;
SIGNAL RST_N: std_logic := '0';

BEGIN

--instantiate the unit under test (The module you want to test)
i1 : s2p_adaptor
PORT MAP (
--input and op ports, means clk pin connected to clk pin
--local signals inside test bench connected to io ports of entity
ADCDAT => ADCDAT,
DACDAT => DACDAT,
DACrdy => DACrdy,
ADCrdy => ADCrdy,
DACstb => DACstb,
ADCstb => ADCstb,
AUD_DACDAT => AUD_DACDAT,
AUD_ADCDAT => AUD_ADCDAT,
AUD_ADCLRCK => AUD_ADCLRCK,
AUD_DACLRCK => AUD_DACLRCK,
AUD_BCLK => AUD_BCLK,
CLOCK_50 => CLOCK_50,
RST_N => RST_N
);

clk_proc :
PROCESS
variable i : integer;
BEGIN -- code that executes only once
for i in 1 to 100 loop -- specify here the length of the simulation run
 CLOCK_50 <= '0';
 wait for 10 ns;
 CLOCK_50 <= '1';
 wait for 10 ns;
 end loop;
 WAIT;
END PROCESS;

clk_proc2 :
PROCESS
variable i : integer;
BEGIN -- code that executes only once
for i in 1 to 100 loop -- specify here the length of the simulation run
 AUD_BCLK <= '0';
 wait for 20 ns;
 AUD_BCLK <= '1';
 wait for 20 ns;
 end loop;
 WAIT;
END PROCESS;

stim1:
 PROCESS
 BEGIN
 -- Reset signals
 RST_N <= '0';
 wait for 20 ns;
 RST_N <= '1';

 -- Provide input AUD_ADCDAT as 1
 AUD_ADCDAT <= '1';

 wait until rising_edge(CLOCK_50);
--ADCrdy <= '1';
--reset <= '1';
--wait for 20 ns;
--DACstb <= '1';
--reset <= '0';
--wait for 20 ns;
--AUD_ADCDAT <= '1';
--wait for 20 ns;
AUD_ADCLRCK <= '0';
wait for 20 ns;
--AUD_DACLRCK <= '1';
--wait for 20 ns;
--AUD_BCLK <= '1';
--T <= '0';
wait for 2000 ns;
RST_N <= '0';
wait;
END PROCESS;

stim2:
PROCESS
BEGIN
--reset <= '0';
--DACDAT <= '1';
AUD_DACLRCK <= '1';
DACstb <= '0';
for i in 1 to 16 loop
wait for 20 ns;
DACDAT(i-1) <= '1';
end loop;
--AUD_DACLRCK <= '1';
wait for 20 ns;
wait for 20 ns;
RST_N <= '1';
wait for 20 ns;
--ADCrdy <= '1';
--reset <= '1';
--wait for 20 ns;
--DACstb <= '1';
--reset <= '0';
--wait for 20 ns;
--AUD_ADCDAT <= '1';
--wait for 20 ns;
DACstb <= '1';
AUD_DACLRCK <= '0';
wait for 20 ns;
--AUD_DACLRCK <= '1';
--wait for 20 ns;
--AUD_BCLK <= '1';
--T <= '0';
wait for 2000 ns;
RST_N <= '0';
wait;
END PROCESS;

END s2p_arch;
