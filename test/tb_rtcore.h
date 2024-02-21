#ifndef RTCORE_HLS_TB_RTCORE_H
#define RTCORE_HLS_TB_RTCORE_H

#define RTCORE_HLS_PREFIX "D:/"

#include <iostream>
#include <fstream>
#include "rtcore_sim.h"

int main() {
    std::vector<ray_t> ray_;
    std::ifstream ray_stream(RTCORE_HLS_PREFIX"rtcore-hls/data/ray.bin", std::ios::binary);
    assert(ray_stream.good());
    for (ray_t ray; ray_stream.read((char*)(&ray), sizeof(ray_t)); )
        ray_.push_back(ray);

    std::vector<generate_result_t> generate_result_;
    std::ifstream generate_result_stream(RTCORE_HLS_PREFIX"rtcore-hls/data/generate_result.bin", std::ios::binary);
    assert(generate_result_stream.good());
    for (generate_result_t generate_result; generate_result_stream.read((char*)(&generate_result), sizeof(generate_result_t)); )
        generate_result_.push_back(generate_result);

    hls_thread_local hls::stream<trv_req_t> trv_req_stream;
    hls_thread_local hls::stream<trv_resp_t> trv_resp_stream;

    for (int i = 0; i < 3; i++) {
        trv_req_t trv_req = {
            .rid = 0,
            .ray_and_preprocessed_ray = {
                .origin_x = ray_[i].origin_x,
                .origin_y = ray_[i].origin_y,
                .origin_z = ray_[i].origin_z,
                .dir_x    = ray_[i].dir_x,
                .dir_y    = ray_[i].dir_y,
                .dir_z    = ray_[i].dir_z,
                .w_x      = 1.0f / ray_[i].dir_x,
                .w_y      = 1.0f / ray_[i].dir_y,
                .w_z      = 1.0f / ray_[i].dir_z,
                .b_x      = (-ray_[i].origin_x) / ray_[i].dir_x,
                .b_y      = (-ray_[i].origin_y) / ray_[i].dir_y,
                .b_z      = (-ray_[i].origin_z) / ray_[i].dir_z,
                .tmin     = ray_[i].tmin,
                .tmax     = ray_[i].tmax
            }
        };
        trv_req_stream.write(trv_req);
    }

    hls_thread_local hls::task t1(rtcore_sim, trv_req_stream, trv_resp_stream); 

    for (int i = 0; i < 3; i++) {
        trv_resp_t trv_resp;
        trv_resp_stream.read(trv_resp);
        std::cout << trv_resp.rid                                                    << std::endl;
        std::cout << trv_resp.intersected << ", " << generate_result_[i].intersected << std::endl;
        std::cout << trv_resp.t           << ", " << generate_result_[i].t           << std::endl;
        std::cout << trv_resp.u           << ", " << generate_result_[i].u           << std::endl;
        std::cout << trv_resp.v           << ", " << generate_result_[i].v           << std::endl;
    }
}

#endif // RTCORE_HLS_TB_RTCORE_H
