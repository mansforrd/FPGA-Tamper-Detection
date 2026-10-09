`timescale 1ns/1ps

module tb_packetizer128;

    reg clk = 0;
    reg rst_n = 0;
    reg payload_valid = 0;
    reg byte_ready = 1;
    reg [127:0] payload = 128'h00112233445566778899aabbccddeeff;
    wire [7:0] byte_out;
    wire byte_valid;
    reg [7:0] received [0:18];
    integer count = 0;

    packetizer128 dut (
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
        wait(count == 19);
        #1;

        if (received[0] !== 8'ha5 || received[1] !== 8'h00 ||
            received[16] !== 8'hff)
            $fatal(1, "ciphertext frame failed");
        if ({received[17], received[18]} === 16'h0000)
            $fatal(1, "CRC absent");

        $display("PASS packetizer128");
        $finish;
    end

endmodule
