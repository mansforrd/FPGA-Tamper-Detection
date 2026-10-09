module sensor #(
	parameter WIDTH = 12)
 (
    input wire [WIDTH-1:0] sensor_in,
    output reg [WIDTH-1:0] sensor_value
);
    always @* sensor_value = sensor_in;
endmodule
