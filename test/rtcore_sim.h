#ifndef RTCORE_HLS_RTCORE_SIM_H
#define RTCORE_HLS_RTCORE_SIM_H

#include <hls_task.h>
#include "bbox_sim.h"
#include "../src/bbox_ctrl.h"
#include "ist_sim.h"
#include "../src/ist_ctrl.h"
#include "../src/trv.h"
#include "bbox_mem_sim.h"
#include "ist_mem_sim.h"

void rtcore_sim(/* in  */ hls::stream<trv_req_t>& trv_req_stream,
                /* out */ hls::stream<trv_resp_t>& trv_resp_stream) {
#pragma HLS STABLE variable=trig_
#pragma HLS INTERFACE mode=ap_ctrl_none port=return
#pragma HLS INTERFACE mode=ap_memory port=trig_ storage_type=rom_1p
#pragma HLS DATAFLOW
    hls_thread_local hls::stream<bbox_ctrl_req_t> bbox_ctrl_req_stream;
    hls_thread_local hls::stream<bbox_ctrl_resp_t> bbox_ctrl_resp_stream;
    hls_thread_local hls::stream<bbox_req_t> bbox_req_stream;
    hls_thread_local hls::stream<bbox_resp_t> bbox_resp_stream;
    hls_thread_local hls::stream<ist_ctrl_req_t> ist_ctrl_req_stream;
    hls_thread_local hls::stream<ist_ctrl_resp_t> ist_ctrl_resp_stream;
    hls_thread_local hls::stream<ist_req_t> ist_req_stream;
    hls_thread_local hls::stream<ist_resp_t> ist_resp_stream;

    hls_thread_local hls::stream<bbox_mem_req_t> bbox_mem_req_stream;
    hls_thread_local hls::stream<bbox_mem_resp_t> bbox_mem_resp_stream;
    hls_thread_local hls::stream<ist_mem_req_t> ist_mem_req_stream;
    hls_thread_local hls::stream<ist_mem_resp_t> ist_mem_resp_stream;
    trig_t trig_[MAX_TRIGS_PER_NODE - 1][NUM_CONCURRENT_RAYS];

    bbox_ctrl(bbox_ctrl_req_stream, bbox_mem_resp_stream, bbox_resp_stream, bbox_mem_req_stream, bbox_req_stream, bbox_ctrl_resp_stream);
    bbox_sim(bbox_req_stream, bbox_resp_stream);
    ist_ctrl(ist_ctrl_req_stream, ist_mem_resp_stream, ist_resp_stream, trig_, ist_mem_req_stream, ist_req_stream, ist_ctrl_resp_stream);
    ist_sim(ist_req_stream, ist_resp_stream);
    trv(trv_req_stream, bbox_ctrl_resp_stream, ist_ctrl_resp_stream, bbox_ctrl_req_stream, ist_ctrl_req_stream, trv_resp_stream);

    bbox_mem_sim(bbox_mem_req_stream, bbox_mem_resp_stream);
    ist_mem_sim(ist_mem_req_stream, ist_mem_resp_stream, trig_);
}

#endif // RTCORE_HLS_RTCORE_SIM_H