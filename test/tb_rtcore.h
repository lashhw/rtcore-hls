#ifndef RTCORE_HLS_TB_RTCORE_H
#define RTCORE_HLS_TB_RTCORE_H

#define RTCORE_HLS_PREFIX "D:/"

#include <iostream>
#include <fstream>
#include "rtcore_sim.h"

int main() {
    std::vector<ray_t> ray_;
    {
        std::ifstream ray_stream(RTCORE_HLS_PREFIX"rtcore-hls/data/ray.bin", std::ios::binary);
        assert(ray_stream.good());
        for (ray_t ray; ray_stream.read((char*)(&ray), sizeof(ray_t)); )
            ray_.push_back(ray);
    }

    std::vector<generate_result_t> generate_result_;
    {
        std::ifstream generate_result_stream(RTCORE_HLS_PREFIX"rtcore-hls/data/generate_result.bin", std::ios::binary);
        assert(generate_result_stream.good());
        for (generate_result_t generate_result; generate_result_stream.read((char*)(&generate_result), sizeof(generate_result_t)); )
            generate_result_.push_back(generate_result);
    }

    hls_thread_local hls::stream<ray_t> ray_stream;
    hls_thread_local hls::stream<result_t> result_stream;

    for (int i = 0; i < ray_.size(); i++) {
        ray_t ray = {
            .origin_x = ray_[i].origin_x,
            .origin_y = ray_[i].origin_y,
            .origin_z = ray_[i].origin_z,
            .dir_x    = ray_[i].dir_x,
            .dir_y    = ray_[i].dir_y,
            .dir_z    = ray_[i].dir_z,
            .tmin     = ray_[i].tmin,
            .tmax     = ray_[i].tmax
        };
        ray_stream.write(ray);
    }

    hls_thread_local hls::task t1(rtcore_sim, ray_stream, result_stream); 

    uintmax_t num_correct = 0;
    for (int i = 0; i < ray_.size(); i++) {
        result_t result;
        result_stream.read(result);
        bool correct = false;
        if (generate_result_[i].intersected) {
            if (result.intersected && 
                result.t == generate_result_[i].t &&
                result.u == generate_result_[i].u &&
                result.v == generate_result_[i].v)
                correct = true;
        } else {
            if (!result.intersected)
                correct = true;
        }
        if (correct) {
            num_correct++;
        } else {
            std::cout << "differ in " << i << std::endl; 
            std::cout << "  " << result.intersected << "<===>" << generate_result_[i].intersected << std::endl;
            std::cout << "  " << result.t           << "<===>" << generate_result_[i].t           << std::endl;
            std::cout << "  " << result.u           << "<===>" << generate_result_[i].u           << std::endl;
            std::cout << "  " << result.v           << "<===>" << generate_result_[i].v           << std::endl;
        }
    }

    std::cout << "num_correct = " << num_correct << std::endl;
    std::cout << "ray_.size() = " << ray_.size() << std::endl;
}

#endif // RTCORE_HLS_TB_RTCORE_H
