`timescale 1ns/1ps

module tb_fault_aggregator;

    reg clk = 0;
    reg rst_n = 0;
    reg tamper = 0;
    reg dwc_mismatch = 0;
    reg puf_auth_fail = 0;
    reg crc_fault = 0;
    reg service_clear = 0;
    wire fault_active;
    wire [3:0] fault_status;

    fault_aggregator dut (
        .clk(clk), .rst_n(rst_n), .tamper(tamper),
        .dwc_mismatch(dwc_mismatch), .puf_auth_fail(puf_auth_fail),
        .crc_fault(crc_fault), .service_clear(service_clear),
        .fault_active(fault_active), .fault_status(fault_status)
    );

    always #5 clk = ~clk;

    initial begin
        #11 rst_n = 1;
        @(negedge clk) dwc_mismatch = 1;
        @(posedge clk);
        #1;
        if (!fault_active || fault_status !== 4'b0100)
            $fatal(1, "DWC fault failed");

        @(negedge clk) dwc_mismatch = 0;
        puf_auth_fail = 1;
        @(posedge clk);
        #1;
        if (fault_status !== 4'b0110)
            $fatal(1, "aggregation failed");

        @(negedge clk) service_clear = 1;
        @(posedge clk);
        #1;
        if (fault_active || fault_status)
            $fatal(1, "clear failed");

        $display("PASS fault_aggregator");
        $finish;
    end

endmodule
