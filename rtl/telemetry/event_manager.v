module event_manager (
    input wire clk, input wire rst_n, input wire event_pulse,
    input wire [3:0] fault_status, input wire [11:0] sensor_value,
    output reg event_valid, output reg [31:0] event_word
);
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin event_valid <= 0; event_word <= 0;
 end
        else begin event_valid <= event_pulse; if (event_pulse) event_word <= {4'hA, fault_status, sensor_value, 12'h000};
 end
endmodule
