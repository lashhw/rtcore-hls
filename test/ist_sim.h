#ifndef RTCORE_HLS_IST_SIM_H
#define RTCORE_HLS_IST_SIM_H

#include <hls_stream.h>
#include <hls_math.h>
#include "../include/datatypes.h"

void ist_sim(/* in  */ hls::stream<ist_req_t>& ist_req_stream,
             /* out */ hls::stream<ist_resp_t>& ist_resp_stream) {
//#pragma HLS INTERFACE mode=ap_ctrl_none port=return
//#pragma HLS PIPELINE II=1

    ist_req_t ist_req;
    if (!ist_req_stream.read_nb(ist_req))
        return;
    ray_t& ray = ist_req.ray;
    trig_t& trig = ist_req.trig;

    float n_x = trig.e1_y * trig.e2_z - trig.e1_z * trig.e2_y;
    float n_y = trig.e1_z * trig.e2_x - trig.e1_x * trig.e2_z;
    float n_z = trig.e1_x * trig.e2_y - trig.e1_y * trig.e2_x;

    float c_x = trig.p0_x - ray.origin_x;
    float c_y = trig.p0_y - ray.origin_y;
    float c_z = trig.p0_z - ray.origin_z;

    float r_x = ray.dir_y * c_z - ray.dir_z * c_y;
    float r_y = ray.dir_z * c_x - ray.dir_x * c_z;
    float r_z = ray.dir_x * c_y - ray.dir_y * c_x;

    float inv_det = 1.0f / (ray.dir_x * n_x + ray.dir_y * n_y + ray.dir_z * n_z);

    float u = inv_det * (trig.e2_x * r_x + trig.e2_y * r_y + trig.e2_z * r_z);
    float v = inv_det * (trig.e1_x * r_x + trig.e1_y * r_y + trig.e1_z * r_z);

    if (u >= 0.0f && v >= 0.0f && (u + v) <= 1.0f) {
        float t = inv_det * (c_x * n_x + c_y * n_y + c_z * n_z);
        if (t >= ray.tmin && t <= ray.tmax) {
            ist_resp_t ist_resp = {
                .id = ist_req.id,
                .intersected = 1,
                .t = t,
                .u = u,
                .v = v
            };
            ist_resp_stream.write(ist_resp);
            return;
        }
    } 

    ist_resp_t ist_resp = {
        .id = ist_req.id,
        .intersected = 0,
        .t = 0.0f,
        .u = 0.0f,
        .v = 0.0f
    };
    ist_resp_stream.write(ist_resp);
}

#endif // RTCORE_HLS_IST_SIM_H