`timescale 1ns/1ps

module tb_aes_key_manager;

    reg clk = 0;
    reg rst_n = 0;
    reg valid = 0;
    reg ok = 0;
    reg [127:0] response = 128'h1234;
    reg [127:0] salt = 128'h00ff;
    wire key_valid;
    wire [127:0] key;

    aes_key_manager dut (
        .clk(clk),
        .rst_n(rst_n),
        .auth_valid(valid),
        .auth_ok(ok),
        .puf_response(response),
        .device_salt(salt),
        .key_valid(key_valid),
        .aes_key(key)
    );

    always #5 clk = ~clk;

    initial begin
        #11 rst_n = 1;
        @(negedge clk) valid = 1;
        ok = 1;
        @(posedge clk);
        #1;

        if (!key_valid || key !== (response ^ salt))
            $fatal(1, "key derivation failed");

        $display("PASS aes_key_manager");
        $finish;
    end

endmodule
