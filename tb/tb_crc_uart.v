`timescale 1ns/1ps

module tb_crc_uart;

    reg [7:0] data;
    reg [15:0] crc;
    wire [15:0] next_crc;
    reg clk = 0;
    reg rst_n = 0;
    reg valid = 0;
    reg [7:0] tx_data = 8'ha5;
    wire ready;
    wire tx;
    wire busy;

    crc16 u_crc (
        .data(data),
        .crc_in(crc),
        .crc_out(next_crc)
    );

    uart_tx #(.CLKS_PER_BIT(4)) u_uart (
        .clk(clk), .rst_n(rst_n), .data(tx_data), .valid(valid),
        .ready(ready), .tx(tx), .busy(busy)
    );

    always #5 clk = ~clk;

    initial begin
        data = 8'h31;
        crc = 16'hffff;
        #1 crc = next_crc; data = 8'h32;
        #1 crc = next_crc; data = 8'h33;
        #1 crc = next_crc; data = 8'h34;
        #1 crc = next_crc; data = 8'h35;
        #1 crc = next_crc; data = 8'h36;
        #1 crc = next_crc; data = 8'h37;
        #1 crc = next_crc; data = 8'h38;
        #1 crc = next_crc; data = 8'h39;
        #1;

        if (next_crc !== 16'h29b1)
            $fatal(1, "CRC mismatch %h", next_crc);

        #10 rst_n = 1;
        @(negedge clk) valid = 1;
        @(negedge clk) valid = 0;
        wait(!busy);
        if (tx !== 1'b1)
            $fatal(1, "UART idle bad");

        $display("PASS CRC-16/CCITT and UART completion");
        $finish;
    end

endmodule
