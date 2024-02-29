`timescale 1ns / 1ps
`define RTCORE_HLS_PREFIX "D:/"
`define NUM_TEST_RAYS 10000

import axi_vip_pkg::*;
import system_axi_vip_0_0_pkg::*;

module tb_system();
    typedef enum {MM2S, S2MM} dma_type_t;

    localparam nbp_baseaddr    = 36'h8_0000_0000;
    localparam trig_baseaddr   = 36'h8_4000_0000;
    localparam ray_baseaddr    = 36'h8_8000_0000;
    localparam result_baseaddr = 36'h8_C000_0000;
    localparam dma_baseaddr    = 36'h0_A000_0000;

    system_axi_vip_0_0_passthrough_mem_t mem_agent;

    system_wrapper DUT();

    initial begin
        int fd_debug;
        int fd;
        int fd_result;

        mem_agent = new("mem_agent", tb_system.DUT.system_i.axi_vip_0.inst.IF);
        tb_system.DUT.system_i.axi_vip_0.inst.set_slave_mode();
        fd_debug = $fopen("debug.txt", "w");

        fd = $fopen({`RTCORE_HLS_PREFIX, "rtcore-hls/data/generate_nbp.bin"}, "rb");
        assert(fd != 0);
        for (int i = 0; ; i++) begin
            bit [511:0] generate_nbp_rev;
            bit [511:0] generate_nbp;
            bit [447:0] nbp;
            if ($fread(generate_nbp_rev, fd) == 0)
                break;
            for (int j = 0; j < 512/8; j++)
                generate_nbp[j*8+:8] = generate_nbp_rev[512-(j+1)*8+:8];
            nbp = {generate_nbp[32*4+:32*12], generate_nbp[32*3+:29], generate_nbp[32*2+:3], generate_nbp[32+:29], generate_nbp[0+:3]};
            for (int j = 0; j < 14; j++)
                write_word(fd_debug, nbp_baseaddr+i*56+j*4, nbp[j*32+:32]);
        end
        $fclose(fd);

        fd = $fopen({`RTCORE_HLS_PREFIX, "rtcore-hls/data/trig.bin"}, "rb");
        assert(fd != 0);
        for (int i = 0; ; i++) begin
            bit [287:0] trig_rev;
            bit [287:0] trig;
            if ($fread(trig_rev, fd) == 0)
                break;
            for (int j = 0; j < 288/8; j++)
                trig[j*8+:8] = trig_rev[288-(j+1)*8+:8];
            for (int j = 0; j < 9; j++)
                write_word(fd_debug, trig_baseaddr+i*36+j*4, trig[32*j+:32]);
        end
        $fclose(fd);

        fd = $fopen({`RTCORE_HLS_PREFIX, "rtcore-hls/data/ray.bin"}, "rb");
        assert(fd != 0);
        for (int i = 0; ; i++) begin
            bit [255:0] ray_rev;
            bit [255:0] ray;
            if ($fread(ray_rev, fd) == 0)
                break;
            for (int j = 0; j < 256/8; j++)
                ray[j*8+:8] = ray_rev[256-(j+1)*8+:8];
            for (int j = 0; j < 8; j++)
                write_word(fd_debug, ray_baseaddr+i*32+j*4, ray[32*j+:32]);
        end
        $fclose(fd);

        mem_agent.start_slave();
        $fclose(fd_debug);

        tb_system.DUT.system_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b1);
        tb_system.DUT.system_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(4'h0);
        #(100*10);
        tb_system.DUT.system_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b0);
        tb_system.DUT.system_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(4'hF);
        #(100*10);
        tb_system.DUT.system_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b1);
        tb_system.DUT.system_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(4'h0);
        #(100*10);

        fd_result = $fopen("result.txt", "w");
        for (int i = 0; i < `NUM_TEST_RAYS; i++) begin
            bit [127:0] data;
            write_dma_ctrl(MM2S, ray_baseaddr+i*32, 32);
            write_dma_ctrl(S2MM, result_baseaddr+i*16, 16);
            data = mem_agent.mem_model.backdoor_memory_read(result_baseaddr+i*16);
            $fwrite(fd_result, "%d: %h\n", i, data);
            $fflush(fd_result);
        end
        $fclose(fd_result);
    end

    task write_word(input int fd_debug,
                    input [35:0] addr,
                    input [31:0] word);
        bit [3:0]   offset;
        bit [35:0]  addr_aligned;
        bit [127:0] data;
        bit [15:0]  strobe;

        offset = addr % 16;
        addr_aligned = addr - offset;
        data = 0;
        data[offset*8+:32] = word;
        strobe = 0;
        strobe[offset+:4] = {4{1'b1}};
        mem_agent.mem_model.backdoor_memory_write(addr_aligned, data, strobe);
        $fwrite(fd_debug, "%h %h %h\n", addr_aligned, data, strobe);
    endtask

    task write_dma_ctrl(input dma_type_t dma_type,
                        input bit [35:0] target_addr,
                        input bit [25:0] length);
        bit [35:0] addr;
        bit [31:0] data;
        bit [1:0]  resp;
        
        // MM2S_DMACR/S2MM_DMACR
        addr = dma_baseaddr + (dma_type == MM2S ? 32'h00 : 32'h30);
        data = 32'h0001_1003;
        tb_system.DUT.system_i.zynq_ultra_ps_e_0.inst.write_data(addr, 4, data, resp);
        assert(resp == 2'b00);
        
        // MM2S_SA/S2MM_DA
        addr = dma_baseaddr + (dma_type == MM2S ? 32'h18 : 32'h48);
        data = target_addr[31:0];
        tb_system.DUT.system_i.zynq_ultra_ps_e_0.inst.write_data(addr, 4, data, resp);
        assert(resp == 2'b00);
        
        // MM2S_SA_MSB/S2MM_DA_MSB
        addr = dma_baseaddr + (dma_type == MM2S ? 32'h1C : 32'h4C);
        data = {{28{1'b0}}, target_addr[35:32]};
        tb_system.DUT.system_i.zynq_ultra_ps_e_0.inst.write_data(addr, 4, data, resp);
        assert(resp == 2'b00);
        
        // MM2S_LENGTH/S2MM_LENGTH
        addr = dma_baseaddr + (dma_type == MM2S ? 32'h28 : 32'h58);
        data = {{6{1'b0}}, length};
        tb_system.DUT.system_i.zynq_ultra_ps_e_0.inst.write_data(addr, 4, data, resp);
        assert(resp == 2'b00);
    
        // poll MM2S_DMASR/S2MM_DMASR
        forever begin
            addr = dma_baseaddr + (dma_type == MM2S ? 32'h04 : 32'h34);
            tb_system.DUT.system_i.zynq_ultra_ps_e_0.inst.read_data(addr, 4, data, resp);
            assert(resp == 2'b00);
            if (data[12])
                break;
        end
        
        // clear MM2S_DMASR/S2MM_DMASR
        addr = dma_baseaddr + (dma_type == MM2S ? 32'h04 : 32'h34);
        data = 32'hFFFF_FFFF;
        tb_system.DUT.system_i.zynq_ultra_ps_e_0.inst.write_data(addr, 4, data, resp);
        assert(resp == 2'b00);
    endtask
endmodule