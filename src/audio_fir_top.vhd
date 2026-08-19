-------------------------------------------------------------------------------
-- audio_fir_top.vhd
--
-- Top-level: wires codec_init, s2p_adaptor and fir_filter together into the
-- full real-time audio signal chain, targeting the DE1-SoC (Cyclone V
-- 5CSEMA5F31C6).
--
-- This mirrors the block-level wiring shown in the original design report's
-- "System of all the Blocks" schematic (audio_filter.bdf): the async audio
-- interface signals (AUD_BCLK, AUD_ADCDAT, AUD_ADCLRCK, AUD_DACLRCK) are
-- double-registered into the CLOCK_50 domain before reaching s2p_adaptor,
-- and KEY(0) is registered the same way to form the synchronous reset.
--
-- NOTE: the original schematic also used an altclkctrl megafunction to
-- derive AUD_XCK; that IP isn't reproduced here in plain VHDL, so AUD_XCK is
-- simply CLOCK_50 passed through -- revisit this against the WM8731's actual
-- master-clock requirement before programming real hardware.
--
-- Pin assignments (CLOCK_50, KEY, AUD_*, FPGA_I2C_*) are board-specific and
-- are made in Quartus (Pin Planner / .qsf), not in this file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity audio_fir_top is
    port (
        CLOCK_50      : in  std_logic;
        KEY           : in  std_logic_vector(3 downto 0);  -- KEY(0) = active-low reset

        -- WM8731 I2C control interface
        FPGA_I2C_SCLK : out std_logic;
        FPGA_I2C_SDAT : out std_logic;  -- open-drain in codec_init (drives 'Z' during ACK slots)

        -- WM8731 I2S audio interface
        AUD_ADCDAT    : in  std_logic;
        AUD_ADCLRCK   : in  std_logic;
        AUD_DACDAT    : out std_logic;
        AUD_DACLRCK   : in  std_logic;
        AUD_BCLK      : in  std_logic;
        AUD_XCK       : out std_logic
    );
end entity audio_fir_top;

architecture structural of audio_fir_top is

    signal RES_N : std_logic;  -- synchronized reset, active low

    -- Double-registered (CLOCK_50 domain) copies of the async audio signals
    signal aud_bclk_d1,   aud_bclk_d2   : std_logic := '0';
    signal aud_adcdat_d1, aud_adcdat_d2 : std_logic := '0';
    signal aud_adclrck_d1, aud_adclrck_d2 : std_logic := '0';
    signal aud_daclrck_d1, aud_daclrck_d2 : std_logic := '0';
    signal key0_d1, key0_d2 : std_logic := '0';

    signal adc_par : std_logic_vector(15 downto 0);
    signal adc_stb  : std_logic;
    signal adc_rdy  : std_logic;

    signal dac_par : std_logic_vector(15 downto 0);
    signal dac_stb  : std_logic;
    signal dac_rdy  : std_logic;

begin

    AUD_XCK <= CLOCK_50;  -- master clock to the codec (see note above)

    -- Synchronizing flip-flops (dffp) for the async audio/reset inputs
    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            aud_bclk_d1    <= AUD_BCLK;    aud_bclk_d2    <= aud_bclk_d1;
            aud_adcdat_d1  <= AUD_ADCDAT;  aud_adcdat_d2  <= aud_adcdat_d1;
            aud_adclrck_d1 <= AUD_ADCLRCK; aud_adclrck_d2 <= aud_adclrck_d1;
            aud_daclrck_d1 <= AUD_DACLRCK; aud_daclrck_d2 <= aud_daclrck_d1;
            key0_d1        <= KEY(0);      key0_d2        <= key0_d1;
        end if;
    end process;

    RES_N <= key0_d2;

    u_codec_init : entity work.codec_init
        port map (
            CLOCK_50 => CLOCK_50,
            RES_N    => RES_N,
            SCLK     => FPGA_I2C_SCLK,
            SDIN     => FPGA_I2C_SDAT
        );

    u_s2p_adaptor : entity work.s2p_adaptor
        port map (
            CLOCK_50    => CLOCK_50,
            RST_N       => RES_N,
            AUD_BCLK    => aud_bclk_d2,
            ADCDAT      => adc_par,
            DACDAT      => dac_par,
            DACrdy      => dac_rdy,
            ADCrdy      => adc_rdy,
            DACstb      => dac_stb,
            ADCstb      => adc_stb,
            AUD_DACDAT  => AUD_DACDAT,
            AUD_ADCDAT  => aud_adcdat_d2,
            AUD_ADCLRCK => aud_adclrck_d2,
            AUD_DACLRCK => aud_daclrck_d2
        );

    u_fir_filter : entity work.fir_filter
        port map (
            ADCDAT   => adc_par,
            DACDAT   => dac_par,
            ADCrdy   => adc_rdy,
            DACrdy   => dac_rdy,
            ADCstb   => adc_stb,
            DACstb   => dac_stb,
            RST_N    => RES_N,
            CLOCK_50 => CLOCK_50
        );

end architecture structural;
