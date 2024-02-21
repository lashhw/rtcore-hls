#include <iostream>
#include <random>
#include <bvh/bvh.hpp>
#include <bvh/triangle.hpp>
#include <bvh/sweep_sah_builder.hpp>
#include <bvh/single_ray_traverser.hpp>
#include <bvh/primitive_intersectors.hpp>
#include <happly.h>
#include "../include/datatypes.h"
#include "gentypes.h"

#define NUM_TEST_RAYS 10000

typedef bvh::Bvh<float> bvh_t;
typedef bvh::Triangle<float> bvh_trig_t;
typedef bvh::Ray<float> bvh_ray_t;
typedef bvh::Vector<float, 3> vector_t;
typedef bvh::SweepSahBuilder<bvh_t> builder_t;
typedef bvh::SingleRayTraverser<bvh_t> traverser_t;
typedef bvh::ClosestPrimitiveIntersector<bvh_t, bvh_trig_t> primitive_intersector_t;

int main() {
    happly::PLYData ply_data("bun_zipper_res4.ply");
    std::vector<std::array<double, 3>> v_pos = ply_data.getVertexPositions();
    std::vector<std::vector<size_t>> f_idx = ply_data.getFaceIndices<size_t>();

    std::vector<bvh_trig_t> bvh_trig_;
    for (auto &face : f_idx) {
        bvh_trig_.emplace_back(
            vector_t((float)v_pos[face[0]][0], (float)v_pos[face[0]][1], (float)v_pos[face[0]][2]),
            vector_t((float)v_pos[face[1]][0], (float)v_pos[face[1]][1], (float)v_pos[face[1]][2]),
            vector_t((float)v_pos[face[2]][0], (float)v_pos[face[2]][1], (float)v_pos[face[2]][2])
        );
    }

    auto [bboxes, centers] = bvh::compute_bounding_boxes_and_centers(bvh_trig_.data(), bvh_trig_.size());
    auto global_bbox = bvh::compute_bounding_boxes_union(bboxes.get(), bvh_trig_.size());
    std::cout << "global_bbox = ("
              << global_bbox.min[0] << ", " << global_bbox.min[1] << ", " << global_bbox.min[2] << "), ("
              << global_bbox.max[0] << ", " << global_bbox.max[1] << ", " << global_bbox.max[2] << ")" << std::endl;

    bvh_t bvh;
    builder_t builder(bvh);
    builder.max_leaf_size = MAX_TRIGS_PER_NODE;
    builder.build(global_bbox, bboxes.get(), centers.get(), bvh_trig_.size());

    vector_t bbox_center;
    for (int i = 0; i < 3; i++)
        bbox_center[i] = (global_bbox.min[i] + global_bbox.max[i]) / 2.0f;

    vector_t bbox_length;
    for (int i = 0; i < 3; i++)
        bbox_length[i] = global_bbox.max[i] - global_bbox.min[i];

    vector_t ray_region_min;
    for (int i = 0; i < 3; i++)
        ray_region_min[i] = bbox_center[i] - bbox_length[i];

    vector_t ray_region_max;
    for (int i = 0; i < 3; i++)
        ray_region_max[i] = bbox_center[i] + bbox_length[i];

    std::mt19937 gen;
    std::uniform_real_distribution<float> dis_x(ray_region_min[0], ray_region_max[0]);
    std::uniform_real_distribution<float> dis_y(ray_region_min[1], ray_region_max[1]);
    std::uniform_real_distribution<float> dis_z(ray_region_min[2], ray_region_max[2]);
    std::uniform_real_distribution<float> dis_dir(-1.0f, 1.0f);

    traverser_t traverser(bvh);
    primitive_intersector_t primitive_intersector(bvh, bvh_trig_.data());

    ray_t ray_[NUM_TEST_RAYS];
    generate_result_t result_[NUM_TEST_RAYS];
    for (int i = 0; i < NUM_TEST_RAYS; i++) {
        ray_t ray = {
            .origin_x = dis_x(gen),
            .origin_y = dis_y(gen),
            .origin_z = dis_z(gen),
            .dir_x    = dis_dir(gen),
            .dir_y    = dis_dir(gen),
            .dir_z    = dis_dir(gen),
            .tmin     = 0.0f,
            .tmax     = std::numeric_limits<float>::max()
        };
        ray_[i] = ray;

        bvh_ray_t bvh_ray;
        bvh_ray.origin[0]    = ray.origin_x;
        bvh_ray.origin[1]    = ray.origin_y;
        bvh_ray.origin[2]    = ray.origin_z;
        bvh_ray.direction[0] = ray.dir_x;
        bvh_ray.direction[1] = ray.dir_y;
        bvh_ray.direction[2] = ray.dir_z;
        bvh_ray.tmin         = ray.tmin;
        bvh_ray.tmax         = ray.tmax;

        auto result = traverser.traverse(bvh_ray, primitive_intersector);
        if (result.has_value()) {
            result_[i].intersected = 1;
            result_[i].t           = result->intersection.t;
            result_[i].u           = result->intersection.u;
            result_[i].v           = result->intersection.v;
        } else {
            result_[i].intersected = 0;
        }
    }

    int nbp_s_size = (int)bvh.node_count / 2;
    generate_nbp_t nbp_[nbp_s_size];
    assert(bvh.node_count % 2 == 1);
    for (int i = 1; i < nbp_s_size; i += 2) {
        generate_nbp_t nbp = {
            .left_node_num_trigs  = bvh.nodes[i].primitive_count,
            .left_node_child_idx  = bvh.nodes[i].first_child_or_primitive,
            .right_node_num_trigs = bvh.nodes[i + 1].primitive_count,
            .right_node_child_idx = bvh.nodes[i + 1].first_child_or_primitive,
            .left_bbox_x_min      = bvh.nodes[i].bounds[0],
            .left_bbox_x_max      = bvh.nodes[i].bounds[1],
            .left_bbox_y_min      = bvh.nodes[i].bounds[2],
            .left_bbox_y_max      = bvh.nodes[i].bounds[3],
            .left_bbox_z_min      = bvh.nodes[i].bounds[4],
            .left_bbox_z_max      = bvh.nodes[i].bounds[5],
            .right_bbox_x_min     = bvh.nodes[i + 1].bounds[0],
            .right_bbox_x_max     = bvh.nodes[i + 1].bounds[1],
            .right_bbox_y_min     = bvh.nodes[i + 1].bounds[2],
            .right_bbox_y_max     = bvh.nodes[i + 1].bounds[3],
            .right_bbox_z_min     = bvh.nodes[i + 1].bounds[4],
            .right_bbox_z_max     = bvh.nodes[i + 1].bounds[5],
        };

        if (nbp.left_node_num_trigs == 0) {
            assert(nbp.left_node_child_idx % 2 == 1);
            nbp.left_node_child_idx /= 2;
        }
        if (nbp.right_node_num_trigs == 0) {
            assert(nbp.right_node_child_idx % 2 == 1);
            nbp.right_node_child_idx /= 2;
        }

        nbp_[i / 2] = nbp;
    }

    int trig_s_size = (int)bvh_trig_.size();
    trig_t trig_[trig_s_size];
    for (int i = 0; i < trig_s_size; i++) {
        trig_[i] = {
            .p0_x = bvh_trig_[i].p0[0],
            .p0_y = bvh_trig_[i].p0[1],
            .p0_z = bvh_trig_[i].p0[2],
            .e1_x = bvh_trig_[i].e1[0],
            .e1_y = bvh_trig_[i].e1[1],
            .e1_z = bvh_trig_[i].e1[2],
            .e2_x = bvh_trig_[i].e2[0],
            .e2_y = bvh_trig_[i].e2[1],
            .e2_z = bvh_trig_[i].e2[2]
        };
    }

    std::ofstream nbp_stream("nbp.bin", std::ios::binary);
    for (int i = 0; i < nbp_s_size; i++)
        nbp_stream.write((char*)(&nbp_[i]), sizeof(generate_nbp_t));

    std::ofstream trig_stream("trig.bin", std::ios::binary);
    for (int i = 0; i < trig_s_size; i++)
        trig_stream.write((char*)(&trig_[i]), sizeof(trig_t));

    std::ofstream ray_stream("ray.bin", std::ios::binary);
    for (auto &ray : ray_)
        ray_stream.write((char*)(&ray), sizeof(ray_t));

    std::ofstream result_stream("result.bin", std::ios::binary);
    for (auto &result : result_)
        result_stream.write((char*)(&result), sizeof(generate_result_t));

    return 0;
}