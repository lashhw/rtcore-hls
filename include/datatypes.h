#ifndef RTCORE_HLS_DATATYPES_H
#define RTCORE_HLS_DATATYPES_H

#include <ap_int.h>
#include "params.h"

typedef ap_uint<1> bool_t;
typedef ap_uint<ID_WIDTH> rid_t;
typedef ap_uint<NUM_TRIGS_WIDTH> num_trigs_t;
typedef ap_uint<CHILD_IDX_WIDTH> child_idx_t;
typedef ap_uint<STACK_SIZE_WIDTH> stack_size_t;

struct ray_t {
    float origin_x;
    float origin_y;
    float origin_z;
    float dir_x;
    float dir_y;
    float dir_z;
    float tmin;
    float tmax;
};

struct preprocessed_ray_t {
    float w_x;
    float w_y;
    float w_z;
    float b_x;
    float b_y;
    float b_z;
    float tmin;
    float tmax;
};

struct ray_and_preprocessed_ray_t {
    float origin_x;
    float origin_y;
    float origin_z;
    float dir_x;
    float dir_y;
    float dir_z;
    float w_x;
    float w_y;
    float w_z;
    float b_x;
    float b_y;
    float b_z;
    float tmin;
    float tmax;
};

struct trig_t {
    float p0_x;
    float p0_y;
    float p0_z;
    float e1_x;
    float e1_y;
    float e1_z;
    float e2_x;
    float e2_y;
    float e2_z;
};

struct node_t {
    num_trigs_t num_trigs;
    child_idx_t child_idx;
};

struct bbox_t {
    float x_min;
    float x_max;
    float y_min;
    float y_max;
    float z_min;
    float z_max;
};

// nbp: node bbox pair
struct nbp_t {
    node_t node[2];
    bbox_t bbox[2];
};

struct result_t {
    bool_t intersected;
    float t;
    float u;
    float v;
};

struct trv_local_mem_t {
    node_t stack_[STACK_SIZE];
    stack_size_t stack_size;
    ray_and_preprocessed_ray_t ray_and_preprocessed_ray;
    bool_t intersected;
    float u;
    float v;
};

struct trv_req_t {
    rid_t rid;
    ray_and_preprocessed_ray_t ray_and_preprocessed_ray;
};

struct trv_resp_t {
    rid_t rid;
    bool_t intersected;
    /* TODO: add intersected idx */
    float t;
    float u;
    float v;
};

struct bbox_ctrl_req_t {
    rid_t rid;
    preprocessed_ray_t preprocessed_ray;
    child_idx_t nbp_idx;
};

struct bbox_ctrl_resp_t {
    rid_t rid;
    bool_t left_hit;
    bool_t right_hit;
    bool_t left_first;
    node_t left_node;
    node_t right_node;
};

struct bbox_mem_req_t {
    rid_t rid;
    child_idx_t nbp_idx;
};

struct bbox_mem_resp_t {
    rid_t rid;
    nbp_t nbp;
};

struct bbox_req_t {
    rid_t rid;
    preprocessed_ray_t preprocessed_ray;
    bbox_t left_bbox;
    bbox_t right_bbox;
};

struct bbox_resp_t {
    rid_t rid;
    bool_t left_hit;
    bool_t right_hit;
    bool_t left_first;
};

struct ist_ctrl_req_t {
    rid_t rid;
    ray_t ray;
    num_trigs_t num_trigs;
    child_idx_t trig_idx;
};

struct ist_ctrl_resp_t {
    rid_t rid;
    bool_t intersected;
    float t;
    float u;
    float v;
};

struct ist_mem_req_t {
    rid_t rid;
    num_trigs_t num_trigs;
    child_idx_t trig_idx;
};

struct ist_mem_resp_t {
    rid_t rid;
    trig_t first_trig;
};

struct ist_req_t {
    rid_t rid;
    ray_t ray;
    trig_t trig;
};

struct ist_resp_t {
    rid_t rid;
    bool_t intersected;
    float t;
    float u;
    float v;
};

#endif // RTCORE_HLS_DATATYPES_H