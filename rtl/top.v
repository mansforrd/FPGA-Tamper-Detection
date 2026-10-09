module top #(
    parameter SENSOR_WIDTH = 12,
    parameter UART_CLKS_PER_BIT = 16
) (
    input wire clk,
    input wire rst_n,
    input wire [SENSOR_WIDTH-1:0] sensor_in,
    input wire [SENSOR_WIDTH-1:0] sensor_in_b,
    input wire [SENSOR_WIDTH-1:0] high_threshold,
    input wire [SENSOR_WIDTH-1:0] low_threshold,
    input wire puf_sample_valid,
    input wire puf_enroll,
    input wire [127:0] ring_count_lsb,
    input wire [127:0] puf_challenge,
    input wire [127:0] enrolled_response,
    input wire [127:0] device_salt,
    input wire uart_rx,
    input wire service_clear,
    input wire authenticated_clear,
    output wire uart_tx,
    output wire locked
);

    wire [SENSOR_WIDTH-1:0] sensor_value;
    wire high_alarm_a;
    wire low_alarm_a;
    wire high_alarm_b;
    wire low_alarm_b;
    wire high_voted;
    wire low_voted;
    wire high_mismatch;
    wire low_mismatch;
    wire dwc_mismatch;
    wire tamper;
    wire event_pulse;
    wire fault_active;
    wire puf_fail;
    wire auth_valid;
    wire auth_ok;
    wire key_valid;
    wire enrollment_valid;
    wire raw_uart;
    wire uart_ready;
    wire uart_busy;
    wire packet_valid;
    wire event_valid;
    wire puf_response_valid;
    wire aes_busy;
    wire aes_valid;
    wire fifo_in_ready;
    wire fifo_out_valid;
    wire fifo_out_ready;
    wire fifo_overflow;
    wire frame_active;
    wire rx_valid;
    wire rx_frame_error;
    wire crc_fault;
    wire [3:0] fault_status;
    wire [31:0] event_word;
    wire [31:0] fifo_event_word;
    wire [7:0] packet_byte;
    wire [7:0] rx_byte;
    wire [127:0] puf_response;
    wire [127:0] aes_key;
    wire [127:0] ciphertext;
    wire [127:0] received_payload;
    reg telemetry_grace;
    reg frame_started;

    sensor #(.WIDTH(SENSOR_WIDTH)) u_sensor_a (
        .sensor_in(sensor_in),
        .sensor_value(sensor_value)
    );

    comparator #(.WIDTH(SENSOR_WIDTH)) u_cmp_a (
        .value(sensor_in),
        .high_threshold(high_threshold),
        .low_threshold(low_threshold),
        .high_alarm(high_alarm_a),
        .low_alarm(low_alarm_a)
    );

    comparator #(.WIDTH(SENSOR_WIDTH)) u_cmp_b (
        .value(sensor_in_b),
        .high_threshold(high_threshold),
        .low_threshold(low_threshold),
        .high_alarm(high_alarm_b),
        .low_alarm(low_alarm_b)
    );

    dwc_logic u_dwc_high (
        .channel_a(high_alarm_a),
        .channel_b(high_alarm_b),
        .voted_value(high_voted),
        .mismatch(high_mismatch)
    );

    dwc_logic u_dwc_low (
        .channel_a(low_alarm_a),
        .channel_b(low_alarm_b),
        .voted_value(low_voted),
        .mismatch(low_mismatch)
    );

    assign dwc_mismatch = high_mismatch | low_mismatch;
    assign fifo_out_ready = fifo_out_valid && key_valid && !aes_busy;

    tamper_decision u_decision (
        .clk(clk),
        .rst_n(rst_n),
        .high_alarm(high_voted),
        .low_alarm(low_voted),
        .dwc_mismatch(dwc_mismatch),
        .clear(service_clear),
        .tamper(tamper),
        .event_pulse(event_pulse)
    );

    ro_puf u_puf (
        .clk(clk),
        .rst_n(rst_n),
        .sample_valid(puf_sample_valid),
        .ring_count_lsb(ring_count_lsb),
        .challenge(puf_challenge),
        .response(puf_response),
        .response_valid(puf_response_valid)
    );

    puf_authenticator u_auth (
        .clk(clk),
        .rst_n(rst_n),
        .response_valid(puf_response_valid),
        .response(puf_response),
        .enroll(puf_enroll),
        .enrolled_response(enrolled_response),
        .auth_valid(auth_valid),
        .auth_ok(auth_ok),
        .auth_fail(puf_fail),
        .enrollment_valid(enrollment_valid)
    );

    aes_key_manager u_key_manager (
        .clk(clk),
        .rst_n(rst_n),
        .auth_valid(auth_valid),
        .auth_ok(auth_ok),
        .puf_response(puf_response),
        .device_salt(device_salt),
        .key_valid(key_valid),
        .aes_key(aes_key)
    );

    uart_rx #(.CLKS_PER_BIT(UART_CLKS_PER_BIT)) u_uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
        .data(rx_byte),
        .valid(rx_valid),
        .frame_error(rx_frame_error)
    );

    packet_checker128 u_packet_checker (
        .clk(clk),
        .rst_n(rst_n),
        .byte_in(rx_byte),
        .byte_valid(rx_valid),
        .crc_fault(crc_fault),
        .packet_valid(),
        .payload(received_payload)
    );

    fault_aggregator u_fault_aggregator (
        .clk(clk),
        .rst_n(rst_n),
        .tamper(tamper),
        .dwc_mismatch(dwc_mismatch),
        .puf_auth_fail(puf_fail),
        .crc_fault(crc_fault | rx_frame_error | fifo_overflow),
        .service_clear(service_clear),
        .fault_active(fault_active),
        .fault_status(fault_status)
    );

    lockout_fsm u_lockout (
        .clk(clk),
        .rst_n(rst_n),
        .fault_active(fault_active),
        .authenticated_clear(authenticated_clear),
        .locked(locked),
        .remaining_cycles()
    );

    event_manager u_event_manager (
        .clk(clk),
        .rst_n(rst_n),
        .event_pulse(event_pulse),
        .fault_status(fault_status),
        .sensor_value(sensor_value),
        .event_valid(event_valid),
        .event_word(event_word)
    );

    event_fifo #(.WIDTH(32), .ADDR_WIDTH(2)) u_event_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(event_word),
        .in_valid(event_valid),
        .in_ready(fifo_in_ready),
        .out_data(fifo_event_word),
        .out_valid(fifo_out_valid),
        .out_ready(fifo_out_ready),
        .overflow(fifo_overflow)
    );

    aes128 u_aes (
        .clk(clk),
        .rst_n(rst_n),
        .start(fifo_out_ready),
        .plaintext({fifo_event_word, 96'b0}),
        .key(aes_key),
        .busy(aes_busy),
        .valid(aes_valid),
        .ciphertext(ciphertext)
    );

    packetizer128 u_packetizer (
        .clk(clk),
        .rst_n(rst_n),
        .payload(ciphertext),
        .payload_valid(aes_valid),
        .byte_out(packet_byte),
        .byte_valid(packet_valid),
        .byte_ready(uart_ready),
        .frame_active(frame_active)
    );

    uart_tx #(.CLKS_PER_BIT(UART_CLKS_PER_BIT)) u_uart_tx (
        .clk(clk),
        .rst_n(rst_n),
        .data(packet_byte),
        .valid(packet_valid),
        .ready(uart_ready),
        .tx(raw_uart),
        .busy(uart_busy)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            telemetry_grace <= 0;
            frame_started <= 0;
        end else begin
            if (event_pulse)
                telemetry_grace <= 1;

            if (!telemetry_grace) begin
                frame_started <= 0;
            end else if (frame_active) begin
                frame_started <= 1;
            end else if (frame_started && !uart_busy) begin
                telemetry_grace <= 0;
            end
        end
    end

    failsafe_mux u_failsafe_mux (
        .fault_active(fault_active),
        .allow_fault_telemetry(telemetry_grace),
        .normal_tx(raw_uart),
        .safe_tx_level(1'b1),
        .uart_tx(uart_tx)
    );

endmodule
