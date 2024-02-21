#ifndef RTCORE_HLS_RTCORE_H
#define RTCORE_HLS_RTCORE_H

#include <hls_task.h>
#include "init.h"
#include "trv.h"
#include "bbox.h"
#include "bbox_ctrl.h"
#include "ist.h"
#include "ist_ctrl.h"

void rtcore(/* in  */ hls::stream<ray_t>& ray_stream,
            /* in  */ hls::stream<bbox_mem_resp_t>& bbox_mem_resp_stream,
            /* in  */ hls::stream<ist_mem_resp_t>& ist_mem_resp_stream,
            /* in  */ const trig_t trig_[MAX_TRIGS_PER_NODE - 1][NUM_CONCURRENT_RAYS],
            /* out */ hls::stream<bbox_mem_req_t>& bbox_mem_req_stream,
            /* out */ hls::stream<ist_mem_req_t>& ist_mem_req_stream,
            /* out */ hls::stream<result_t>& result_stream) {
#pragma HLS STABLE variable=trig_
#pragma HLS INTERFACE mode=ap_ctrl_none port=return
#pragma HLS INTERFACE mode=ap_memory port=trig_ storage_type=rom_1p
#pragma HLS DATAFLOW
    hls_thread_local hls::stream<trv_req_t> trv_req_stream;
    hls_thread_local hls::stream<trv_resp_t> trv_resp_stream;
    hls_thread_local hls::stream<bbox_ctrl_req_t> bbox_ctrl_req_stream;
    hls_thread_local hls::stream<bbox_ctrl_resp_t> bbox_ctrl_resp_stream;
    hls_thread_local hls::stream<bbox_req_t> bbox_req_stream;
    hls_thread_local hls::stream<bbox_resp_t> bbox_resp_stream;
    hls_thread_local hls::stream<ist_ctrl_req_t> ist_ctrl_req_stream;
    hls_thread_local hls::stream<ist_ctrl_resp_t> ist_ctrl_resp_stream;
    hls_thread_local hls::stream<ist_req_t> ist_req_stream;
    hls_thread_local hls::stream<ist_resp_t> ist_resp_stream;

    init(ray_stream, trv_resp_stream, trv_req_stream, result_stream);
    trv(trv_req_stream, bbox_ctrl_resp_stream, ist_ctrl_resp_stream, bbox_ctrl_req_stream, ist_ctrl_req_stream, trv_resp_stream);
    bbox_ctrl(bbox_ctrl_req_stream, bbox_mem_resp_stream, bbox_resp_stream, bbox_mem_req_stream, bbox_req_stream, bbox_ctrl_resp_stream);
    bbox(bbox_req_stream, bbox_resp_stream);
    ist_ctrl(ist_ctrl_req_stream, ist_mem_resp_stream, ist_resp_stream, trig_, ist_mem_req_stream, ist_req_stream, ist_ctrl_resp_stream);
    ist(ist_req_stream, ist_resp_stream);
}

#endif // RTCORE_HLS_RTCORE_H