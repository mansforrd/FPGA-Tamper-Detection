`timescale 1ns/1ps

module tb_packet_checker128;

    reg clk = 0;
    reg rst_n = 0;
    reg [7:0] byte_in = 0;
    reg byte_valid = 0;
    wire crc_fault;
    wire packet_valid;
    wire [127:0] payload;
    reg [7:0] bytes [0:17];
    integer i;
    reg [15:0] crc;

    packet_checker128 dut (
        .clk(clk),
        .rst_n(rst_n),
        .byte_in(byte_in),
        .byte_valid(byte_valid),
        .crc_fault(crc_fault),
        .packet_valid(packet_valid),
        .payload(payload)
    );

    always #5 clk = ~clk;

    function [15:0] crc_next;
        input [15:0] crc_in;
        input [7:0] data;
        integer j;
        reg [15:0] value;
        begin
            value = crc_in ^ {data, 8'h00};
            for (j = 0; j < 8; j = j + 1)
                if (value[15])
                    value = (value << 1) ^ 16'h1021;
                else
                    value = value << 1;
            crc_next = value;
        end
    endfunction

    task send_byte;
        input [7:0] value;
        begin
            @(negedge clk) byte_in = value;
            byte_valid = 1;
            @(negedge clk) byte_valid = 0;
        end
    endtask

    initial begin
        for (i = 0; i < 16; i = i + 1)
            bytes[i] = i;

        crc = 16'hffff;
        for (i = 0; i < 16; i = i + 1)
            crc = crc_next(crc, bytes[i]);
        bytes[16] = crc[15:8];
        bytes[17] = crc[7:0];

        #11 rst_n = 1;
        send_byte(8'ha5);
        for (i = 0; i < 18; i = i + 1)
            send_byte(bytes[i]);

        #1;
        if (!packet_valid || payload !== 128'h000102030405060708090a0b0c0d0e0f)
            $fatal(1, "valid packet rejected");

        send_byte(8'ha5);
        for (i = 0; i < 17; i = i + 1)
            send_byte(bytes[i]);
        send_byte(bytes[17] ^ 8'h01);

        #1;
        if (!crc_fault)
            $fatal(1, "bad CRC accepted");

        $display("PASS packet_checker128");
        $finish;
    end

endmodule
