#ifndef RTCORE_HLS_GENTYPES_H
#define RTCORE_HLS_GENTYPES_H

struct generate_nbp_t {
    uint32_t left_node_num_trigs;
    uint32_t left_node_child_idx;
    uint32_t right_node_num_trigs;
    uint32_t right_node_child_idx;
    float left_bbox_x_min;
    float left_bbox_x_max;
    float left_bbox_y_min;
    float left_bbox_y_max;
    float left_bbox_z_min;
    float left_bbox_z_max;
    float right_bbox_x_min;
    float right_bbox_x_max;
    float right_bbox_y_min;
    float right_bbox_y_max;
    float right_bbox_z_min;
    float right_bbox_z_max;
};

struct generate_result_t {
    uint32_t intersected;
    float t;
    float u;
    float v;
};

#endif // RTCORE_HLS_GENTYPES_H