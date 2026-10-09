`timescale 1ns/1ps

module tb_lockout_fsm;

    reg clk = 0;
    reg rst_n = 0;
    reg fault_active = 0;
    reg authenticated_clear = 0;
    wire locked;
    wire [31:0] remaining_cycles;

    lockout_fsm #(.LOCKOUT_CYCLES(3)) dut (
        .clk(clk), .rst_n(rst_n), .fault_active(fault_active),
        .authenticated_clear(authenticated_clear), .locked(locked),
        .remaining_cycles(remaining_cycles)
    );

    always #5 clk = ~clk;

    initial begin
        #11 rst_n = 1;
        @(negedge clk) fault_active = 1;
        @(posedge clk);
        #1;
        if (!locked || remaining_cycles != 3)
            $fatal(1, "entry failed");

        @(negedge clk) fault_active = 0;
        repeat (3) @(posedge clk);
        #1;
        if (remaining_cycles != 0 || !locked)
            $fatal(1, "countdown failed");

        @(negedge clk) authenticated_clear = 1;
        @(posedge clk);
        #1;
        if (locked)
            $fatal(1, "release failed");

        $display("PASS lockout_fsm");
        $finish;
    end

endmodule
