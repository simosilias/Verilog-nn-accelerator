# ⚡ Digital Systems HW-1 — ALU, Calculator & Neural Network Accelerator

A hardware design project implemented in Verilog, built as a university lab assignment for the **Digital Systems** course at Aristotle University of Thessaloniki. The project is developed incrementally across four exercises, culminating in a pipelined AI accelerator that runs a small neural network.

---

## Project Overview

| Exercise | Module(s) | Description |
|----------|-----------|-------------|
| 1 | `alu.v` | 32-bit Arithmetic Logic Unit |
| 2 | `calc.v`, `calc_enc.v`, `calc_tb.v` | 16-bit accumulator-based calculator |
| 3 | `regfile.v` | 16×32-bit register file |
| 4 | `mac_unit.v`, `nn.v`, `tb_nn.v` | 3-neuron neural network AI accelerator |

---

## Exercise 1 — 32-bit ALU

A combinational 32-bit signed ALU supporting 12 operations, selected via the 4-bit `alu_op` input.

| `alu_op` | Operation |
|----------|-----------|
| `1000` | Bitwise AND |
| `1001` | Bitwise OR |
| `1010` | Bitwise NOR |
| `1011` | Bitwise NAND |
| `1100` | Bitwise XOR |
| `0100` | Signed Addition |
| `0101` | Signed Subtraction |
| `0110` | Signed Multiplication |
| `0000` | Logical Shift Right |
| `0001` | Logical Shift Left |
| `0010` | Arithmetic Shift Right |
| `0011` | Arithmetic Shift Left |

**Overflow detection:** Addition and subtraction use sign-bit analysis; multiplication stores the full 64-bit product (`fullprod`) and checks whether the upper 32 bits are a sign extension of the lower 32 bits.

---

## Exercise 2 — 16-bit Calculator

A clocked calculator circuit built around the ALU from Exercise 1. It maintains a 16-bit accumulator register updated on each button press.

**Key components:**
- `calc.v` — top-level module with the accumulator and ALU instantiation
- `calc_enc.v` — structural Verilog encoder that maps three buttons (`btnl`, `btnr`, `btnd`) to a 4-bit `alu_op` signal using gate primitives (`not`, `and`, `or`, `xor`)
- `calc_tb.v` — testbench verifying 9 sequential operations (ADD, XOR, LSR, NOR, MUL, LSL, NAND, SUB) against expected results; all 9 pass

**Signal flow:**

```
sw[15:0] ──► Sign Extend ──► op2 ─┐
                                   ├──► ALU ──► result[15:0] ──► accumulator ──► led
accumulator ─► Sign Extend ──► op1 ┘
                    ▲                                                  │
                    └──────────────────────────────────────────────────┘
btnl, btnr, btnd ──► calc_enc ──► alu_op
```

---

## Exercise 3 — Register File

A parameterised 16×DATAWIDTH-bit register file (`DATAWIDTH` defaults to 32) with:
- **2 write ports** and **4 read ports**
- **Synchronous write**, **asynchronous read**
- **Active-low asynchronous reset** (`resetn`)
- **Write-first forwarding**: if a read address matches an active write address, the new write data is forwarded directly to the read output

---

## Exercise 4 — Neural Network AI Accelerator

A 3-neuron feedforward neural network implemented as a **Moore FSM** with 7 states. Weights and biases are loaded from ROM into the register file at startup and reused across all subsequent inferences.

### Architecture

```
input_1 ──► Right Shift (ALU) ──► inter_1 ──► Neuron 1 (MAC) ──► inter_3 ─┐
                                                                             ├──► Neuron 3 (MAC) ──► Left Shift (ALU) ──► output
input_2 ──► Right Shift (ALU) ──► inter_2 ──► Neuron 2 (MAC) ──► inter_4 ─┘
```

Each neuron computes: `output = input × weight + bias`

### FSM States

| State | Description |
|-------|-------------|
| `DEACTIVATED` (000) | Idle, waiting for first `enable` pulse |
| `LOADING_WEIGHTS_AND_BIASES` (001) | Reads ROM → register file (runs once) |
| `PRE_PROCESSING_LAYER` (010) | Parallel arithmetic right shift on both inputs |
| `INPUT_LAYER` (011) | Parallel MAC on both neurons (Neuron 1 & 2) |
| `OUTPUT_LAYER` (100) | Sequential MAC for Neuron 3: `inter_3 × w3 + inter_4 × w4 + bias_3` |
| `POST_PROCESSING_LAYER` (101) | Arithmetic left shift on final result |
| `IDLE` (110) | Output valid; waits for next `enable` |

**Overflow handling:** Any overflow in any stage immediately transitions the FSM to `IDLE` and sets the output to the maximum positive 32-bit value (`0x7FFFFFFF`). The stage where overflow occurred is recorded in `ovf_fsm_stage`.

### MAC Unit

`mac_unit.v` chains two ALU instances in series:
```
op1 × op2  ──► ALU₁ (MUL) ──► intermediate ──► ALU₂ (ADD, +op3) ──► total_result
```

### Testbench (`tb_nn.v`)

- 100 iterations × 3 test cases each = **300 total tests**, all passing
- Test case 1: random inputs in `[-4096, 4095]` (normal operation)
- Test case 2: large positive inputs (positive overflow check)
- Test case 3: large negative inputs (negative overflow check)
- Results are compared against the reference `nn_model` function

---

## Project Structure

```
.
├── alu.v           # 32-bit ALU (combinational, 12 operations)
├── calc.v          # 16-bit calculator with accumulator
├── calc_enc.v      # Button-to-ALU-op encoder (structural Verilog)
├── calc_tb.v       # Calculator testbench
├── regfile.v       # 16×32-bit register file (2W / 4R ports)
├── mac_unit.v      # Multiply-Accumulate unit (2× ALU in series)
├── nn.v            # Neural network AI accelerator (Moore FSM)
├── nn_model.v      # Reference model for testbench verification
├── rom.v           # ROM for storing weights and biases
├── rom_bytes.data  # Binary weight/bias data loaded by ROM
└── tb_nn.v         # Neural network testbench (300 test cases)
```

---

## Simulation

The project is designed for simulation with **Questa**. To simulate the calculator testbench:

```bash
# Compile
vlog src/alu.v src/calc_enc.v src/calc.v tb/calc_tb.v

# Run
vsim -c calc_tb -do "run -all; quit"
```

To simulate the neural network testbench:

```bash
# Compile
vlog src/alu.v src/regfile.v src/rom.v src/mac_unit.v src/nn.v tb/nn_model.v tb/tb_nn.v

# Run
vsim -c tb_nn -do "run -all; quit"
```

---

## Platform

Developed and tested with **Questa**.
