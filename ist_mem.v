`timescale 1ns / 1ps

//     | 15 | 14 | 13 | 12 | 11 | 10 | 9  | 8  | 7  | 6  | 5  | 4  | 3  | 2  | 1  | 0  |
//  0                                      <------------------------------------------> 
//  1*  --------------------------------->                                    <-------- 
//  2                            <------------------------------------------>           
//  3*  ----------------------->                                    <------------------ 
//  4                  <------------------------------------------>                     
//  5*  ------------->                                    <---------------------------- 
//  6        <------------------------------------------>                               
//  7*  --->                                    <-------------------------------------- 
//  8*  -------------------------------------->                                    <--- 
//  9                                 <------------------------------------------>      
// 10*  ---------------------------->                                    <------------- 
// 11                       <------------------------------------------>                
// 12*  ------------------>                                    <----------------------- 
// 13             <------------------------------------------>                          
// 14*  -------->                                    <--------------------------------- 
// 15   <------------------------------------------>                                    

module ist_mem #(
    parameter                  ID_WIDTH = 5,
    parameter                  ADDR_WIDTH = 36,
    parameter [ADDR_WIDTH-1:0] TRIG_BASE_ADDR = 36'h8_4000_0000,  // MUST BE ALIGNED ON 4K
    // DO NOT MODIFY VALUES BELOW
    parameter                  NUM_CONCURRENT_RAYS = (1 << ID_WIDTH),
    parameter                  NUM_TRIGS_WIDTH = 3,
    parameter                  MAX_TRIGS_PER_NODE = ((1 << NUM_TRIGS_WIDTH) - 1),
    parameter                  BRAM_ADDR_WIDTH = $clog2((MAX_TRIGS_PER_NODE - 1) * NUM_CONCURRENT_RAYS),
    parameter                  TRIG_IDX_WIDTH = 29,
    parameter [5:0]            TRIG_BYTES = 36,
    parameter                  TRIG_WIDTH = 8 * TRIG_BYTES
)(                             
    input      [ID_WIDTH+NUM_TRIGS_WIDTH+TRIG_IDX_WIDTH-1:0] ist_mem_req_din,
    input                                                    ist_mem_req_empty,
    output                                                   ist_mem_req_read,
                            
    output     [ID_WIDTH+TRIG_WIDTH-1:0]                     ist_mem_resp_dout,
    input                                                    ist_mem_resp_full,
    output                                                   ist_mem_resp_write,

    output     [BRAM_ADDR_WIDTH-1:0]                         trig_bram_addr,
    output     [TRIG_WIDTH-1:0]                              trig_bram_din,
    output reg                                               trig_bram_en,
    output                                                   trig_bram_we,

    output     [ADDR_WIDTH-1:0]                              m_axi_ddr_araddr,
    output     [7:0]                                         m_axi_ddr_arlen,
    output     [2:0]                                         m_axi_ddr_arsize,
    output     [1:0]                                         m_axi_ddr_arburst,
    output     [3:0]                                         m_axi_ddr_arcache,
    output     [2:0]                                         m_axi_ddr_arprot,
    output                                                   m_axi_ddr_arvalid,
    input                                                    m_axi_ddr_arready,
    input      [511:0]                                       m_axi_ddr_rdata,
    input      [1:0]                                         m_axi_ddr_rresp,
    input                                                    m_axi_ddr_rlast,
    input                                                    m_axi_ddr_rvalid,
    output                                                   m_axi_ddr_rready,

    input                                                    aclk,
    input                                                    aresetn
);
    
    // state diagram:                 +------+
    //                                |KEEP_A|----------
    //                                +------+<-        \
    //              ---------------     |  ^  \ \        \
    //             /               \    v  |   \ \        \
    // +----+   +------+   +------+ ->+------+  ->+------+ ->+----+
    // |IDLE|-->|ADDR_A|-->|ADDR_B|-->|DATA_A|--->|DATA_B|-->|DONE|
    // +----+<- +------+   +------+   +------+    +------+ ->+----+
    //         \                         \                /   /
    //          \                         ----------------   /
    //           --------------------------------------------

    localparam S_NUM_STATES = 7;
    localparam S_IDLE   = 0,
               S_ADDR_A = 1,
               S_ADDR_B = 2,
               S_DATA_A = 3,
               S_KEEP_A = 4,
               S_DATA_B = 5,
               S_DONE   = 6;

    wire [ID_WIDTH-1:0]        req_id;
    wire [NUM_TRIGS_WIDTH-1:0] req_num_trigs;
    wire [TRIG_IDX_WIDTH-1:0]  req_trig_idx;

    wire [ADDR_WIDTH-1:0]   start_offset;
    wire [ADDR_WIDTH-1:0]   end_offset;
    wire [ADDR_WIDTH-6-1:0] offset_diff;
    wire [ADDR_WIDTH-6-1:0] start_highaddr;
    wire [ADDR_WIDTH-6-1:0] end_highaddr;

    wire cross_4k;
    wire cross_64b;

    wire [31:0]           rdata [15:0];
    reg  [TRIG_WIDTH-1:0] trig;

    reg [$clog2(S_NUM_STATES)-1:0] state;
    reg [$clog2(S_NUM_STATES)-1:0] next_state;

    reg [ID_WIDTH-1:0]        id;
    reg                       cross_4k_r;
    reg [5:0]                 len_a;
    reg [5:0]                 len_b;
    reg [ADDR_WIDTH-6-1:0]    highaddr_a;
    reg [ADDR_WIDTH-12-1:0]   highaddr_b;

    reg [511:0] m_axi_ddr_rdata_r;

    reg [NUM_TRIGS_WIDTH-1:0] num_trigs_left;
    reg [3:0]                 trig_lowidx;

    reg [TRIG_WIDTH-1:0] trig_;

    assign ist_mem_req_read = (state == S_IDLE && (~ist_mem_req_empty));
    
    assign ist_mem_resp_dout  = {trig_, id};
    assign ist_mem_resp_write = (state == S_DONE && (~ist_mem_resp_full));

    assign trig_bram_addr = (num_trigs_left - 1) * NUM_CONCURRENT_RAYS + id;
    assign trig_bram_din  = trig;
    assign trig_bram_we   = 1'b1;

    assign m_axi_ddr_araddr  = (state == S_ADDR_A ? {highaddr_a, {6{1'b0}}} : {highaddr_b, {12{1'b0}}});
    assign m_axi_ddr_arlen   = (state == S_ADDR_A ? {2'b00, len_a} : {2'b00, len_b});
    assign m_axi_ddr_arsize  = 3'b110;
    assign m_axi_ddr_arburst = (m_axi_ddr_arlen == 0 ? 2'b00 : 2'b01);
    assign m_axi_ddr_arcache = 4'b1111;
    assign m_axi_ddr_arprot  = 3'b000;
    assign m_axi_ddr_arvalid = (state == S_ADDR_A || state == S_ADDR_B);
    assign m_axi_ddr_rready  = (state == S_DATA_A || state == S_DATA_B);

    assign {req_trig_idx, req_num_trigs, req_id} = ist_mem_req_din;
    
    assign start_offset   = req_trig_idx * TRIG_BYTES;
    assign end_offset     = (req_trig_idx + req_num_trigs) * TRIG_BYTES - 1;
    assign offset_diff    = end_offset[ADDR_WIDTH-1:6] - start_offset[ADDR_WIDTH-1:6];
    assign start_highaddr = TRIG_BASE_ADDR[ADDR_WIDTH-1:6] + start_offset[ADDR_WIDTH-1:6];
    assign end_highaddr   = TRIG_BASE_ADDR[ADDR_WIDTH-1:6] + end_offset[ADDR_WIDTH-1:6];

    assign cross_4k  = (start_offset[12] != end_offset[12]); 
    assign cross_64b = (trig_lowidx[3] ^ trig_lowidx[0]);

    assign {rdata[15], rdata[14], rdata[13], rdata[12], rdata[11], rdata[10], rdata[9], rdata[8],
            rdata[7],  rdata[6],  rdata[5],  rdata[4],  rdata[3],  rdata[2],  rdata[1], rdata[0]} = (state == S_KEEP_A ? m_axi_ddr_rdata_r : m_axi_ddr_rdata);

    always @(*) begin
        case (trig_lowidx)
             0: trig = {rdata[8],  rdata[7],  rdata[6],  rdata[5],  rdata[4],  rdata[3],  rdata[2], rdata[1], rdata[0]                   };
             9: trig = {rdata[9],  rdata[8],  rdata[7],  rdata[6],  rdata[5],  rdata[4],  rdata[3], rdata[2], rdata[1]                   };
             2: trig = {rdata[10], rdata[9],  rdata[8],  rdata[7],  rdata[6],  rdata[5],  rdata[4], rdata[3], rdata[2]                   };
            11: trig = {rdata[11], rdata[10], rdata[9],  rdata[8],  rdata[7],  rdata[6],  rdata[5], rdata[4], rdata[3]                   };
             4: trig = {rdata[12], rdata[11], rdata[10], rdata[9],  rdata[8],  rdata[7],  rdata[6], rdata[5], rdata[4]                   };
            13: trig = {rdata[13], rdata[12], rdata[11], rdata[10], rdata[9],  rdata[8],  rdata[7], rdata[6], rdata[5]                   };
             6: trig = {rdata[14], rdata[13], rdata[12], rdata[11], rdata[10], rdata[9],  rdata[8], rdata[7], rdata[6]                   };
            15: trig = {rdata[15], rdata[14], rdata[13], rdata[12], rdata[11], rdata[10], rdata[9], rdata[8], rdata[7]                   };
             8: trig = {rdata[0],                                                                             trig_[TRIG_WIDTH-1*32-1:0] };
             1: trig = {rdata[1],  rdata[0],                                                                  trig_[TRIG_WIDTH-2*32-1:0] };
            10: trig = {rdata[2],  rdata[1],  rdata[0],                                                       trig_[TRIG_WIDTH-3*32-1:0] };
             3: trig = {rdata[3],  rdata[2],  rdata[1],  rdata[0],                                            trig_[TRIG_WIDTH-4*32-1:0] };
            12: trig = {rdata[4],  rdata[3],  rdata[2],  rdata[1],  rdata[0],                                 trig_[TRIG_WIDTH-5*32-1:0] };
             5: trig = {rdata[5],  rdata[4],  rdata[3],  rdata[2],  rdata[1],  rdata[0],                      trig_[TRIG_WIDTH-6*32-1:0] };
            14: trig = {rdata[6],  rdata[5],  rdata[4],  rdata[3],  rdata[2],  rdata[1],  rdata[0],           trig_[TRIG_WIDTH-7*32-1:0] };
             7: trig = {rdata[7],  rdata[6],  rdata[5],  rdata[4],  rdata[3],  rdata[2],  rdata[1], rdata[0], trig_[TRIG_WIDTH-8*32-1:0] };
        endcase
    end

    always @(posedge aclk)
        state <= next_state;

    always @(*) begin
        trig_bram_en = 1'b0;
        next_state = S_IDLE;
        if (aresetn) case (state)
            S_IDLE: begin
                if (ist_mem_req_read)
                    next_state = S_ADDR_A;
                else
                    next_state = S_IDLE;
            end
            S_ADDR_A: begin
                if (m_axi_ddr_arvalid & m_axi_ddr_arready) begin
                    if (cross_4k_r) 
                        next_state = S_ADDR_B;
                    else
                        next_state = S_DATA_A;
                end else begin
                    next_state = S_ADDR_A;
                end
            end
            S_ADDR_B: begin
                if (m_axi_ddr_arvalid & m_axi_ddr_arready)
                    next_state = S_DATA_A;
                else
                    next_state = S_ADDR_B;
            end
            S_DATA_A: begin
                if (m_axi_ddr_rvalid & m_axi_ddr_rready) begin
                    if (cross_64b) begin
                        next_state = S_DATA_B;
                    end else if (num_trigs_left == 0) begin
                        next_state = S_DONE;
                    end else if (trig_lowidx == 15) begin
                        trig_bram_en = 1'b1;
                        next_state = S_DATA_A;
                    end else begin
                        trig_bram_en = 1'b1;
                        next_state = S_KEEP_A;
                    end
                end else begin
                    next_state = S_DATA_A;
                end
            end
            S_KEEP_A: begin
                if (cross_64b) begin
                    next_state = S_DATA_B;
                end else if (num_trigs_left == 0) begin
                    next_state = S_DONE;
                end else if (trig_lowidx == 15) begin
                    trig_bram_en = 1'b1;
                    next_state = S_DATA_A;
                end else begin
                    trig_bram_en = 1'b1;
                    next_state = S_KEEP_A;
                end
            end
            S_DATA_B: begin
                if (m_axi_ddr_rvalid & m_axi_ddr_rready) begin
                    if (num_trigs_left == 0) begin
                        next_state = S_DONE;
                    end else begin
                        trig_bram_en = 1'b1;
                        next_state = S_KEEP_A;
                    end
                end else begin
                    next_state = S_DATA_B;
                end
            end
            S_DONE: begin
                if (ist_mem_resp_write)
                    next_state = S_IDLE;
                else
                    next_state = S_DONE;
            end
        endcase
    end

    always @(posedge aclk) begin
        if (state == S_IDLE) begin
            id         <= req_id;
            cross_4k_r <= cross_4k;
            len_a      <= cross_4k ? (6'b111111 - start_highaddr[5:0]) : offset_diff[5:0];
            len_b      <= end_highaddr[5:0];
            highaddr_a <= start_highaddr;
            highaddr_b <= end_highaddr[ADDR_WIDTH-6-1:6];
        end
    end

    always @(posedge aclk) begin
        if (m_axi_ddr_rvalid && m_axi_ddr_rready) begin
            m_axi_ddr_rdata_r <= m_axi_ddr_rdata;
        end
    end

    always @(posedge aclk) begin
        if (state == S_IDLE) begin
            num_trigs_left <= req_num_trigs - 1;
            trig_lowidx    <= req_trig_idx[3:0];
        end else if (trig_bram_en) begin
            num_trigs_left <= num_trigs_left - 1;
            trig_lowidx    <= trig_lowidx + 1;
        end
    end

    always @(posedge aclk) begin
        case (state)
            S_DATA_A, S_KEEP_A: begin
                case (trig_lowidx)
                          8: trig_ <= {{32{1'bX}}, rdata[15],  rdata[14],  rdata[13],  rdata[12],  rdata[11],  rdata[10],  rdata[9],   rdata[8]  };
                          1: trig_ <= {{32{1'bX}}, {32{1'bX}}, rdata[15],  rdata[14],  rdata[13],  rdata[12],  rdata[11],  rdata[10],  rdata[9]  };
                         10: trig_ <= {{32{1'bX}}, {32{1'bX}}, {32{1'bX}}, rdata[15],  rdata[14],  rdata[13],  rdata[12],  rdata[11],  rdata[10] };
                          3: trig_ <= {{32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, rdata[15],  rdata[14],  rdata[13],  rdata[12],  rdata[11] };
                         12: trig_ <= {{32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, rdata[15],  rdata[14],  rdata[13],  rdata[12] };
                          5: trig_ <= {{32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, rdata[15],  rdata[14],  rdata[13] };
                         14: trig_ <= {{32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, rdata[15],  rdata[14] };
                          7: trig_ <= {{32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, {32{1'bX}}, rdata[15] };
                    default: trig_ <= trig;
                endcase
            end
            S_DATA_B: begin
                trig_ <= trig;
            end
        endcase
    end
endmodule
