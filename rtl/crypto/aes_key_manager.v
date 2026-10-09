module aes_key_manager (
    input wire clk,
    input wire rst_n,
    input wire auth_valid,
    input wire auth_ok,
    input wire [127:0] puf_response,
    input wire [127:0] device_salt,
    output reg key_valid,
    output reg [127:0] aes_key
);
    always @(posedge clk or negedge rst_n)
      if(!rst_n) begin key_valid<=0;aes_key<=0;
end
      else if(auth_valid && auth_ok) begin aes_key<=puf_response^device_salt; key_valid<=1;
 end
endmodule
