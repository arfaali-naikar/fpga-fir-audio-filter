LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY codec_init_vhd_tst IS
END codec_init_vhd_tst;

ARCHITECTURE codec_init_arch OF codec_init_vhd_tst IS
-- signals
SIGNAL CLOCK_50 : STD_LOGIC;
SIGNAL RES_N : STD_LOGIC;
SIGNAL SCLK : STD_LOGIC;
SIGNAL SDIN : STD_LOGIC;

COMPONENT codec_init
PORT (
CLOCK_50 : IN STD_LOGIC;
RES_N : IN STD_LOGIC;
SCLK : OUT STD_LOGIC;
SDIN : OUT STD_LOGIC
);
END COMPONENT;

BEGIN
i1 : codec_init
PORT MAP (
CLOCK_50 => CLOCK_50,
RES_N => RES_N,
SCLK => SCLK,
SDIN => SDIN
);

stim:
PROCESS
BEGIN
RES_N <= '0';
wait for 42 ns;
RES_N <= '1';
wait;
END PROCESS;

clk_proc :
PROCESS
variable i : integer;
BEGIN -- code that executes only once
for i in 1 to 42*11*500 loop -- specify here the length of the simulation run
 CLOCK_50 <= '0';
 wait for 10 ns;
 CLOCK_50 <= '1';
 wait for 10 ns;
 end loop;
 WAIT;
END PROCESS;
END codec_init_arch;
