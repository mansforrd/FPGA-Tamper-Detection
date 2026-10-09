# Tamper telemetry RTL

Core, synthesizable RTL for the following datapath:

`sensor -> comparator -> dwc_logic -> tamper_decision -> fault_aggregator -> failsafe_mux -> lockout_fsm`

Accepted telemetry follows `event_manager -> packetizer (+ CRC-16) -> aes128 -> uart_tx`.
The PUF path is `ro_puf -> puf_authenticator -> aes_key_manager -> aes128`.

The PUF module is a digital wrapper around hardware ring-oscillator counters.  Ring oscillators and DPR/ICAP primitives are board/Vivado-flow specific and deliberately are not instantiated in this portable core.

Run the checks (requires Icarus Verilog): `make test`.
