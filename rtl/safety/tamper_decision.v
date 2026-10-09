module tamper_decision (
    input wire clk,
    input wire rst_n,
    input wire high_alarm,
    input wire low_alarm,
    input wire dwc_mismatch,
    input wire clear,
    output reg tamper,
    output reg event_pulse
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin tamper <= 1'b0; event_pulse <= 1'b0; end
        else begin
            event_pulse <= 1'b0;
            if (clear) tamper <= 1'b0;
            else if (high_alarm || low_alarm || dwc_mismatch) begin
                if (!tamper) event_pulse <= 1'b1;
                tamper <= 1'b1;
            end
        end
    end
endmodule
