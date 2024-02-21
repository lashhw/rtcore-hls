#ifndef RTCORE_HLS_BBOX_MEM_SIM_H
#define RTCORE_HLS_BBOX_MEM_SIM_H

#include "../data/gentypes.h"

void bbox_mem_sim(/* in  */ hls::stream<bbox_mem_req_t>& bbox_mem_req_stream,
                  /* out */ hls::stream<bbox_mem_resp_t>& bbox_mem_resp_stream) {
    static bool initialized = false;
    static std::vector<nbp_t> nbp_mem;
    if (!initialized) {
        std::ifstream generate_nbp_stream(RTCORE_HLS_PREFIX"rtcore-hls/data/generate_nbp.bin", std::ios::binary);
        assert(generate_nbp_stream.good());
        for (generate_nbp_t generate_nbp; generate_nbp_stream.read((char*)(&generate_nbp), sizeof(generate_nbp_t)); ) {
            nbp_t nbp = {
                .node = {
                    { 
                        .num_trigs = generate_nbp.left_node_num_trigs,
                        .child_idx = generate_nbp.left_node_child_idx
                    },
                    { 
                        .num_trigs = generate_nbp.right_node_num_trigs,
                        .child_idx = generate_nbp.right_node_child_idx
                    }
                },
                .bbox = {
                    {
                        .x_min = generate_nbp.left_bbox_x_min,
                        .x_max = generate_nbp.left_bbox_x_max,
                        .y_min = generate_nbp.left_bbox_y_min,
                        .y_max = generate_nbp.left_bbox_y_max,
                        .z_min = generate_nbp.left_bbox_z_min,
                        .z_max = generate_nbp.left_bbox_z_max
                    },
                    {
                        .x_min = generate_nbp.right_bbox_x_min,
                        .x_max = generate_nbp.right_bbox_x_max,
                        .y_min = generate_nbp.right_bbox_y_min,
                        .y_max = generate_nbp.right_bbox_y_max,
                        .z_min = generate_nbp.right_bbox_z_min,
                        .z_max = generate_nbp.right_bbox_z_max
                    }
                }
            };
            nbp_mem.push_back(nbp);
        }
        initialized = true;
    }

    bbox_mem_req_t bbox_mem_req;
    if (!bbox_mem_req_stream.read_nb(bbox_mem_req))
        return;
    bbox_mem_resp_t bbox_mem_resp = {
        .rid = bbox_mem_req.rid,
        .nbp = nbp_mem[bbox_mem_req.nbp_idx]
    };
    bbox_mem_resp_stream.write(bbox_mem_resp);
}

#endif // RTCORE_HLS_BBOX_MEM_SIM_H