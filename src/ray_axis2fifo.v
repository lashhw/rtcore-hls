`timescale 1ns / 1ps

module ray_axis2fifo (
    input          aclk,

    // axis
    input  [255:0] s_axis_ray_tdata,
    input  [31:0]  s_axis_ray_tkeep,
    input          s_axis_ray_tlast,
    output         s_axis_ray_tready,
    input          s_axis_ray_tvalid,

    // fifo
    input          full,
    output [255:0] din,
    output         write
);
    assign s_axis_ray_tready = ~full;
    assign din               = s_axis_ray_tdata;
    assign write             = s_axis_ray_tready & s_axis_ray_tvalid;
endmodule