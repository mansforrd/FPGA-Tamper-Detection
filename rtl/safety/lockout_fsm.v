module lockout_fsm #(
	parameter LOCKOUT_CYCLES = 32'd1000000)
 (
    input wire clk,
    input wire rst_n,
    input wire fault_active,
    input wire authenticated_clear,
    output reg locked,
    output reg [31:0] remaining_cycles
);
    localparam IDLE = 1'b0, LOCKED = 1'b1;
    reg state;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin state <= IDLE; locked <= 1'b0; remaining_cycles <= 0;
 end
        else case (state)
            IDLE: if (fault_active) begin state <= LOCKED; locked <= 1'b1; remaining_cycles <= LOCKOUT_CYCLES;
 end
            LOCKED: begin
                locked <= 1'b1;
                if (fault_active) remaining_cycles <= LOCKOUT_CYCLES;
                else if (authenticated_clear && remaining_cycles == 0) begin state <= IDLE; locked <= 1'b0;
 end
                else if (remaining_cycles != 0) remaining_cycles <= remaining_cycles - 1'b1;
            end
        endcase
    end
endmodule
