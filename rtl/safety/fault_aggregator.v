module fault_aggregator (
    input wire clk,
    input wire rst_n,
    input wire tamper,
    input wire dwc_mismatch,
    input wire puf_auth_fail,
    input wire crc_fault,
    input wire service_clear,
    output reg fault_active,
    output reg [3:0] fault_status
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin fault_active <= 1'b0; fault_status <= 4'b0;
 end
        else if (service_clear) begin fault_active <= 1'b0; fault_status <= 4'b0;
 end
        else begin
            if (tamper || dwc_mismatch || puf_auth_fail || crc_fault) fault_active <= 1'b1;
            fault_status <= fault_status | {tamper, dwc_mismatch, puf_auth_fail, crc_fault};
        end
    end
endmodule
