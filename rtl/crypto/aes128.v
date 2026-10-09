module aes128 (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [127:0] plaintext,
    input wire [127:0] key,
    output reg busy,
    output reg valid,
    output reg [127:0] ciphertext
);
    reg [127:0] state, round_key;
    reg [3:0] round;
    function [7:0] gm; input [7:0] a; input [7:0] b; integer i; reg [7:0] x,y,p; begin
      x=a;y=b;p=0; for(i=0;i<8;i=i+1) begin if(y[0])p=p^x; x=x[7]?(x<<1)^8'h1b:x<<1; y=y>>1; end gm=p;
    end
 endfunction
    function [7:0] sb; input [7:0] a; integer i; reg [7:0] p,inv,t; begin
      p=8'h01; t=a; for(i=0;i<8;i=i+1) begin if((8'hfe>>i)&1) p=gm(p,t); t=gm(t,t);
 end inv=p;
      sb = inv ^ {inv[6:0],inv[7]} ^ {inv[5:0],inv[7:6]} ^ {inv[4:0],inv[7:5]} ^ {inv[3:0],inv[7:4]} ^ 8'h63;
    end
 endfunction
    function [127:0] sub_bytes; input [127:0] x; integer i; reg [127:0] y; begin
      for(i=0;i<16;i=i+1) y[127-i*8 -: 8]=sb(x[127-i*8 -: 8]); sub_bytes=y;
    end
 endfunction
    function [127:0] shift_rows; input [127:0] x; reg [7:0] b[0:15]; reg [7:0] y[0:15]; integer i,r,c; reg [127:0] z; begin
      for(i=0;i<16;i=i+1) b[i]=x[127-i*8 -: 8];
      for(c=0;c<4;c=c+1) for(r=0;r<4;r=r+1) y[4*c+r]=b[4*((c+r)%4)+r];
      for(i=0;i<16;i=i+1) z[127-i*8 -: 8]=y[i]; shift_rows=z;
    end
 endfunction
    function [127:0] mix_columns; input [127:0] x; reg [7:0] b[0:15]; reg [7:0] y[0:15]; integer i,c; reg [127:0] z; begin
      for(i=0;i<16;i=i+1) b[i]=x[127-i*8 -: 8];
      for(c=0;c<4;c=c+1) begin
        y[4*c]=gm(b[4*c],2)^gm(b[4*c+1],3)^b[4*c+2]^b[4*c+3];
        y[4*c+1]=b[4*c]^gm(b[4*c+1],2)^gm(b[4*c+2],3)^b[4*c+3];
        y[4*c+2]=b[4*c]^b[4*c+1]^gm(b[4*c+2],2)^gm(b[4*c+3],3);
        y[4*c+3]=gm(b[4*c],3)^b[4*c+1]^b[4*c+2]^gm(b[4*c+3],2);
      end
      for(i=0;i<16;i=i+1) z[127-i*8 -: 8]=y[i]; mix_columns=z;
    end
 endfunction
    function [127:0] next_key; input [127:0] k; input [3:0] rn; reg [31:0] w0,w1,w2,w3,t; reg [7:0] rc; integer j; begin
      w0=k[127:96];w1=k[95:64];w2=k[63:32];w3=k[31:0]; rc=1;
      for(j=1;j<rn;j=j+1) rc=gm(rc,2);
      t={sb(w3[23:16]),sb(w3[15:8]),sb(w3[7:0]),sb(w3[31:24])}^{rc,24'h0};
      w0=w0^t;w1=w1^w0;w2=w2^w1;w3=w3^w2; next_key={w0,w1,w2,w3};
    end
 endfunction
    reg [127:0] nk, transformed;
    always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin busy<=0;valid<=0;ciphertext<=0;state<=0;round_key<=0;round<=0;
 end
      else begin
        valid<=0;
        if(!busy && start) begin state<=plaintext^key; round_key<=key; round<=1; busy<=1;
 end
        else if(busy) begin
          nk=next_key(round_key,round);
          transformed=shift_rows(sub_bytes(state));
          if(round==10) begin ciphertext<=transformed^nk; state<=transformed^nk; busy<=0;valid<=1;
 end
          else begin state<=mix_columns(transformed)^nk; round_key<=nk; round<=round+1'b1;
 end
        end
      end
    end
endmodule
