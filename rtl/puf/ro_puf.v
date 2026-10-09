module ro_puf #(
	parameter WIDTH=128)
 (
    input wire clk,
    input wire rst_n,
    input wire sample_valid,
    input wire [WIDTH-1:0] ring_count_lsb,
    input wire [WIDTH-1:0] challenge,
    output reg [WIDTH-1:0] response,
    output reg response_valid
);
    always @(posedge clk or negedge rst_n)
      if(!rst_n) begin response<=0;
	 response_valid<=0;
 end
      else begin response_valid<=sample_valid;
	 if(sample_valid) response<=ring_count_lsb^challenge;
 end
endmodule
