module crc16 (
    input wire [7:0] data,
    input wire [15:0] crc_in,
    output reg [15:0] crc_out
);
    integer i;
    reg [15:0] c;
    always @* begin
        c = crc_in ^ {data, 8'h00};
        for (i=0; i<8; i=i+1)
            if (c[15]) c = (c << 1) ^ 16'h1021; else c = c << 1;
        crc_out = c;
    end
endmodule
