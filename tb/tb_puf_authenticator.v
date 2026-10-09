`timescale 1ns/1ps

module tb_puf_authenticator;

    reg clk = 0;
    reg rst_n = 0;
    reg response_valid = 0;
    reg enroll = 0;
    reg [127:0] response;
    reg [127:0] enrolled_response;
    wire auth_valid;
    wire auth_ok;
    wire auth_fail;

    puf_authenticator #(.MAX_BIT_ERRORS(2)) dut (
        .clk(clk), .rst_n(rst_n), .response_valid(response_valid),
        .response(response), .enroll(enroll), .enrolled_response(enrolled_response),
        .auth_valid(auth_valid), .auth_ok(auth_ok), .auth_fail(auth_fail)
    );

    always #5 clk = ~clk;

    initial begin
        enrolled_response = 128'h55;
        response = 128'h55;
        #11 rst_n = 1;
        @(negedge clk) response_valid = 1;
        @(posedge clk);
        #1;
        if (!auth_valid || !auth_ok || auth_fail)
            $fatal(1, "exact auth failed");

        @(negedge clk) response = 128'hff;
        @(posedge clk);
        #1;
        if (!auth_fail || auth_ok)
            $fatal(1, "reject failed");

        $display("PASS puf_authenticator");
        $finish;
    end

endmodule
