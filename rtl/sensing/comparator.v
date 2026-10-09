module comparator #(
	parameter WIDTH = 12)
 (
    input wire [WIDTH-1:0] value,
    input wire [WIDTH-1:0] high_threshold,
    input wire [WIDTH-1:0] low_threshold,
    output wire high_alarm,
    output wire low_alarm
);
    assign high_alarm = (value >= high_threshold);
    assign low_alarm  = (value <= low_threshold);
endmodule
