`timescale 1ns/1ps

module tb_decision;

    reg clk = 0;
    reg rst_n = 0;
    reg high_alarm = 0;
    reg low_alarm = 0;
    reg mismatch = 0;
    reg clear = 0;
    wire tamper;
    wire event_pulse;

    tamper_decision dut (
        .clk(clk), .rst_n(rst_n), .high_alarm(high_alarm),
        .low_alarm(low_alarm), .dwc_mismatch(mismatch), .clear(clear),
        .tamper(tamper), .event_pulse(event_pulse)
    );

    always #5 clk = ~clk;

    initial begin
        #11 rst_n = 1;
        @(negedge clk) high_alarm = 1;
        @(posedge clk);
        #1;
        if (!tamper || !event_pulse)
            $fatal(1, "alarm did not latch/event");

        @(negedge clk) high_alarm = 0;
        @(posedge clk);
        #1;
        if (event_pulse)
            $fatal(1, "event repeated");

        @(negedge clk) clear = 1;
        @(posedge clk);
        #1;
        if (tamper)
            $fatal(1, "clear failed");

        $display("PASS tamper decision");
        $finish;
    end

endmodule
