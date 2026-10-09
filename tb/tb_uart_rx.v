`timescale 1ns/1ps

module tb_uart_rx;

    localparam CLKS_PER_BIT = 4;

    reg clk = 0;
    reg rst_n = 0;
    reg rx = 1;
    wire [7:0] data;
    wire valid;
    wire frame_error;
    integer i;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .data(data),
        .valid(valid),
        .frame_error(frame_error)
    );

    always #5 clk = ~clk;

    task send_byte;
        input [7:0] value;
        begin
            rx = 0;
            repeat (CLKS_PER_BIT) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                rx = value[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end
            rx = 1;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    initial begin
        #11 rst_n = 1;
        @(negedge clk);
        send_byte(8'ha5);
        wait(valid);
        #1;
        if (data !== 8'ha5 || frame_error)
            $fatal(1, "UART receive failed");

        $display("PASS uart_rx");
        $finish;
    end

endmodule
