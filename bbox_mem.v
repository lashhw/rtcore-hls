`timescale 1ns / 1ps

module bbox_mem #(
    parameter                  ID_WIDTH = 5,
    parameter                  ADDR_WIDTH = 36,
    parameter [ADDR_WIDTH-1:0] NBP_BASE_ADDR = 36'h8_0000_0000,  // MUST BE ALIGNED ON 4K
    // DO NOT MODIFY VALUES BELOW
    parameter                  NBP_IDX_WIDTH = 29,
    parameter [5:0]            NBP_BYTES = 56,
    parameter                  NBP_WIDTH = 8 * NBP_BYTES
)(                             
    input  [ID_WIDTH+NBP_IDX_WIDTH-1:0] bbox_mem_req_din,
    input                               bbox_mem_req_empty,
    output                              bbox_mem_req_read,
                        
    output [ID_WIDTH+NBP_WIDTH-1:0]     bbox_mem_resp_dout,
    input                               bbox_mem_resp_full,
    output                              bbox_mem_resp_write,

    output [ADDR_WIDTH-1:0]             m_axi_ddr_araddr,
    output [7:0]                        m_axi_ddr_arlen,
    output [2:0]                        m_axi_ddr_arsize,
    output [1:0]                        m_axi_ddr_arburst,
    output [3:0]                        m_axi_ddr_arcache,
    output [2:0]                        m_axi_ddr_arprot,
    output                              m_axi_ddr_arvalid,
    input                               m_axi_ddr_arready,
    input  [511:0]                      m_axi_ddr_rdata,
    input  [1:0]                        m_axi_ddr_rresp,
    input                               m_axi_ddr_rlast,
    input                               m_axi_ddr_rvalid,
    output                              m_axi_ddr_rready,

    input                               aclk,
    input                               aresetn
);
    
    localparam S_NUM_STATES = 6;
    localparam S_IDLE = 0,
               S_ADDR_A = 1,
               S_ADDR_B = 2,
               S_DATA_A = 3,
               S_DATA_B = 4,
               S_DONE = 5;

    wire [ID_WIDTH-1:0]      req_id;
    wire [NBP_IDX_WIDTH-1:0] req_nbp_idx;

    wire cross_4k;
    wire cross_64b;

    wire [ADDR_WIDTH-1:0] addr;
    wire [63:0]           rdata [7:0];

    reg [$clog2(S_NUM_STATES)-1:0] state;

    reg [ID_WIDTH-1:0]     id;
    reg [2:0]              nbp_lowidx;
    reg                    cross_4k_r;
    reg                    cross_64b_r;
    reg [ADDR_WIDTH-6-1:0] highaddr_a;
    reg [ADDR_WIDTH-6-1:0] highaddr_b;

    reg [NBP_WIDTH-1:0] nbp;

    assign bbox_mem_req_read = (state == S_IDLE & (~bbox_mem_req_empty));
    
    assign bbox_mem_resp_dout = {nbp, id};
    assign bbox_mem_resp_write = (state == S_DONE & (~bbox_mem_resp_full));

    assign m_axi_ddr_araddr = (state == S_ADDR_A ? {highaddr_a, 6'b000000} : {highaddr_b, 6'b000000});
    assign m_axi_ddr_arlen = (cross_4k_r ? 0 : (cross_64b_r ? 1 : 0));
    assign m_axi_ddr_arsize = 3'b110;
    assign m_axi_ddr_arburst = (cross_4k_r ? 2'b00 : (cross_64b_r ? 2'b01 : 2'b00));
    assign m_axi_ddr_arcache = 4'b1111;
    assign m_axi_ddr_arprot = 3'b000;
    assign m_axi_ddr_arvalid = (state == S_ADDR_A || state == S_ADDR_B);
    assign m_axi_ddr_rready = (state == S_DATA_A || state == S_DATA_B);

    assign {req_nbp_idx, req_id} = bbox_mem_req_din;

    assign cross_4k = (req_nbp_idx[8:0] == 1 * 73 ||
                       req_nbp_idx[8:0] == 2 * 73 || 
                       req_nbp_idx[8:0] == 3 * 73 || 
                       req_nbp_idx[8:0] == 4 * 73 || 
                       req_nbp_idx[8:0] == 5 * 73 || 
                       req_nbp_idx[8:0] == 6 * 73); 
    assign cross_64b = (req_nbp_idx[2:0] != 0 && req_nbp_idx[2:0] != 7);

    assign addr = NBP_BASE_ADDR + NBP_BYTES * req_nbp_idx;
    assign {rdata[7], rdata[6], rdata[5], rdata[4], rdata[3], rdata[2], rdata[1], rdata[0]} = m_axi_ddr_rdata;

    always @(posedge aclk) begin
        if (~aresetn) begin
            state <= S_IDLE;
        end case (state)
            S_IDLE: begin
                if (bbox_mem_req_read)
                    state <= S_ADDR_A;
            end
            S_ADDR_A: begin
                if (m_axi_ddr_arvalid & m_axi_ddr_arready) begin
                    if (cross_4k_r) 
                        state <= S_ADDR_B;
                    else
                        state <= S_DATA_A;
                end
            end
            S_ADDR_B: begin
                if (m_axi_ddr_arvalid & m_axi_ddr_arready)
                    state <= S_DATA_A;
            end
            S_DATA_A: begin
                if (m_axi_ddr_rvalid & m_axi_ddr_rready) begin
                    if (cross_64b_r)
                        state <= S_DATA_B;
                    else
                        state <= S_DONE;
                end
            end
            S_DATA_B: begin
                if (m_axi_ddr_rvalid & m_axi_ddr_rready)
                    state <= S_DONE;
            end
            S_DONE: begin
                if (bbox_mem_resp_write)
                    state <= S_IDLE;
            end
        endcase
    end

    always @(posedge aclk) begin
        if (state == S_IDLE) begin
            id <= req_id;
            nbp_lowidx <= req_nbp_idx[2:0];
            cross_4k_r <= cross_4k;
            cross_64b_r <= cross_64b;
            highaddr_a <= addr[ADDR_WIDTH-1:6];
            highaddr_b <= addr[ADDR_WIDTH-1:6] + 1;
        end
    end

    always @(posedge aclk) begin
        case (state)
            S_DATA_A: begin
                case (nbp_lowidx)
                    0: nbp <= {rdata[6],   rdata[5],   rdata[4],   rdata[3],   rdata[2],   rdata[1],   rdata[0]};
                    1: nbp <= {{64{1'bX}}, {64{1'bX}}, {64{1'bX}}, {64{1'bX}}, {64{1'bX}}, {64{1'bX}}, rdata[7]};
                    2: nbp <= {{64{1'bX}}, {64{1'bX}}, {64{1'bX}}, {64{1'bX}}, {64{1'bX}}, rdata[7],   rdata[6]};
                    3: nbp <= {{64{1'bX}}, {64{1'bX}}, {64{1'bX}}, {64{1'bX}}, rdata[7],   rdata[6],   rdata[5]};
                    4: nbp <= {{64{1'bX}}, {64{1'bX}}, {64{1'bX}}, rdata[7],   rdata[6],   rdata[5],   rdata[4]};
                    5: nbp <= {{64{1'bX}}, {64{1'bX}}, rdata[7],   rdata[6],   rdata[5],   rdata[4],   rdata[3]};
                    6: nbp <= {{64{1'bX}}, rdata[7],   rdata[6],   rdata[5],   rdata[4],   rdata[3],   rdata[2]};
                    7: nbp <= {rdata[7],   rdata[6],   rdata[5],   rdata[4],   rdata[3],   rdata[2],   rdata[1]};
                endcase
            end
            S_DATA_B: begin
                case (nbp_lowidx)
                    1: nbp[NBP_WIDTH-1:1*64] <= {rdata[5], rdata[4], rdata[3], rdata[2], rdata[1], rdata[0]};
                    2: nbp[NBP_WIDTH-1:2*64] <= {rdata[4], rdata[3], rdata[2], rdata[1], rdata[0]};
                    3: nbp[NBP_WIDTH-1:3*64] <= {rdata[3], rdata[2], rdata[1], rdata[0]};
                    4: nbp[NBP_WIDTH-1:4*64] <= {rdata[2], rdata[1], rdata[0]};
                    5: nbp[NBP_WIDTH-1:5*64] <= {rdata[1], rdata[0]};
                    6: nbp[NBP_WIDTH-1:6*64] <= {rdata[0]};
                endcase
            end
        endcase
    end
endmodule
