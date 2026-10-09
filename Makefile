IVERILOG ?= iverilog
VVP ?= vvp
RTL := $(shell find rtl -type f -name '*.v' | sort)
TESTS := aes128 crc_uart sensor comparator dwc_logic tamper_decision fault_aggregator failsafe_mux lockout_fsm event_manager event_fifo uart_rx packet_checker128 packetizer packetizer128 ro_puf puf_authenticator aes_key_manager top

test: $(addprefix test_,$(TESTS))

test_%: waves tb/tb_%.v $(RTL)
	$(IVERILOG) -g2012 -s tb_$* -o build_$* $(RTL) tb/tb_$*.v
	$(VVP) build_$*

waves:
	mkdir -p waves

wave: test_top
view: wave
	surfer waves/top.vcd &

clean:
	rm -f $(addprefix build_,$(TESTS))

.PHONY: test waves wave view clean
