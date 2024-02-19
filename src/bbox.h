#ifndef RTCORE_HLS_BBOX_H
#define RTCORE_HLS_BBOX_H

#include <hls_stream.h>
#include <hls_math.h>
#include "../include/datatypes.h"

float my_fmax(float a, float b) {
#pragma HLS INLINE
    return a < b ? b : a;
}

float my_fmin(float a, float b) {
#pragma HLS INLINE
    return a < b ? a : b;
}

void bbox(/* in  */ hls::stream<bbox_req_t>& bbox_req_stream,
          /* out */ hls::stream<bbox_resp_t>& bbox_resp_stream) {
//#pragma HLS INTERFACE mode=ap_ctrl_none port=return
//#pragma HLS PIPELINE II=1

    bbox_req_t bbox_req = bbox_req_stream.read();
    preprocessed_ray_t& preprocessed_ray = bbox_req.preprocessed_ray;
    
    float& left_x_a_x = hls::signbit(preprocessed_ray.w_x) ? bbox_req.left_bbox.x_max : bbox_req.left_bbox.x_min;
    float& left_x_a_y = hls::signbit(preprocessed_ray.w_y) ? bbox_req.left_bbox.y_max : bbox_req.left_bbox.y_min;
    float& left_x_a_z = hls::signbit(preprocessed_ray.w_z) ? bbox_req.left_bbox.z_max : bbox_req.left_bbox.z_min;
    float& left_x_b_x = hls::signbit(preprocessed_ray.w_x) ? bbox_req.left_bbox.x_min : bbox_req.left_bbox.x_max;
    float& left_x_b_y = hls::signbit(preprocessed_ray.w_y) ? bbox_req.left_bbox.y_min : bbox_req.left_bbox.y_max;
    float& left_x_b_z = hls::signbit(preprocessed_ray.w_z) ? bbox_req.left_bbox.z_min : bbox_req.left_bbox.z_max;

    float left_entry_x = preprocessed_ray.w_x * left_x_a_x + preprocessed_ray.b_x;
    float left_entry_y = preprocessed_ray.w_y * left_x_a_y + preprocessed_ray.b_y;
    float left_entry_z = preprocessed_ray.w_z * left_x_a_z + preprocessed_ray.b_z;
    float left_exit_x  = preprocessed_ray.w_x * left_x_b_x + preprocessed_ray.b_x;
    float left_exit_y  = preprocessed_ray.w_y * left_x_b_y + preprocessed_ray.b_y;
    float left_exit_z  = preprocessed_ray.w_z * left_x_b_z + preprocessed_ray.b_z;

    float left_entry = my_fmax(my_fmax(left_entry_x, left_entry_y), my_fmax(left_entry_z, preprocessed_ray.tmin));
    float left_exit  = my_fmin(my_fmin(left_exit_x, left_exit_y), my_fmin(left_exit_z, preprocessed_ray.tmax));
    bool_t left_hit  = left_entry <= left_exit;

    float& right_x_a_x = hls::signbit(preprocessed_ray.w_x) ? bbox_req.right_bbox.x_max : bbox_req.right_bbox.x_min;
    float& right_x_a_y = hls::signbit(preprocessed_ray.w_y) ? bbox_req.right_bbox.y_max : bbox_req.right_bbox.y_min;
    float& right_x_a_z = hls::signbit(preprocessed_ray.w_z) ? bbox_req.right_bbox.z_max : bbox_req.right_bbox.z_min;
    float& right_x_b_x = hls::signbit(preprocessed_ray.w_x) ? bbox_req.right_bbox.x_min : bbox_req.right_bbox.x_max;
    float& right_x_b_y = hls::signbit(preprocessed_ray.w_y) ? bbox_req.right_bbox.y_min : bbox_req.right_bbox.y_max;
    float& right_x_b_z = hls::signbit(preprocessed_ray.w_z) ? bbox_req.right_bbox.z_min : bbox_req.right_bbox.z_max;

    float right_entry_x = preprocessed_ray.w_x * right_x_a_x + preprocessed_ray.b_x;
    float right_entry_y = preprocessed_ray.w_y * right_x_a_y + preprocessed_ray.b_y;
    float right_entry_z = preprocessed_ray.w_z * right_x_a_z + preprocessed_ray.b_z;
    float right_exit_x  = preprocessed_ray.w_x * right_x_b_x + preprocessed_ray.b_x;
    float right_exit_y  = preprocessed_ray.w_y * right_x_b_y + preprocessed_ray.b_y;
    float right_exit_z  = preprocessed_ray.w_z * right_x_b_z + preprocessed_ray.b_z;

    float right_entry = my_fmax(my_fmax(right_entry_x, right_entry_y), my_fmax(right_entry_z, preprocessed_ray.tmin));
    float right_exit  = my_fmin(my_fmin(right_exit_x, right_exit_y), my_fmin(right_exit_z, preprocessed_ray.tmax));
    bool_t right_hit  = right_entry <= right_exit;

    bool_t left_first = left_entry <= right_entry; 

    bbox_resp_t bbox_resp = {
        .id = bbox_req.id,
        .left_hit = left_hit,
        .right_hit = right_hit,
        .left_first = left_first
    };
    bbox_resp_stream.write(bbox_resp);
}

#endif // RTCORE_HLS_BBOX_H