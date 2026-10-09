`timescale 1ns/1ps

module tb_sensor;

    reg [11:0] sensor_in;
    wire [11:0] sensor_value;

    sensor #(.WIDTH(12)) dut (
        .sensor_in(sensor_in),
        .sensor_value(sensor_value)
    );

    initial begin
        sensor_in = 12'habc;
        #1;
        if (sensor_value !== sensor_in)
            $fatal(1, "sensor pass-through failed");

        $display("PASS sensor");
        $finish;
    end

endmodule
