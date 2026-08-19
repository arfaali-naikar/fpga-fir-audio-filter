# FPGA Audio Signal Processing — FIR Filter

Real-time audio filtering on a **DE1-SoC (Cyclone V)** FPGA. A WM8731 codec
streams audio in over I2S; an 8-tap FIR low-pass filter, implemented in
VHDL, filters it in the digital domain; the result streams back out to the
codec for playback.

```
WM8731 (ADC) ──I2S──▶ s2p_adaptor ──16-bit──▶ fir_filter ──16-bit──▶ s2p_adaptor ──I2S──▶ WM8731 (DAC)
                                                                                          codec_init configures
                                                                                          the WM8731 over I2C on reset
```

## Provenance

`src/codec_init.vhd`, `src/s2p_adaptor.vhd`, and `src/fir_filter.vhd` are
**verbatim transcriptions** of the original VHDL from Appendices a, c, and e
of the accompanying design report (EEE8088, Newcastle University, Mar 2024)
— not a rewrite. The source files themselves were lost; the report's
appendix had the only surviving copy, so this repo recovers them exactly as
submitted. `sim/*_tb.vhd` are the original ModelSim testbenches from
Appendices b, d, and f, transcribed the same way (one line in
`fir_filter_tb.vhd` needed `44100` written as `44100.0` for GHDL, noted
inline — ModelSim accepted the bare integer literal there, GHDL doesn't).

`src/audio_fir_top.vhd` is **not** from the report — the original `.bdf`
schematic wasn't in the appendix, only a screenshot of it (Figure 22). This
top-level is a reasonable reconstruction from that figure (block wiring,
synchronizing flip-flops on the async audio/reset signals) but hasn't been
verified against real hardware.

## Blocks

| File | Role |
|---|---|
| `src/codec_init.vhd` | Configures the WM8731 over its I2C control interface on power-up. Ports: `CLOCK_50`, `RES_N`, `SCLK`, `SDIN`. |
| `src/s2p_adaptor.vhd` | Converts the codec's serial I2S stream to/from 16-bit parallel words. |
| `src/fir_filter.vhd` | 8-tap symmetric FIR low-pass filter, single-multiplier sequential MAC. |
| `src/audio_fir_top.vhd` | Reconstructed top-level wiring the above three blocks (see Provenance). |

**Filter design:** 8 taps, coefficients `-1260, 7827, 12471, 16384, 16384,
12471, 7827, 1260` (symmetric → linear phase). Samples and coefficients are
16-bit signed; the accumulator is 35 bits wide (`signed(34 downto 0)`) to
avoid overflow across all 8 taps, then truncated back to a 16-bit output.

## Simulating (GHDL)

No Quartus/ModelSim needed to check the logic — [GHDL](https://ghdl.github.io/ghdl/)
runs headless in WSL2. `fir_filter.vhd` uses the Synopsys
`std_logic_unsigned` package, so **every** `ghdl` invocation in this project
needs `-fsynopsys` (GHDL requires it consistently across analysis,
elaboration, and run — not just on the one file that uses the package):

```bash
sudo apt install ghdl-mcode   # once
mkdir -p work
ghdl -a --workdir=work --std=08 -fsynopsys src/codec_init.vhd
ghdl -a --workdir=work --std=08 -fsynopsys src/s2p_adaptor.vhd
ghdl -a --workdir=work --std=08 -fsynopsys src/fir_filter.vhd
ghdl -a --workdir=work --std=08 -fsynopsys src/audio_fir_top.vhd

# testbenches (original ModelSim .vht files, transcribed)
ghdl -a --workdir=work --std=08 -fsynopsys sim/codec_init_tb.vhd
ghdl -a --workdir=work --std=08 -fsynopsys sim/s2p_adaptor_tb.vhd
ghdl -a --workdir=work --std=08 -fsynopsys sim/fir_filter_tb.vhd

ghdl -e --workdir=work --std=08 -fsynopsys audio_fir_top
ghdl -e --workdir=work --std=08 -fsynopsys codec_init_vhd_tst
ghdl -e --workdir=work --std=08 -fsynopsys s2p_vhd_tst
ghdl -e --workdir=work --std=08 -fsynopsys fir_filter_vhd_tst

ghdl -r --workdir=work --std=08 -fsynopsys codec_init_vhd_tst  --stop-time=100us
ghdl -r --workdir=work --std=08 -fsynopsys s2p_vhd_tst         --stop-time=5us
ghdl -r --workdir=work --std=08 -fsynopsys fir_filter_vhd_tst  --stop-time=1ms
```

All three original testbenches compile, elaborate, and run cleanly under
GHDL with no errors (verified while assembling this repo). These are the
original testbenches as submitted, not new coverage — they exercise timing
and basic protocol behaviour rather than making tight self-checking
assertions, so they won't fail loudly on a subtly wrong sample; treat a
clean run as "doesn't crash," not "provably correct."

## Synthesizing for hardware

Requires Quartus Prime + a DE1-SoC board:
1. Create a new Quartus project targeting `5CSEMA5F31C6`.
2. Add all files under `src/` (top-level entity: `audio_fir_top`).
3. Assign pins for `CLOCK_50`, `KEY`, `FPGA_I2C_*`, and `AUD_*` per the
   DE1-SoC board pinout (not yet checked into this repo).
4. Compile and program.

## Background

Originally built for the Reconfigurable Hardware Design module (EEE8088,
Newcastle University, taught by Dr. Alex Bystrov and Dr. Nick Coleman),
as a group project (codec block: Arfaali Naikar; FIR filter: Vandana
Eganagoudar; S2P adaptor: Madhuri Dongare). Full design rationale,
simulation waveforms, and oscilloscope validation are documented in the
accompanying project report.
