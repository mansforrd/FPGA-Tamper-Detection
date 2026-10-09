module packet_checker128 (
    input wire clk,
    input wire rst_n,
    input wire [7:0] byte_in,
    input wire byte_valid,
    output reg crc_fault,
    output reg packet_valid,
    output reg [127:0] payload
);

    localparam WAIT_SYNC = 2'd0;
    localparam READ_PAYLOAD = 2'd1;
    localparam READ_CRC_HIGH = 2'd2;
    localparam READ_CRC_LOW = 2'd3;

    reg [1:0] state;
    reg [4:0] index;
    reg [15:0] crc;
    reg [15:0] received_crc;

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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= WAIT_SYNC;
            index <= 0;
            crc <= 16'hffff;
            received_crc <= 0;
            payload <= 0;
            crc_fault <= 0;
            packet_valid <= 0;
        end else begin
            crc_fault <= 0;
            packet_valid <= 0;

            if (byte_valid) begin
                case (state)
                    WAIT_SYNC: begin
                        if (byte_in == 8'ha5) begin
                            index <= 0;
                            crc <= 16'hffff;
                            state <= READ_PAYLOAD;
                        end
                    end

                    READ_PAYLOAD: begin
                        payload[127 - index * 8 -: 8] <= byte_in;
                        crc <= crc_next(crc, byte_in);
                        if (index == 5'd15)
                            state <= READ_CRC_HIGH;
                        else
                            index <= index + 1'b1;
                    end

                    READ_CRC_HIGH: begin
                        received_crc[15:8] <= byte_in;
                        state <= READ_CRC_LOW;
                    end

                    READ_CRC_LOW: begin
                        received_crc[7:0] <= byte_in;
                        if ({received_crc[15:8], byte_in} == crc)
                            packet_valid <= 1;
                        else
                            crc_fault <= 1;
                        state <= WAIT_SYNC;
                    end

                    default: state <= WAIT_SYNC;
                endcase
            end
        end
    end

endmodule
