#include <hls_stream.h>
#include "D:/rtcore-hls/include/datatypes.h"

void send_req(const id_t& id,
              const trv_local_mem_t trv_local_mem_[NUM_CONCURRENT_RAYS],
              const node_t& node,
              hls::stream<bbox_ctrl_req_t>& bbox_ctrl_req_stream,
              hls::stream<ist_ctrl_req_t>& ist_ctrl_req_stream) {
#pragma HLS INLINE
    if (node.num_trigs == 0) {
        bbox_ctrl_req_t bbox_ctrl_req = {
            .id = id,
            .preprocessed_ray = {
                .w_x  = trv_local_mem_[id].ray_and_preprocessed_ray.w_x,
                .w_y  = trv_local_mem_[id].ray_and_preprocessed_ray.w_y,
                .w_z  = trv_local_mem_[id].ray_and_preprocessed_ray.w_z,
                .b_x  = trv_local_mem_[id].ray_and_preprocessed_ray.b_x,
                .b_y  = trv_local_mem_[id].ray_and_preprocessed_ray.b_y,
                .b_z  = trv_local_mem_[id].ray_and_preprocessed_ray.b_z,
                .tmin = trv_local_mem_[id].ray_and_preprocessed_ray.tmin,
                .tmax = trv_local_mem_[id].ray_and_preprocessed_ray.tmax
            },
            .nbp_idx = node.child_idx
        };
        bbox_ctrl_req_stream.write(bbox_ctrl_req);
    } else {
        ist_ctrl_req_t ist_ctrl_req = {
            .id = id,
            .ray = {
                .origin_x = trv_local_mem_[id].ray_and_preprocessed_ray.origin_x,
                .origin_y = trv_local_mem_[id].ray_and_preprocessed_ray.origin_y,
                .origin_z = trv_local_mem_[id].ray_and_preprocessed_ray.origin_z,
                .dir_x    = trv_local_mem_[id].ray_and_preprocessed_ray.dir_x,
                .dir_y    = trv_local_mem_[id].ray_and_preprocessed_ray.dir_y,
                .dir_z    = trv_local_mem_[id].ray_and_preprocessed_ray.dir_z,
                .tmin     = trv_local_mem_[id].ray_and_preprocessed_ray.tmin,
                .tmax     = trv_local_mem_[id].ray_and_preprocessed_ray.tmax
            },
            .num_trigs = node.num_trigs,
            .trig_idx = node.child_idx
        };
        ist_ctrl_req_stream.write(ist_ctrl_req);
    }
}

void stack_op(const id_t& id,
              trv_local_mem_t trv_local_mem_[NUM_CONCURRENT_RAYS],
              hls::stream<bbox_ctrl_req_t>& bbox_ctrl_req_stream,
              hls::stream<ist_ctrl_req_t>& ist_ctrl_req_stream,
              hls::stream<trv_resp_t>& trv_resp_stream) {
#pragma HLS INLINE
    stack_size_t stack_size = trv_local_mem_[id].stack_size;
    if (stack_size == 0) {
        trv_resp_t trv_resp = {
            .id          = id,
            .intersected = trv_local_mem_[id].intersected,
            .t           = trv_local_mem_[id].ray_and_preprocessed_ray.tmax,
            .u           = trv_local_mem_[id].u,
            .v           = trv_local_mem_[id].v
        };
        trv_resp_stream.write(trv_resp);
    } else {
        stack_size_t stack_size_minus_1 = stack_size - 1;
        node_t stack_top = trv_local_mem_[id].stack_[stack_size_minus_1];
        trv_local_mem_[id].stack_size = stack_size_minus_1;
        send_req(id, trv_local_mem_, stack_top, bbox_ctrl_req_stream, ist_ctrl_req_stream);
    }
}

