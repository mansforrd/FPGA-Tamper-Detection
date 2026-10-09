`timescale 1ns/1ps

module tb_comparator;

    reg [11:0] value;
    reg [11:0] high_threshold;
    reg [11:0] low_threshold;
    wire high_alarm;
    wire low_alarm;

    comparator #(.WIDTH(12)) dut (
        .value(value),
        .high_threshold(high_threshold),
        .low_threshold(low_threshold),
        .high_alarm(high_alarm),
        .low_alarm(low_alarm)
    );

    initial begin
        high_threshold = 12'd900;
        low_threshold  = 12'd100;
        value          = 12'd500;
        #1;
        if (high_alarm || low_alarm)
            $fatal(1, "midrange alarm");

        value = 12'd900;
        #1;
        if (!high_alarm)
            $fatal(1, "high threshold failed");

        value = 12'd100;
        #1;
        if (!low_alarm)
            $fatal(1, "low threshold failed");

        $display("PASS comparator");
        $finish;
    end

endmodule
