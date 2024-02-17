`timescale 1ns / 1ps

import axi_vip_pkg::*; 
import system_axi_vip_0_0_pkg::*;

module tb_system();
    localparam ID_WIDTH      = 5;
    localparam NBP_BASE_ADDR = 36'h8_0000_0000;
    localparam NBP_IDX_WIDTH = 29;
    localparam NBP_BYTES     = 56;
    localparam NBP_WIDTH     = 8 * NBP_BYTES;
    
    localparam NUM_TEST_NBPS = 2048;
    
    // input
    bit                               aclk;
    bit                               aresetn;
    wire [ID_WIDTH+NBP_IDX_WIDTH-1:0] bbox_mem_req_din;
    bit                               bbox_mem_req_empty;
    bit                               bbox_mem_resp_full;
    
    // output
    wire                          bbox_mem_req_read;
    wire [ID_WIDTH+NBP_WIDTH-1:0] bbox_mem_resp_dout;
    wire                          bbox_mem_resp_write;
    
    system_axi_vip_0_0_slv_mem_t slave_agent;
    bit [NBP_WIDTH*NUM_TEST_NBPS-1:0] mem;
    int ii;
    
    bit [ID_WIDTH-1:0]      req_id;
    bit [NBP_IDX_WIDTH-1:0] req_nbp_idx;
    assign bbox_mem_req_din = {req_nbp_idx, req_id};
    
    wire [ID_WIDTH-1:0] resp_id;
    wire [NBP_WIDTH-1:0] resp_nbp;
    assign {resp_nbp, resp_id} = bbox_mem_resp_dout;
    
    system_wrapper DUT(
        .aresetn(aresetn),
        .aclk(aclk),
        .bbox_mem_req_din(bbox_mem_req_din),
        .bbox_mem_req_empty(bbox_mem_req_empty),
        .bbox_mem_req_read(bbox_mem_req_read),
        .bbox_mem_resp_dout(bbox_mem_resp_dout),
        .bbox_mem_resp_full(bbox_mem_resp_full),
        .bbox_mem_resp_write(bbox_mem_resp_write)
    );
    
    always #1 aclk = ~aclk;
    
    initial begin
        slave_agent = new("slave vip agent", DUT.system_i.axi_vip_0.inst.IF);
        slave_agent.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_RANDOM);
        slave_agent.mem_model.set_inter_beat_gap_range(1, 8);
        std::randomize(mem);
        for (int i = 0; i < NUM_TEST_NBPS; i++)
            $display("%d: %h", i, mem[NBP_WIDTH*i+:NBP_WIDTH]);
        assert((NBP_WIDTH*NUM_TEST_NBPS)%512 == 0);
        for (int i = 0; i < (NBP_WIDTH*NUM_TEST_NBPS)/512; i++)
            slave_agent.mem_model.backdoor_memory_write(NBP_BASE_ADDR+64*i, mem[512*i+:512], {64{1'b1}});
        slave_agent.start_slave();
        
        bbox_mem_req_empty = 1'b1;
        repeat(100) @(negedge aclk);
        aresetn = 1'b1;
        repeat(100) @(negedge aclk);
        
        for (int i = 0; i < NUM_TEST_NBPS; i++) begin
            ii = i;
            req_id = $random;
            req_nbp_idx = i;
            bbox_mem_req_empty = 1'b0;
            forever @(posedge aclk)
                if (bbox_mem_req_read)
                    break;
            @(negedge aclk);
            bbox_mem_req_empty = 1'b1;
            forever @(posedge aclk)
                if (bbox_mem_resp_write)
                    break;
            @(negedge aclk);
            if (resp_id != req_id)
                $fatal(1, "ID MISMATCH @ i=%d", i);
            if (resp_nbp != mem[NBP_WIDTH*i+:NBP_WIDTH])
                $fatal(1, "NBP MISMATCH @ i=%d", i);
            @(negedge aclk);
        end
    
        $display("TEST PASSED");
        $finish;
    end
endmodule
