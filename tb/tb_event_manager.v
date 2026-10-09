`timescale 1ns/1ps

module tb_event_manager;

    reg clk = 0;
    reg rst_n = 0;
    reg event_pulse = 0;
    reg [3:0] fault_status = 4'h5;
    reg [11:0] sensor_value = 12'habc;
    wire event_valid;
    wire [31:0] event_word;

    event_manager dut (
        .clk(clk), .rst_n(rst_n), .event_pulse(event_pulse),
        .fault_status(fault_status), .sensor_value(sensor_value),
        .event_valid(event_valid), .event_word(event_word)
    );

    always #5 clk = ~clk;

    initial begin
        #11 rst_n = 1;
        @(negedge clk) event_pulse = 1;
        @(posedge clk);
        #1;
        if (!event_valid || event_word !== 32'ha5abc000)
            $fatal(1, "encoding failed: %h", event_word);

        @(negedge clk) event_pulse = 0;
        @(posedge clk);
        #1;
        if (event_valid)
            $fatal(1, "valid stuck");

        $display("PASS event_manager");
        $finish;
    end

endmodule
