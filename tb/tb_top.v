`timescale 1ns/1ps

module tb_top;

    reg clk = 0;
    reg rst_n = 0;
    reg [11:0] sensor_in = 12'd500;
    reg [11:0] sensor_in_b = 12'd500;
    reg [11:0] high_threshold = 12'd900;
    reg [11:0] low_threshold = 12'd100;
    reg puf_sample_valid = 0;
    reg puf_enroll = 0;
    reg [127:0] ring_count_lsb = 0;
    reg [127:0] puf_challenge = 128'h5a;
    reg [127:0] enrolled_response = 128'h5a;
    reg [127:0] device_salt = 128'h3c;
    reg uart_rx = 1;
    reg service_clear = 0;
    reg authenticated_clear = 0;
    wire uart_tx;
    wire locked;

    top #(.UART_CLKS_PER_BIT(2)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .sensor_in(sensor_in),
        .sensor_in_b(sensor_in_b),
        .high_threshold(high_threshold),
        .low_threshold(low_threshold),
        .puf_sample_valid(puf_sample_valid),
        .puf_enroll(puf_enroll),
        .ring_count_lsb(ring_count_lsb),
        .puf_challenge(puf_challenge),
        .enrolled_response(enrolled_response),
        .device_salt(device_salt),
        .uart_rx(uart_rx),
        .service_clear(service_clear),
        .authenticated_clear(authenticated_clear),
        .uart_tx(uart_tx),
        .locked(locked)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waves/top.vcd");
        $dumpvars(0, tb_top);

        #11 rst_n = 1;
        @(negedge clk) puf_sample_valid = 1;
        @(negedge clk) puf_sample_valid = 0;
        repeat (3) @(posedge clk);
        #1;
        if (!dut.key_valid)
            $fatal(1, "PUF-derived AES key not installed");

        @(negedge clk) sensor_in = 12'd950;
        sensor_in_b = 12'd950;
        repeat (3) @(posedge clk);
        #1;
        if (!locked || !dut.fault_active)
            $fatal(1, "tamper did not lock system");

        wait(dut.aes_valid);
        #1;
        if (dut.ciphertext === 0)
            $fatal(1, "AES did not encrypt event");
        wait(dut.raw_uart == 1'b0);
        #1;
        if (uart_tx !== 1'b0)
            $fatal(1, "telemetry grace did not pass UART start bit");

        wait(!dut.telemetry_grace);
        #1;
        if (uart_tx !== 1'b1)
            $fatal(1, "failsafe UART level incorrect");

        $display("PASS top integration; waveform: waves/top.vcd");
        #20;
        $finish;
    end

endmodule
