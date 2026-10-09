module event_fifo #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 2
) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] in_data,
    input wire in_valid,
    output wire in_ready,
    output wire [WIDTH-1:0] out_data,
    output wire out_valid,
    input wire out_ready,
    output wire overflow
);

    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [WIDTH-1:0] memory [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] write_ptr;
    reg [ADDR_WIDTH-1:0] read_ptr;
    reg [ADDR_WIDTH:0] count;
    reg overflow_reg;
    wire push;
    wire pop;

    assign in_ready = (count != DEPTH);
    assign out_valid = (count != 0);
    assign out_data = memory[read_ptr];
    assign overflow = overflow_reg;
    assign push = in_valid && in_ready;
    assign pop = out_valid && out_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= 0;
            read_ptr <= 0;
            count <= 0;
            overflow_reg <= 0;
        end else begin
            if (in_valid && !in_ready)
                overflow_reg <= 1;

            if (push) begin
                memory[write_ptr] <= in_data;
                write_ptr <= write_ptr + 1'b1;
            end

            if (pop)
                read_ptr <= read_ptr + 1'b1;

            case ({push, pop})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
