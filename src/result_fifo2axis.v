`timescale 1ns / 1ps

module result_fifo2axis (
    input          aclk,

    // fifo
    input          empty,
    input  [96:0]  dout,
    output         read,

    // axis
    output [127:0] s_axis_result_tdata,
    output [15:0]  s_axis_result_tkeep,
    output         s_axis_result_tlast,
    input          s_axis_result_tready,
    output         s_axis_result_tvalid
);
    assign read = s_axis_result_tready & s_axis_result_tvalid;
    assign s_axis_result_tdata = {dout[96:1], {31{1'b0}}, dout[0]};
    assign s_axis_result_tkeep = {16{1'b1}};
    assign s_axis_result_tlast = 1'b1;
    assign s_axis_result_tvalid = ~empty;
endmodule