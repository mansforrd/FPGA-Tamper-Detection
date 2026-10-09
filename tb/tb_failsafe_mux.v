`timescale 1ns/1ps

module tb_failsafe_mux;

    reg fault_active;
    reg allow_fault_telemetry;
    reg normal_tx;
    reg safe_tx_level;
    wire uart_tx;

    failsafe_mux dut (
        .fault_active(fault_active),
        .allow_fault_telemetry(allow_fault_telemetry),
        .normal_tx(normal_tx),
        .safe_tx_level(safe_tx_level),
        .uart_tx(uart_tx)
    );

    initial begin
        fault_active = 0;
        allow_fault_telemetry = 0;
        normal_tx = 0;
        safe_tx_level = 1;
        #1;
        if (uart_tx !== 0)
            $fatal(1, "normal route failed");

        fault_active = 1;
        #1;
        if (uart_tx !== 1)
            $fatal(1, "safe override failed");

        allow_fault_telemetry = 1;
        #1;
        if (uart_tx !== 0)
            $fatal(1, "telemetry grace failed");

        $display("PASS failsafe_mux");
        $finish;
    end

endmodule
