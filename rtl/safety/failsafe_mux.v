module failsafe_mux (
    input wire fault_active,
    input wire allow_fault_telemetry,
    input wire normal_tx,
    input wire safe_tx_level,
    output wire uart_tx
);

    assign uart_tx = (fault_active && !allow_fault_telemetry) ?
                     safe_tx_level : normal_tx;

endmodule
