# UART Transmitter / Receiver — ASIC Front-End Design Diploma

RTL design + verification + lint for a configurable UART TX/RX block.

| Block | Status | Simulator | Lint |
|---|---|---|---|
| **UART_TX** | ✅ Done | QuestaSim / ModelSim | SpyGlass — clean (0 errors, 0 warnings) |
| **UART_RX** | 🚧 In progress | — | — |

---

## UART_TX

Converts an 8-bit parallel byte into a serial frame: `START(0) → 8 data bits (LSB first) → [parity] → STOP(1)`.
Parity is configurable (enable/disable, even/odd). `CLK` is the bit-rate clock directly.

**Architecture:** FSM (IDLE/START/DATA/PARITY/STOP) driving a Serializer, a Parity Calculator, and an output MUX.

**Files:**
```
uart_tx.v         top module
fsm.v / serializer.v / parity_calc.v / tx_mux.v   sub-blocks
tb_uart_tx.v       self-checking testbench (200 MHz)
sourcefile.txt / run.do / wave.do    sim scripts
```

**Run:** `do run.do` in QuestaSim/ModelSim.

**Tests (all passing):** even parity, odd parity, no parity, `DATA_VALID` ignored while busy, async reset mid-frame.

**Lint fixes (SpyGlass):**
- Added `` `timescale `` to all RTL files.
- Removed an unused `par_en_latched` output port from `fsm.v` (kept it internal) — this also fixed a real bug where the FSM was using the live `PAR_EN` instead of the latched value for the parity-state decision.

Result: 0 errors, 0 warnings.

---

## UART_RX

🚧 Not started yet — will detect start bit, sample 8 data bits, check parity/stop, flag framing errors. Details to be added once implemented.

---

**Toolchain:** Verilog · QuestaSim/ModelSim (cross-checked with Icarus Verilog) · Synopsys SpyGlass

