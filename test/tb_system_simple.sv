`timescale 1ns / 1ps
`define RTCORE_HLS_PREFIX "D:/"
`define MIN(a, b) (((a) > (b)) ? (b) : (a))

import axi_vip_pkg::*; 
import system_simple_axi_vip_0_0_pkg::*;
import system_simple_axi_vip_1_0_pkg::*;

module tb_system_simple();
    function [31:0] convert_endian (input [31:0] in);
        convert_endian = {in[7:0], in[15:8], in[23:16], in[31:24]};
    endfunction

    function [447:0] convert_nbp (input [511:0] generate_nbp);
        bit [31:0] generate_nbp_left_node_num_trigs;
        bit [31:0] generate_nbp_left_node_child_idx;
        bit [31:0] generate_nbp_right_node_num_trigs;
        bit [31:0] generate_nbp_right_node_child_idx;
        bit [31:0] generate_nbp_left_bbox_x_min;
        bit [31:0] generate_nbp_left_bbox_x_max;
        bit [31:0] generate_nbp_left_bbox_y_min;
        bit [31:0] generate_nbp_left_bbox_y_max;
        bit [31:0] generate_nbp_left_bbox_z_min;
        bit [31:0] generate_nbp_left_bbox_z_max;
        bit [31:0] generate_nbp_right_bbox_x_min;
        bit [31:0] generate_nbp_right_bbox_x_max;
        bit [31:0] generate_nbp_right_bbox_y_min;
        bit [31:0] generate_nbp_right_bbox_y_max;
        bit [31:0] generate_nbp_right_bbox_z_min;
        bit [31:0] generate_nbp_right_bbox_z_max;
        bit [2:0]  nbp_left_node_num_trigs;
        bit [28:0] nbp_left_node_child_idx;
        bit [2:0]  nbp_right_node_num_trigs;
        bit [28:0] nbp_right_node_child_idx;
        bit [31:0] nbp_left_bbox_x_min;
        bit [31:0] nbp_left_bbox_x_max;
        bit [31:0] nbp_left_bbox_y_min;
        bit [31:0] nbp_left_bbox_y_max;
        bit [31:0] nbp_left_bbox_z_min;
        bit [31:0] nbp_left_bbox_z_max;
        bit [31:0] nbp_right_bbox_x_min;
        bit [31:0] nbp_right_bbox_x_max;
        bit [31:0] nbp_right_bbox_y_min;
        bit [31:0] nbp_right_bbox_y_max;
        bit [31:0] nbp_right_bbox_z_min;
        bit [31:0] nbp_right_bbox_z_max;
        {   
            generate_nbp_left_node_num_trigs,
            generate_nbp_left_node_child_idx,
            generate_nbp_right_node_num_trigs,
            generate_nbp_right_node_child_idx,
            generate_nbp_left_bbox_x_min,
            generate_nbp_left_bbox_x_max,
            generate_nbp_left_bbox_y_min,
            generate_nbp_left_bbox_y_max,
            generate_nbp_left_bbox_z_min,
            generate_nbp_left_bbox_z_max,
            generate_nbp_right_bbox_x_min,
            generate_nbp_right_bbox_x_max,
            generate_nbp_right_bbox_y_min,
            generate_nbp_right_bbox_y_max,
            generate_nbp_right_bbox_z_min,
            generate_nbp_right_bbox_z_max
        } = generate_nbp;
        nbp_left_node_num_trigs  = convert_endian(generate_nbp_left_node_num_trigs);
        nbp_left_node_child_idx  = convert_endian(generate_nbp_left_node_child_idx);
        nbp_right_node_num_trigs = convert_endian(generate_nbp_right_node_num_trigs);
        nbp_right_node_child_idx = convert_endian(generate_nbp_right_node_child_idx);
        nbp_left_bbox_x_min      = convert_endian(generate_nbp_left_bbox_x_min);
        nbp_left_bbox_x_max      = convert_endian(generate_nbp_left_bbox_x_max);
        nbp_left_bbox_y_min      = convert_endian(generate_nbp_left_bbox_y_min);
        nbp_left_bbox_y_max      = convert_endian(generate_nbp_left_bbox_y_max);
        nbp_left_bbox_z_min      = convert_endian(generate_nbp_left_bbox_z_min);
        nbp_left_bbox_z_max      = convert_endian(generate_nbp_left_bbox_z_max);
        nbp_right_bbox_x_min     = convert_endian(generate_nbp_right_bbox_x_min);
        nbp_right_bbox_x_max     = convert_endian(generate_nbp_right_bbox_x_max);
        nbp_right_bbox_y_min     = convert_endian(generate_nbp_right_bbox_y_min);
        nbp_right_bbox_y_max     = convert_endian(generate_nbp_right_bbox_y_max);
        nbp_right_bbox_z_min     = convert_endian(generate_nbp_right_bbox_z_min);
        nbp_right_bbox_z_max     = convert_endian(generate_nbp_right_bbox_z_max);
        convert_nbp = {
            nbp_right_bbox_z_max,
            nbp_right_bbox_z_min,
            nbp_right_bbox_y_max,
            nbp_right_bbox_y_min,
            nbp_right_bbox_x_max,
            nbp_right_bbox_x_min,
            nbp_left_bbox_z_max,
            nbp_left_bbox_z_min,
            nbp_left_bbox_y_max,
            nbp_left_bbox_y_min,
            nbp_left_bbox_x_max,
            nbp_left_bbox_x_min,
            nbp_right_node_child_idx,
            nbp_right_node_num_trigs,
            nbp_left_node_child_idx,
            nbp_left_node_num_trigs
        };
    endfunction

    function [287:0] convert_trig (input [287:0] trig);
        bit [31:0] p0_x;
        bit [31:0] p0_y;
        bit [31:0] p0_z;
        bit [31:0] e1_x;
        bit [31:0] e1_y;
        bit [31:0] e1_z;
        bit [31:0] e2_x;
        bit [31:0] e2_y;
        bit [31:0] e2_z;
        {
            p0_x,
            p0_y,
            p0_z,
            e1_x,
            e1_y,
            e1_z,
            e2_x,
            e2_y,
            e2_z
        } = trig;
        p0_x = convert_endian(p0_x);
        p0_y = convert_endian(p0_y);
        p0_z = convert_endian(p0_z);
        e1_x = convert_endian(e1_x);
        e1_y = convert_endian(e1_y);
        e1_z = convert_endian(e1_z);
        e2_x = convert_endian(e2_x);
        e2_y = convert_endian(e2_y);
        e2_z = convert_endian(e2_z);
        convert_trig = {
            e2_z,
            e2_y,
            e2_x,
            e1_z,
            e1_y,
            e1_x,
            p0_z,
            p0_y,
            p0_x
        };
    endfunction

    function [255:0] convert_ray (input [255:0] ray);
        bit [31:0] origin_x;
        bit [31:0] origin_y;
        bit [31:0] origin_z;
        bit [31:0] dir_x;
        bit [31:0] dir_y;
        bit [31:0] dir_z;
        bit [31:0] tmin;
        bit [31:0] tmax;
        {
            origin_x,
            origin_y,
            origin_z,
            dir_x,
            dir_y,
            dir_z,
            tmin,
            tmax
        } = ray;
        origin_x = convert_endian(origin_x);
        origin_y = convert_endian(origin_y);
        origin_z = convert_endian(origin_z);
        dir_x = convert_endian(dir_x);
        dir_y = convert_endian(dir_y);
        dir_z = convert_endian(dir_z);
        tmin = convert_endian(tmin);
        tmax = convert_endian(tmax);
        convert_ray = {
            tmax,
            tmin,
            dir_z,
            dir_y,
            dir_x,
            origin_z,
            origin_y,
            origin_x
        };
    endfunction 

    function [96:0] convert_result (input [127:0] generate_result);
        bit [31:0] generate_result_intersected;
        bit [31:0] generate_result_t;
        bit [31:0] generate_result_u;
        bit [31:0] generate_result_v;
        bit        result_intersected;
        bit [31:0] result_t;
        bit [31:0] result_u;
        bit [31:0] result_v;
        {
            generate_result_intersected,
            generate_result_t,
            generate_result_u,
            generate_result_v
        } = generate_result;
        result_intersected = convert_endian(generate_result_intersected);
        result_t           = convert_endian(generate_result_t);
        result_u           = convert_endian(generate_result_u);
        result_v           = convert_endian(generate_result_v);
        convert_result = {
            result_v,
            result_u,
            result_t,
            result_intersected
        };
    endfunction

    localparam bbox_baseaddr = 36'h8_0000_0000;
    localparam ist_baseaddr  = 36'h8_4000_0000;

    system_simple_axi_vip_0_0_slv_mem_t bbox_agent;
    system_simple_axi_vip_1_0_slv_mem_t ist_agent;

    bit [511:0] generate_nbp;
    bit [287:0] trig;
    bit [255:0] ray;
    bit [127:0] generate_result;
    bit [96:0]  result;
    int         num_correct = 0;
    int         num_incorrect = 0;

    // input
    bit         aclk;
    bit         aresetn;
    bit         ray_stream_empty_n;
    bit [255:0] ray_stream_rd_data;
    bit         result_stream_full_n;

    // output
    wire        ray_stream_rd_en;
    wire [96:0] result_stream_wr_data;
    wire        result_stream_wr_en;

    system_simple_wrapper DUT(
        .aclk(aclk),
        .aresetn(aresetn),
        .ray_stream_empty_n(ray_stream_empty_n),
        .ray_stream_rd_data(ray_stream_rd_data),
        .ray_stream_rd_en(ray_stream_rd_en),
        .result_stream_full_n(result_stream_full_n),
        .result_stream_wr_data(result_stream_wr_data),
        .result_stream_wr_en(result_stream_wr_en)
    );

    always #1 aclk = ~aclk;

    initial begin
        int          fd_1;
        int          fd_2;
        int          fd_3;
        bit [35:0]   addr;
        bit [5:0]    offset;
        bit [35:0]   addr_1_aligned;
        bit [35:0]   addr_2_aligned;
        bit [127:0]  strobe;
        bit [1023:0] data;
        bit          correct;

        bbox_agent = new("bbox_agent", DUT.system_simple_i.axi_vip_0.inst.IF);
        bbox_agent.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_RANDOM);
        bbox_agent.mem_model.set_inter_beat_gap_range(0, 8);
        fd_1 = $fopen({`RTCORE_HLS_PREFIX, "rtcore-hls/data/generate_nbp.bin"}, "rb");
        assert(fd_1 != 0);
        for (int i = 0; ; i++) begin
            if ($fread(generate_nbp, fd_1) == 0)
                break;
            addr = bbox_baseaddr + i * 56;
            offset = addr % 64;
            addr_1_aligned = addr - offset;
            addr_2_aligned = addr_1_aligned + 64;
            strobe = 0;
            strobe[offset+:56] = {56{1'b1}};
            data = 0;
            data[offset*8+:448] = convert_nbp(generate_nbp);
            bbox_agent.mem_model.backdoor_memory_write(addr_1_aligned, data[511:0], strobe[63:0]);
            //$display("%h %h %h", addr_1_aligned, data[511:0], strobe[63:0]);
            bbox_agent.mem_model.backdoor_memory_write(addr_2_aligned, data[1023:512], strobe[127:64]);
            //$display("%h %h %h", addr_2_aligned, data[1023:512], strobe[127:64]);
        end
        $fclose(fd_1);
        bbox_agent.start_slave();
        
        ist_agent = new("ist_agent", DUT.system_simple_i.axi_vip_1.inst.IF);
        ist_agent.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_RANDOM);
        ist_agent.mem_model.set_inter_beat_gap_range(0, 8);
        fd_1 = $fopen({`RTCORE_HLS_PREFIX, "rtcore-hls/data/trig.bin"}, "rb");
        assert(fd_1 != 0);
        for (int i = 0; ; i++) begin
            if ($fread(trig, fd_1) == 0)
                break;
            addr = ist_baseaddr + i * 36;
            offset = addr % 64;
            addr_1_aligned = addr - offset;
            addr_2_aligned = addr_1_aligned + 64;
            strobe = 0;
            strobe[offset+:36] = {36{1'b1}};
            data = 0;
            data[offset*8+:288] = convert_trig(trig);
            ist_agent.mem_model.backdoor_memory_write(addr_1_aligned, data[511:0], strobe[63:0]);
            //$display("%h %h %h", addr_1_aligned, data[511:0], strobe[63:0]);
            ist_agent.mem_model.backdoor_memory_write(addr_2_aligned, data[1023:512], strobe[127:64]);
            //$display("%h %h %h", addr_2_aligned, data[1023:512], strobe[127:64]);
        end
        $fclose(fd_1);
        ist_agent.start_slave();

        aresetn = 1'b0;
        repeat(100) @(negedge aclk);
        aresetn = 1'b1;
        repeat(100) @(negedge aclk);

        fd_1 = $fopen({`RTCORE_HLS_PREFIX, "rtcore-hls/data/ray.bin"}, "rb");
        fd_2 = $fopen({`RTCORE_HLS_PREFIX, "rtcore-hls/data/generate_result.bin"}, "rb");
        fd_3 = $fopen("incorrect.txt", "w");
        assert(fd_1 != 0);
        assert(fd_2 != 0);
        forever begin
            if ($fread(ray_stream_rd_data, fd_1) == 0)
                break;
            assert($fread(generate_result, fd_2) != 0);
            ray_stream_rd_data = convert_ray(ray_stream_rd_data);
            ray_stream_empty_n = 1'b1;
            forever @(posedge aclk)
                if (ray_stream_rd_en)
                    break;
            @(negedge aclk);
            ray_stream_empty_n = 1'b0;
            result_stream_full_n = 1'b1;
            forever @(posedge aclk)
                if (result_stream_wr_en)
                    break;
            @(negedge aclk);
            result_stream_full_n = 1'b0;
            result = convert_result(generate_result);
            correct = 1'b0;
            if (result[0]) begin
                if (result_stream_wr_data[0] &&
                    result_stream_wr_data[32:1] == result[32:1] &&
                    result_stream_wr_data[64:33] == result[64:33] &&
                    result_stream_wr_data[96:65] == result[96:65])
                    correct = 1'b1;
            end else begin
                if (~result_stream_wr_data[0])
                    correct = 1'b1;
            end
            if (correct) begin
                num_correct++;
            end else begin
                num_incorrect++;
                $fwrite(fd_3, "i: %b <=> %b\n", result_stream_wr_data[0], result[0]);
                $fwrite(fd_3, "t: %h <=> %h\n", result_stream_wr_data[32:1], result[32:1]);
                $fwrite(fd_3, "u: %h <=> %h\n", result_stream_wr_data[64:33], result[64:33]);
                $fwrite(fd_3, "v: %h <=> %h\n", result_stream_wr_data[96:65], result[96:65]);
                $fflush(fd_3);
            end
            @(negedge aclk);
        end
        $fclose(fd_1);
        $fclose(fd_2);
        $fclose(fd_3);

        $display("num_correct: %d", num_correct);
        $display("num_incorrect: %d", num_incorrect);
        $finish;
    end
endmodule