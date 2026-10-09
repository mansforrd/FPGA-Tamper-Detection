`timescale 1ns/1ps

module tb_event_fifo;

    reg clk = 0;
    reg rst_n = 0;
    reg [31:0] in_data = 0;
    reg in_valid = 0;
    wire in_ready;
    wire [31:0] out_data;
    wire out_valid;
    reg out_ready = 0;
    wire overflow;

    event_fifo #(.WIDTH(32), .ADDR_WIDTH(2)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(in_data),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .out_data(out_data),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .overflow(overflow)
    );

    always #5 clk = ~clk;

    initial begin
        #11 rst_n = 1;

        @(negedge clk) in_data = 32'h11111111;
        in_valid = 1;
        @(negedge clk) in_data = 32'h22222222;
        @(negedge clk) in_valid = 0;

        if (!out_valid || out_data !== 32'h11111111)
            $fatal(1, "first FIFO value failed");

        @(negedge clk) out_ready = 1;
        @(posedge clk);
        #1;
        if (!out_valid || out_data !== 32'h22222222)
            $fatal(1, "second FIFO value failed");

        @(posedge clk);
        #1;
        if (out_valid || overflow)
            $fatal(1, "FIFO drain failed");

        $display("PASS event_fifo");
        $finish;
    end

endmodule
