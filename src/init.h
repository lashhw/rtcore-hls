#ifndef RTCORE_HLS_INIT_H
#define RTCORE_HLS_INIT_H

#include <hls_stream.h>
#include "../include/datatypes.h"

void init(/* in  */ hls::stream<ray_t>& ray_stream,
          /* in  */ hls::stream<trv_resp_t>& trv_resp_stream,
          /* out */ hls::stream<trv_req_t>& trv_req_stream,
          /* out */ hls::stream<result_t>& result_stream) {
    static bool running = false;

    ray_t ray;
    trv_resp_t trv_resp;
    if (!running && ray_stream.read_nb(ray)) {
        running = true;
        trv_req_t trv_req = {
            .rid = 0,
            .ray_and_preprocessed_ray = {
                .origin_x = ray.origin_x,
                .origin_y = ray.origin_y,
                .origin_z = ray.origin_z,
                .dir_x    = ray.dir_x,
                .dir_y    = ray.dir_y,
                .dir_z    = ray.dir_z,
                .w_x      = 1.0f / ray.dir_x,
                .w_y      = 1.0f / ray.dir_y,
                .w_z      = 1.0f / ray.dir_z,
                .b_x      = (-ray.origin_x) / ray.dir_x,
                .b_y      = (-ray.origin_y) / ray.dir_y,
                .b_z      = (-ray.origin_z) / ray.dir_z,
                .tmin     = ray.tmin,
                .tmax     = ray.tmax
            }
        };
        trv_req_stream.write(trv_req);
    } else if (trv_resp_stream.read_nb(trv_resp)) {
        running = false;
        result_t result = {
            .intersected = trv_resp.intersected,
            .t           = trv_resp.t,
            .u           = trv_resp.u,
            .v           = trv_resp.v
        };
        result_stream.write(result);
    }
}

#endif // RTCORE_HLS_INIT_H