module puf_authenticator #(
    parameter WIDTH = 128,
    parameter MAX_BIT_ERRORS = 8
) (
    input wire clk,
    input wire rst_n,
    input wire response_valid,
    input wire [WIDTH-1:0] response,
    input wire enroll,
    input wire [WIDTH-1:0] enrolled_response,
    output reg auth_valid,
    output reg auth_ok,
    output reg auth_fail,
    output reg enrollment_valid
);

    integer i;
    integer errors;
    reg [WIDTH-1:0] reference_response;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reference_response <= enrolled_response;
            enrollment_valid <= 1;
            auth_valid <= 0;
            auth_ok <= 0;
            auth_fail <= 0;
        end else begin
            auth_valid <= 0;
            auth_fail <= 0;

            if (response_valid) begin
                auth_valid <= 1;

                if (enroll) begin
                    reference_response <= response;
                    enrollment_valid <= 1;
                    auth_ok <= 1;
                end else if (!enrollment_valid) begin
                    auth_ok <= 0;
                    auth_fail <= 1;
                end else begin
                    errors = 0;
                    for (i = 0; i < WIDTH; i = i + 1)
                        if (response[i] ^ reference_response[i])
                            errors = errors + 1;

                    auth_ok <= (errors <= MAX_BIT_ERRORS);
                    auth_fail <= (errors > MAX_BIT_ERRORS);
                end
            end
        end
    end

endmodule
