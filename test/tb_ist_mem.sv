`timescale 1ns / 1ps

import axi_vip_pkg::*; 
import system_axi_vip_0_0_pkg::*;

module tb_system();
    localparam  ID_WIDTH            = 5;
    localparam  ADDR_WIDTH          = 36;
    localparam  TRIG_BASE_ADDR      = 36'h8_4000_0000;
    localparam  NUM_CONCURRENT_RAYS = (1 << ID_WIDTH);
    localparam  NUM_TRIGS_WIDTH     = 3;
    localparam  MAX_TRIGS_PER_NODE  = ((1 << NUM_TRIGS_WIDTH) - 1);
    localparam  BRAM_ADDR_WIDTH     = $clog2((MAX_TRIGS_PER_NODE - 1) * NUM_CONCURRENT_RAYS);
    localparam  TRIG_IDX_WIDTH      = 29;
    localparam  TRIG_BYTES          = 36;
    localparam  TRIG_WIDTH          = 8 * TRIG_BYTES;

    localparam  NUM_TEST_TRIGS = 2048;
    
    // input
    bit         aclk;
    bit         aresetn;
    wire [36:0] ist_mem_req_din;
    bit         ist_mem_req_empty;
    bit         ist_mem_resp_full;
    bit  [7:0]  addrb;
    bit         enb;

    // output
    wire [287:0] doutb;
    wire         ist_mem_req_read;
    wire [292:0] ist_mem_resp_dout;
    wire         ist_mem_resp_write;
    
    system_axi_vip_0_0_slv_mem_t slave_agent;
    bit [TRIG_WIDTH*NUM_TEST_TRIGS-1:0] mem;
    int ii;
    
    bit [ID_WIDTH-1:0]        req_id;
    bit [NUM_TRIGS_WIDTH-1:0] req_num_trigs;
    bit [TRIG_IDX_WIDTH-1:0]  req_trig_id;
    assign ist_mem_req_din = {req_trig_id, req_num_trigs, req_id};
    
    wire [ID_WIDTH-1:0]   resp_id;
    wire [TRIG_WIDTH-1:0] resp_trig;
    assign {resp_trig, resp_id} = ist_mem_resp_dout;
    
    system_wrapper DUT(
        .aclk(aclk),
        .addrb(addrb),
        .aresetn(aresetn),
        .doutb(doutb),
        .enb(enb),
        .ist_mem_req_din(ist_mem_req_din),
        .ist_mem_req_empty(ist_mem_req_empty),
        .ist_mem_req_read(ist_mem_req_read),
        .ist_mem_resp_dout(ist_mem_resp_dout),
        .ist_mem_resp_full(ist_mem_resp_full),
        .ist_mem_resp_write(ist_mem_resp_write)
    );
    
    always #1 aclk = ~aclk;
    
    initial begin
        slave_agent = new("slave vip agent", DUT.system_i.axi_vip_0.inst.IF);
        slave_agent.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_RANDOM);
        slave_agent.mem_model.set_inter_beat_gap_range(1, 8);
        std::randomize(mem);
        for (int i = 0; i < NUM_TEST_TRIGS; i++)
            $display("%d: %h", i, mem[TRIG_WIDTH*i+:TRIG_WIDTH]);
        assert((TRIG_WIDTH*NUM_TEST_TRIGS)%512 == 0);
        for (int i = 0; i < (TRIG_WIDTH*NUM_TEST_TRIGS)/512; i++)
            slave_agent.mem_model.backdoor_memory_write(TRIG_BASE_ADDR+64*i, mem[512*i+:512], {64{1'b1}});
        slave_agent.start_slave();
        
        ist_mem_req_empty = 1'b1;
        repeat(100) @(negedge aclk);
        aresetn = 1'b1;
        repeat(100) @(negedge aclk);
        
        for (int i = 0; i < NUM_TEST_TRIGS-MAX_TRIGS_PER_NODE+1; i++) begin
            ii = i;
            for (int j = 1; j <= MAX_TRIGS_PER_NODE; j++) begin
                req_id = $random;
                req_num_trigs = j;
                req_trig_id = i;
                ist_mem_req_empty = 1'b0;
                forever @(posedge aclk)
                    if (ist_mem_req_read)
                        break;
                @(negedge aclk);
                ist_mem_req_empty = 1'b1;
                forever @(posedge aclk)
                    if (ist_mem_resp_write)
                        break;
                @(negedge aclk);
                if (resp_id != req_id)
                    $fatal(1, "ID MISMATCH @ i=%d j=%d", i, j);
                for (int k = 0; k < j-1; k++) begin
                    enb = 1'b1;
                    addrb = (j-k-2) * NUM_CONCURRENT_RAYS + resp_id;
                    @(negedge aclk);
                    enb = 1'b0;
                    if (doutb != mem[TRIG_WIDTH*(i+k)+:TRIG_WIDTH])
                        $fatal(1, "TRIG MISMATCH @ i=%d j=%d k=%d", i, j, k);
                    @(negedge aclk);
                end
                if (resp_trig != mem[TRIG_WIDTH*(i+j-1)+:TRIG_WIDTH])
                    $fatal(1, "TRIG MISMATCH @ i=%d j=%d", i, j);
                @(negedge aclk);
            end
        end
        
        $display("TEST PASSED");
        $finish;
    end
endmodule
