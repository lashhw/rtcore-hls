#ifndef RTCORE_HLS_IST_CTRL_H
#define RTCORE_HLS_IST_CTRL_H

#include <hls_stream.h>
#include "../include/datatypes.h"

void ist_ctrl(/* in  */ hls::stream<ist_ctrl_req_t>& ist_ctrl_req_stream,
              /* in  */ hls::stream<ist_mem_resp_t>& ist_mem_resp_stream,
              /* in  */ hls::stream<ist_resp_t>& ist_resp_stream,
              /* in  */ const trig_t trig_[MAX_TRIGS_PER_NODE - 1][NUM_CONCURRENT_RAYS],
              /* out */ hls::stream<ist_mem_req_t>& ist_mem_req_stream,
              /* out */ hls::stream<ist_req_t>& ist_req_stream,
              /* out */ hls::stream<ist_ctrl_resp_t>& ist_ctrl_resp_stream) {
//#pragma HLS INTERFACE mode=ap_ctrl_none port=return

    struct local_mem_t {
        ray_t ray;
        num_trigs_t num_trigs_left;
        bool_t intersected;
        float u;
        float v;
    };

    static local_mem_t local_mem_[NUM_CONCURRENT_RAYS];

    ist_ctrl_req_t ist_ctrl_req;
    ist_mem_resp_t ist_mem_resp;
    ist_resp_t ist_resp;
    
    if (ist_ctrl_req_stream.read_nb(ist_ctrl_req)) {
        local_mem_[ist_ctrl_req.rid].ray            = ist_ctrl_req.ray;
        local_mem_[ist_ctrl_req.rid].num_trigs_left = ist_ctrl_req.num_trigs - 1;
        local_mem_[ist_ctrl_req.rid].intersected    = 0;
        ist_mem_req_t ist_mem_req = {
            .rid       = ist_ctrl_req.rid,
            .num_trigs = ist_ctrl_req.num_trigs,
            .trig_idx  = ist_ctrl_req.trig_idx
        };
        ist_mem_req_stream.write(ist_mem_req);
    } else if (ist_mem_resp_stream.read_nb(ist_mem_resp)) {
        ist_req_t ist_req = {
            .rid  = ist_mem_resp.rid,
            .ray  = local_mem_[ist_mem_resp.rid].ray,
            .trig = ist_mem_resp.first_trig
        };
        ist_req_stream.write(ist_req);
    } else if (ist_resp_stream.read_nb(ist_resp)) {
        local_mem_t local_mem      = local_mem_[ist_resp.rid];
        num_trigs_t num_trigs_left = local_mem.num_trigs_left;
        local_mem.num_trigs_left   = num_trigs_left - 1;
        if (ist_resp.intersected) {
            local_mem.ray.tmax    = ist_resp.t;
            local_mem.intersected = 1;
            local_mem.u           = ist_resp.u;
            local_mem.v           = ist_resp.v;
        }
        local_mem_[ist_resp.rid] = local_mem;

        if (num_trigs_left == 0) {
            ist_ctrl_resp_t ist_ctrl_resp = {
                .rid         = ist_resp.rid,
                .intersected = local_mem.intersected,
                .t           = local_mem.ray.tmax,
                .u           = local_mem.u,
                .v           = local_mem.v
            };
            ist_ctrl_resp_stream.write(ist_ctrl_resp);
        } else {
            ist_req_t ist_req = {
                .rid  = ist_resp.rid,
                .ray  = local_mem.ray,
                .trig = trig_[local_mem.num_trigs_left][ist_resp.rid]
            };
            ist_req_stream.write(ist_req);
        }
    }
}

#endif // RTCORE_HLS_IST_CTRL_H