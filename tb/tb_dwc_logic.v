`timescale 1ns/1ps

module tb_dwc_logic;

    reg channel_a;
    reg channel_b;
    wire voted_value;
    wire mismatch;

    dwc_logic dut (
        .channel_a(channel_a),
        .channel_b(channel_b),
        .voted_value(voted_value),
        .mismatch(mismatch)
    );

    initial begin
        channel_a = 0;
        channel_b = 0;
        #1;
        if (mismatch || voted_value)
            $fatal(1, "00 failed");

        channel_a = 1;
        channel_b = 1;
        #1;
        if (mismatch || !voted_value)
            $fatal(1, "11 failed");

        channel_a = 1;
        channel_b = 0;
        #1;
        if (!mismatch || voted_value)
            $fatal(1, "mismatch failed");

        $display("PASS dwc_logic");
        $finish;
    end

endmodule
