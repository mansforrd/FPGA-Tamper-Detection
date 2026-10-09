module uart_tx #(
	parameter CLKS_PER_BIT = 16)
 (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data,
    input wire valid,
    output wire ready,
    output reg tx,
    output reg busy
);
    reg [9:0] shifter; reg [15:0] count;
    reg [3:0] bit_index;
    assign ready = !busy;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin tx <= 1'b1; busy <= 1'b0;
	 count <= 0;
	bit_index <= 0;
		shifter <= 10'h3ff;
 end
        else if (!busy) begin
            tx <= 1'b1;
            if (valid) begin busy <= 1'b1;
	 shifter <= {1'b1,data,1'b0};
	 tx <= 1'b0;
	 count <= 0;
	 bit_index <= 0;
 end
        end else if (count == CLKS_PER_BIT-1) begin
            count <= 0;
            if (bit_index == 4'd9) begin busy <= 1'b0;
	 tx <= 1'b1;
 end
            else begin bit_index <= bit_index + 1'b1;
		 shifter <= {1'b1,shifter[9:1]};
			 tx <= shifter[1];
 end
        end else count <= count + 1'b1;
    end
endmodule
