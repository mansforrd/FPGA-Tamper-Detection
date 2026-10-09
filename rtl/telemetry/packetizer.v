module packetizer (
    input wire clk,
    input wire rst_n,
    input wire [31:0] payload,
    input wire payload_valid,
    output reg [7:0] byte_out,
    output reg byte_valid,
    input wire byte_ready
);
    reg [2:0] index;
    reg active;
    reg [31:0] saved;
    reg [15:0] crc;
    function [15:0] crc_next;
    input [15:0] ci;
    input [7:0] d;
    integer j;
    reg [15:0] x;
 begin
        x=ci^{d,8'h00};
 for(j=0;j<8;j=j+1) if(x[15]) x=(x<<1)^16'h1021;
 else x=x<<1; crc_next=x;
    end
 endfunction
    function [7:0] payload_byte;
    input [31:0] p;
    input [1:0] n;
 begin
        case(n) 0:payload_byte=p[31:24];
 1:payload_byte=p[23:16];
 2:payload_byte=p[15:8];
 default:payload_byte=p[7:0];
 endcase
    end
 endfunction
    always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin index<=0; active<=0; byte_valid<=0; byte_out<=0; saved<=0; crc<=16'hffff;
 end
      else begin
        byte_valid<=0;
        if(!active && payload_valid) begin active<=1; index<=0; saved<=payload; crc<=16'hffff;
 end
        if(active && byte_ready) begin
          byte_valid<=1;
          case(index)
            0: byte_out<=8'ha5;
            1,2,3,4: begin byte_out<=payload_byte(saved,index-1);
	    crc<=crc_next(crc,payload_byte(saved,index-1));
 end
            5: byte_out<=crc[15:8];
            6: begin byte_out<=crc[7:0]; active<=0;
 end
          endcase
          index<=index+1'b1;
        end
      end
    end
endmodule
