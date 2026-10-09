module dwc_logic (
    input wire channel_a,
    input wire channel_b,
    output wire voted_value,
    output wire mismatch
);
    assign mismatch = channel_a ^ channel_b;
    assign voted_value = channel_a & channel_b;
endmodule
