`timescale 1ns/1ps

module tb_ro_puf;

    reg clk = 0;
    reg rst_n = 0;
    reg sample_valid = 0;
    reg [127:0] ring_count_lsb = 128'h1234;
    reg [127:0] challenge = 128'h00ff;
    wire [127:0] response;
    wire response_valid;

    ro_puf dut (
        .clk(clk), .rst_n(rst_n), .sample_valid(sample_valid),
        .ring_count_lsb(ring_count_lsb), .challenge(challenge),
        .response(response), .response_valid(response_valid)
    );

    always #5 clk = ~clk;

    initial begin
        #11 rst_n = 1;
        @(negedge clk) sample_valid = 1;
        @(posedge clk);
        #1;
        if (!response_valid || response !== (ring_count_lsb ^ challenge))
            $fatal(1, "PUF response failed");

        $display("PASS ro_puf");
        $finish;
    end

endmodule
