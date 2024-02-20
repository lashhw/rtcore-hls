#ifndef RTCORE_HLS_BBOX_CTRL_H
#define RTCORE_HLS_BBOX_CTRL_H

#include <hls_stream.h>
#include "../include/datatypes.h"

void bbox_ctrl(/* in  */ hls::stream<bbox_ctrl_req_t>& bbox_ctrl_req_stream,
               /* in  */ hls::stream<bbox_mem_resp_t>& bbox_mem_resp_stream,
               /* in  */ hls::stream<bbox_resp_t>& bbox_resp_stream,
               /* out */ hls::stream<bbox_mem_req_t>& bbox_mem_req_stream,
               /* out */ hls::stream<bbox_req_t>& bbox_req_stream,
               /* out */ hls::stream<bbox_ctrl_resp_t>& bbox_ctrl_resp_stream) {
//#pragma HLS INTERFACE mode=ap_ctrl_none port=return
    
    struct local_mem_t {
        preprocessed_ray_t preprocessed_ray;
        node_t left_node;
        node_t right_node;
    };

    static local_mem_t local_mem_[NUM_CONCURRENT_RAYS];

    bbox_ctrl_req_t bbox_ctrl_req;
    bbox_mem_resp_t bbox_mem_resp;
    bbox_resp_t bbox_resp;
    
    if (bbox_ctrl_req_stream.read_nb(bbox_ctrl_req)) {
        local_mem_[bbox_ctrl_req.rid].preprocessed_ray = bbox_ctrl_req.preprocessed_ray;
        bbox_mem_req_t bbox_mem_req = {
            .rid     = bbox_ctrl_req.rid,
            .nbp_idx = bbox_ctrl_req.nbp_idx
        };
        bbox_mem_req_stream.write(bbox_mem_req);
    } else if (bbox_mem_resp_stream.read_nb(bbox_mem_resp)) {
        local_mem_[bbox_mem_resp.rid].left_node = bbox_mem_resp.nbp.node[0];
        local_mem_[bbox_mem_resp.rid].right_node = bbox_mem_resp.nbp.node[1];
        bbox_req_t bbox_req = {
            .rid              = bbox_mem_resp.rid,
            .preprocessed_ray = local_mem_[bbox_mem_resp.rid].preprocessed_ray,
            .left_bbox        = bbox_mem_resp.nbp.bbox[0],
            .right_bbox       = bbox_mem_resp.nbp.bbox[1]
        };
        bbox_req_stream.write(bbox_req);
    } else if (bbox_resp_stream.read_nb(bbox_resp)) {
        bbox_ctrl_resp_t bbox_ctrl_resp = {
            .rid        = bbox_resp.rid,
            .left_hit   = bbox_resp.left_hit,
            .right_hit  = bbox_resp.right_hit,
            .left_first = bbox_resp.left_first,
            .left_node  = local_mem_[bbox_resp.rid].left_node,
            .right_node = local_mem_[bbox_resp.rid].right_node
        };
        bbox_ctrl_resp_stream.write(bbox_ctrl_resp);
    }
}

#endif // RTCORE_HLS_BBOX_CTRL_H