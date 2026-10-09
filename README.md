# FPGA Tamper and Theft Detection System

This project is a simulation-verified Verilog design for detecting tamper and theft conditions in a prepaid electricity meter.

The design monitors two redundant sensor paths, checks that their decisions agree, locks the system when a fault is detected, and generates an encrypted UART alert. It also includes a receive-side CRC checker, a PUF-based key path, and fail-safe output control.

## What the design does

When both sensor channels agree that a monitored value is outside its allowed threshold range, the design:

1. Detects the tamper condition.
2. Records the fault in the fault aggregator.
3. Enters a lockout state.
4. Creates a telemetry event.
5. Queues the event before encryption.
6. Encrypts the event with AES-128.
7. Sends one encrypted UART alert frame.
8. Forces the UART output to its safe idle value after the alert frame finishes.

If the redundant channels disagree, the disagreement itself is treated as a fault.

## Main Features

- Dual redundant sensor threshold comparison
- Duplication-with-comparison (DWC) fault detection
- High and low threshold alarm detection
- Fault aggregation and sticky fault status
- FSM-based lockout
- Fail-safe UART output control
- RO-PUF response wrapper and authentication
- PUF-derived AES-128 key generation
- AES-128 encrypted telemetry
- Event FIFO to avoid losing events while encryption is busy
- UART transmission and reception
- CRC-16/CCITT packet generation and validation
- Self-checking Verilog testbenches
- VCD waveform output for Surfer



## Architecture

```text
sensor_in   → comparator A ─┐
                            ├→ DWC → tamper decision → fault aggregator → lockout FSM
sensor_in_b → comparator B ─┘                              │
                                                           ├→ fail-safe UART mux
RO-PUF → PUF authenticator → AES key manager               │
                                                           └→ event manager → FIFO → AES → packetizer → UART TX

UART RX → UART receiver → packet checker → CRC fault ──────┘
```



## Repository Structure

```text
.
├── Makefile
├── README.md
├── rtl/
│   ├── top.v
│   ├── sensing/
│   │   ├── sensor.v
│   │   └── comparator.v
│   ├── safety/
│   │   ├── dwc_logic.v
│   │   ├── tamper_decision.v
│   │   ├── fault_aggregator.v
│   │   ├── failsafe_mux.v
│   │   └── lockout_fsm.v
│   ├── telemetry/
│   │   ├── event_manager.v
│   │   ├── event_fifo.v
│   │   ├── crc16.v
│   │   ├── packetizer128.v
│   │   ├── packet_checker128.v
│   │   ├── uart_tx.v
│   │   └── uart_rx.v
│   ├── crypto/
│   │   ├── aes128.v
│   │   └── aes_key_manager.v
│   └── puf/
│       ├── ro_puf.v
│       └── puf_authenticator.v
└── tb/
    └── Verilog testbenches
```

## DWC Operation

The system uses two comparator paths:
Comparator A result ─┐
                     XOR → mismatch
Comparator B result ─┘
There is one DWC checker for the high-threshold alarms and another for the low-threshold alarms.
assign mismatch = channel_a ^ channel_b;
assign voted_value = channel_a & channel_b;
A mismatch indicates that the redundant channels disagree. The two mismatch signals are combined using OR, so any disagreement raises a fault.

## Telemetry Frame

The encrypted UART packet format is:
0xA5 | 16 AES ciphertext bytes | CRC-16 high byte | CRC-16 low byte
0xA5 is the synchronization byte. CRC-16 detects accidental transmission errors.

## Requirements

- Icarus Verilog
- vvp
- Make
- Surfer waveform viewer
On macOS:
brew install icarus-verilog
brew install surfer

## Run All Tests

make test
This compiles and runs all unit and integration testbenches.

## Run the Full Integration Test

iverilog -g2012 -s tb_top -o sim \
  $(find rtl -type f -name '*.v' | sort) \
  tb/tb_top.v

vvp sim
Expected result:
PASS top integration; waveform: waves/top.vcd

## View the Waveform

surfer waves/top.vcd

## Verification Coverage

The test suite verifies:
- Sensor pass-through behavior
- Comparator high and low thresholds
- DWC agreement and mismatch detection
- Tamper decision latching
- Fault aggregation
- Fail-safe UART mux behavior
- Lockout FSM timing
- Event-manager packet generation
- Event FIFO operation
- CRC-16/CCITT calculation
- UART transmission and reception
- Packet CRC checking
- PUF response generation and authentication
- AES key derivation
- AES-128 FIPS-197 known-answer vector
- Full tamper-to-lockout telemetry flow

## Scope and Limitations

This project is verified through RTL simulation.
The following items require target-FPGA hardware work:
- Physical ring-oscillator PUF implementation
- PUF stability and uniqueness characterization
- Secure nonvolatile PUF enrollment storage
- FPGA pin and clock constraints
- Timing closure
- Configuration-memory fault injection
- DEFCON-style FPGA LUT and routing protection
- ICAP/DPR-based partial reconfiguration
- Real sensor and UART electrical validation

## Future Work

- Add message authentication, such as AES-GCM or a MAC
- Add FPGA configuration scrubbing
- Add fault diagnosis and controlled partial reconfiguration
- Implement persistent secure PUF enrollment storage
- Evaluate the design against DWC, TMR, and DEFCON-style fail-safe methods
- Perform hardware fault-injection experiments
