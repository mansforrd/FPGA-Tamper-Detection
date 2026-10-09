`timescale 1ns/1ps

module tb_packetizer;

    reg clk = 0;
    reg rst_n = 0;
    reg payload_valid = 0;
    reg byte_ready = 1;
    reg [31:0] payload = 32'h11223344;
    wire [7:0] byte_out;
    wire byte_valid;
    reg [7:0] received [0:6];
    integer count = 0;

    packetizer dut (
        .clk(clk), .rst_n(rst_n), .payload(payload),
        .payload_valid(payload_valid), .byte_out(byte_out),
        .byte_valid(byte_valid), .byte_ready(byte_ready)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (byte_valid) begin
            received[count] = byte_out;
            count = count + 1;
        end
    end

    initial begin
        #11 rst_n = 1;
        @(negedge clk) payload_valid = 1;
        @(negedge clk) payload_valid = 0;
        wait(count == 7);
        #1;

        if (received[0] !== 8'ha5 || received[1] !== 8'h11 ||
            received[2] !== 8'h22 || received[3] !== 8'h33 ||
            received[4] !== 8'h44)
            $fatal(1, "payload frame failed");
        if ({received[5], received[6]} === 16'h0000)
            $fatal(1, "CRC absent");

        $display("PASS packetizer");
        $finish;
    end

endmodule
