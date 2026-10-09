`timescale 1ns/1ps

module tb_aes128;

    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;
    reg [127:0] plaintext;
    reg [127:0] key;
    wire busy;
    wire valid;
    wire [127:0] ciphertext;

    aes128 dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .plaintext(plaintext),
        .key(key),
        .busy(busy),
        .valid(valid),
        .ciphertext(ciphertext)
    );

    always #5 clk = ~clk;

    initial begin
        plaintext = 128'h00112233445566778899aabbccddeeff;
        key       = 128'h000102030405060708090a0b0c0d0e0f;

        #12 rst_n = 1;
        @(negedge clk) start = 1;
        @(negedge clk) start = 0;
        wait(valid);
        #1;

        if (ciphertext !== 128'h69c4e0d86a7b0430d8cdb78070b4c55a)
            $fatal(1, "AES mismatch: %h", ciphertext);

        $display("PASS aes128 FIPS-197 vector");
        $finish;
    end

endmodule
