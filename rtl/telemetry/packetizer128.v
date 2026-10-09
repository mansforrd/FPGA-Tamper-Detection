module packetizer128 (
    input wire clk,
    input wire rst_n,
    input wire [127:0] payload,
    input wire payload_valid,
    output reg [7:0] byte_out,
    output reg byte_valid,
    input wire byte_ready,
    output wire frame_active
);

    reg [4:0] index;
    reg active;
    reg [127:0] saved;
    reg [15:0] crc;

    function [15:0] crc_next;
        input [15:0] crc_in;
        input [7:0] data;
        integer i;
        reg [15:0] value;
        begin
            value = crc_in ^ {data, 8'h00};
            for (i = 0; i < 8; i = i + 1)
                if (value[15])
                    value = (value << 1) ^ 16'h1021;
                else
                    value = value << 1;
            crc_next = value;
        end
    endfunction

    function [7:0] payload_byte;
        input [127:0] data;
        input [3:0] byte_index;
        begin
            payload_byte = data[127 - byte_index * 8 -: 8];
        end
    endfunction

    assign frame_active = active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            index <= 0;
            active <= 0;
            byte_valid <= 0;
            byte_out <= 0;
            saved <= 0;
            crc <= 16'hffff;
        end else begin
            byte_valid <= 0;

            if (!active && payload_valid) begin
                active <= 1;
                index <= 0;
                saved <= payload;
                crc <= 16'hffff;
            end

            if (active && byte_ready) begin
                byte_valid <= 1;

                if (index == 0) begin
                    byte_out <= 8'ha5;
                end else if (index <= 16) begin
                    byte_out <= payload_byte(saved, index - 1'b1);
                    crc <= crc_next(crc, payload_byte(saved, index - 1'b1));
                end else if (index == 17) begin
                    byte_out <= crc[15:8];
                end else begin
                    byte_out <= crc[7:0];
                    active <= 0;
                end

                index <= index + 1'b1;
            end
        end
    end

endmodule
