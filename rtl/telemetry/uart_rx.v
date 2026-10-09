module uart_rx #(
    parameter CLKS_PER_BIT = 16
) (
    input wire clk,
    input wire rst_n,
    input wire rx,
    output reg [7:0] data,
    output reg valid,
    output reg frame_error
);

    localparam IDLE = 2'd0;
    localparam START = 2'd1;
    localparam DATA = 2'd2;
    localparam STOP = 2'd3;

    reg [1:0] state;
    reg [15:0] count;
    reg [2:0] bit_index;
    reg [7:0] shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            count <= 0;
            bit_index <= 0;
            shift <= 0;
            data <= 0;
            valid <= 0;
            frame_error <= 0;
        end else begin
            valid <= 0;
            frame_error <= 0;

            case (state)
                IDLE: begin
                    count <= 0;
                    if (!rx)
                        state <= START;
                end

                START: begin
                    if (count == (CLKS_PER_BIT / 2) - 1) begin
                        count <= 0;
                        if (!rx) begin
                            bit_index <= 0;
                            state <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        count <= count + 1'b1;
                    end
                end

                DATA: begin
                    if (count == CLKS_PER_BIT - 1) begin
                        count <= 0;
                        shift[bit_index] <= rx;
                        if (bit_index == 3'd7)
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1'b1;
                    end else begin
                        count <= count + 1'b1;
                    end
                end

                STOP: begin
                    if (count == CLKS_PER_BIT - 1) begin
                        count <= 0;
                        state <= IDLE;
                        if (rx) begin
                            data <= shift;
                            valid <= 1;
                        end else begin
                            frame_error <= 1;
                        end
                    end else begin
                        count <= count + 1'b1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