void trv(/* in  */ hls::stream<trv_req_t>& trv_req_stream,
         /* in  */ hls::stream<bbox_ctrl_resp_t>& bbox_ctrl_resp_stream,
         /* in  */ hls::stream<ist_ctrl_resp_t>& ist_ctrl_resp_stream,
         /* out */ hls::stream<bbox_ctrl_req_t>& bbox_ctrl_req_stream,
         /* out */ hls::stream<ist_ctrl_req_t>& ist_ctrl_req_stream,
         /* out */ hls::stream<trv_resp_t>& trv_resp_stream) {
#pragma HLS INTERFACE mode=ap_ctrl_none port=return
//#pragma HLS PIPELINE II=1

    static trv_local_mem_t trv_local_mem_[NUM_CONCURRENT_RAYS];
//#pragma HLS DEPENDENCE dependent=false type=inter variable=trv_local_mem_

    trv_req_t trv_req;
    bbox_ctrl_resp_t bbox_ctrl_resp;
    ist_ctrl_resp_t ist_ctrl_resp;

    if (trv_req_stream.read_nb(trv_req)) {
        trv_local_mem_[trv_req.id].stack_size = 0;
        trv_local_mem_[trv_req.id].ray_and_preprocessed_ray = trv_req.ray_and_preprocessed_ray;
        trv_local_mem_[trv_req.id].intersected = 0;
        bbox_ctrl_req_t bbox_ctrl_req = {
            .id = trv_req.id,
            .preprocessed_ray = {
                .w_x  = trv_req.ray_and_preprocessed_ray.w_x,
                .w_y  = trv_req.ray_and_preprocessed_ray.w_y,
                .w_z  = trv_req.ray_and_preprocessed_ray.w_z,
                .b_x  = trv_req.ray_and_preprocessed_ray.b_x,
                .b_y  = trv_req.ray_and_preprocessed_ray.b_y,
                .b_z  = trv_req.ray_and_preprocessed_ray.b_z,
                .tmin = trv_req.ray_and_preprocessed_ray.tmin,
                .tmax = trv_req.ray_and_preprocessed_ray.tmax
            },
            .nbp_idx = 0
        };
        bbox_ctrl_req_stream.write(bbox_ctrl_req);
    } else if (bbox_ctrl_resp_stream.read_nb(bbox_ctrl_resp)) {
        if (bbox_ctrl_resp.left_hit) {
            if (bbox_ctrl_resp.right_hit) {
                if (bbox_ctrl_resp.left_first) {
                    trv_local_mem_[bbox_ctrl_resp.id].stack_[trv_local_mem_[bbox_ctrl_resp.id].stack_size++] = bbox_ctrl_resp.right_node;
                    send_req(bbox_ctrl_resp.id, trv_local_mem_, bbox_ctrl_resp.left_node, bbox_ctrl_req_stream, ist_ctrl_req_stream);
                } else {
                    trv_local_mem_[bbox_ctrl_resp.id].stack_[trv_local_mem_[bbox_ctrl_resp.id].stack_size++] = bbox_ctrl_resp.left_node;
                    send_req(bbox_ctrl_resp.id, trv_local_mem_, bbox_ctrl_resp.right_node, bbox_ctrl_req_stream, ist_ctrl_req_stream);
                }
            } else {
                send_req(bbox_ctrl_resp.id, trv_local_mem_, bbox_ctrl_resp.left_node, bbox_ctrl_req_stream, ist_ctrl_req_stream);
            }
        } else if (bbox_ctrl_resp.right_hit) {
            send_req(bbox_ctrl_resp.id, trv_local_mem_, bbox_ctrl_resp.right_node, bbox_ctrl_req_stream, ist_ctrl_req_stream);
        } else {
            stack_op(bbox_ctrl_resp.id, trv_local_mem_, bbox_ctrl_req_stream, ist_ctrl_req_stream, trv_resp_stream);
        }
    } else if (ist_ctrl_resp_stream.read_nb(ist_ctrl_resp)) {
        if (ist_ctrl_resp.intersected) {
            trv_local_mem_[ist_ctrl_resp.id].intersected                   = 1;
            trv_local_mem_[ist_ctrl_resp.id].ray_and_preprocessed_ray.tmax = ist_ctrl_resp.t;
            trv_local_mem_[ist_ctrl_resp.id].u                             = ist_ctrl_resp.u;
            trv_local_mem_[ist_ctrl_resp.id].v                             = ist_ctrl_resp.v;
        }
        stack_op(ist_ctrl_resp.id, trv_local_mem_, bbox_ctrl_req_stream, ist_ctrl_req_stream, trv_resp_stream);
    }
}
