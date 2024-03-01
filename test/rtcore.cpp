#include <cassert>
#include <cstdio>
#include <cstdint>
#include <fcntl.h>
#include <fstream>
#include <iostream>
#include <sys/mman.h>
#include <unistd.h>

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

struct generate_result_t {
    uint32_t intersected;
    float t;
    float u;
    float v;
};

enum dma_type_t {
    MM2S, S2MM
};

uint64_t dma_baseaddr = 0x0A0000000;

uint64_t nbp_baseaddr    = 0x800000000;
uint64_t trig_baseaddr   = 0x840000000;
uint64_t ray_baseaddr    = 0x880000000;
uint64_t result_baseaddr = 0x8C0000000;

size_t dma_size    = 0x10000;
size_t nbp_size    = 0x10000000;
size_t trig_size   = 0x10000000;
size_t ray_size    = 0x10000000;
size_t result_size = 0x10000000;

void write_dma_ctrl(dma_type_t dma_type,
                    void* dma_ptr,
                    uint64_t target_addr,
                    uint32_t length) {
    void* ptr;

    // MM2S_DMACR/S2MM_DMACR
    ptr = dma_ptr + (dma_type == MM2S ? 0x00 : 0x30);
    *(volatile uint32_t*)ptr = 0x00011003;

    // MM2S_SA/S2MM_DA
    ptr = dma_ptr + (dma_type == MM2S ? 0x18 : 0x48);
    *(volatile uint32_t*)ptr = target_addr;

    // MM2S_SA_MSB/S2MM_DA_MSB
    ptr = dma_ptr + (dma_type == MM2S ? 0x1C : 0x4C);
    *(volatile uint32_t*)ptr = (target_addr >> 32);

    // MM2S_LENGTH/S2MM_LENGTH
    ptr = dma_ptr + (dma_type == MM2S ? 0x28 : 0x58);
    *(volatile uint32_t*)ptr = length;

    // poll MM2S_DMASR/S2MM_DMASR
    while (true) {
        ptr = dma_ptr + (dma_type == MM2S ? 0x04 : 0x34);
        if ((*(volatile uint32_t*)ptr) & (1 << 12))
            break;
    }

    // clear MM2S_DMASR/S2MM_DMASR
    ptr = dma_ptr + (dma_type == MM2S ? 0x04 : 0x34);
    *(volatile uint32_t*)ptr = 0xFFFFFFFF;
}

int main() {
    // open /dev/mem
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    assert(fd != -1);

    // mmap
    void* dma_ptr    = mmap(NULL, dma_size,    PROT_READ | PROT_WRITE, MAP_SHARED, fd, dma_baseaddr);
    void* nbp_ptr    = mmap(NULL, nbp_size,    PROT_READ | PROT_WRITE, MAP_SHARED, fd, nbp_baseaddr);
    void* trig_ptr   = mmap(NULL, trig_size,   PROT_READ | PROT_WRITE, MAP_SHARED, fd, trig_baseaddr);
    void* ray_ptr    = mmap(NULL, ray_size,    PROT_READ | PROT_WRITE, MAP_SHARED, fd, ray_baseaddr);
    void* result_ptr = mmap(NULL, result_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, result_baseaddr);
    assert(dma_ptr    != MAP_FAILED);
    assert(nbp_ptr    != MAP_FAILED);
    assert(trig_ptr   != MAP_FAILED);
    assert(ray_ptr    != MAP_FAILED);
    assert(result_ptr != MAP_FAILED);

    std::ifstream generate_nbp_fs("generate_nbp.bin", std::ios::binary);
    assert(generate_nbp_fs.good());
    generate_nbp_t generate_nbp;
    for (int i = 0; generate_nbp_fs.read((char*)(&generate_nbp), sizeof(generate_nbp_t)); i++) {
        *(volatile uint32_t*)(nbp_ptr + i * 56 + 0)  = (generate_nbp.left_node_child_idx << 3) | generate_nbp.left_node_num_trigs;
        *(volatile uint32_t*)(nbp_ptr + i * 56 + 4)  = (generate_nbp.right_node_child_idx << 3) | generate_nbp.right_node_num_trigs;
        *(volatile float*   )(nbp_ptr + i * 56 + 8)  = generate_nbp.left_bbox_x_min;
        *(volatile float*   )(nbp_ptr + i * 56 + 12) = generate_nbp.left_bbox_x_max;
        *(volatile float*   )(nbp_ptr + i * 56 + 16) = generate_nbp.left_bbox_y_min;
        *(volatile float*   )(nbp_ptr + i * 56 + 20) = generate_nbp.left_bbox_y_max;
        *(volatile float*   )(nbp_ptr + i * 56 + 24) = generate_nbp.left_bbox_z_min;
        *(volatile float*   )(nbp_ptr + i * 56 + 28) = generate_nbp.left_bbox_z_max;
        *(volatile float*   )(nbp_ptr + i * 56 + 32) = generate_nbp.right_bbox_x_min;
        *(volatile float*   )(nbp_ptr + i * 56 + 36) = generate_nbp.right_bbox_x_max;
        *(volatile float*   )(nbp_ptr + i * 56 + 40) = generate_nbp.right_bbox_y_min;
        *(volatile float*   )(nbp_ptr + i * 56 + 44) = generate_nbp.right_bbox_y_max;
        *(volatile float*   )(nbp_ptr + i * 56 + 48) = generate_nbp.right_bbox_z_min;
        *(volatile float*   )(nbp_ptr + i * 56 + 52) = generate_nbp.right_bbox_z_max;
    }

    std::ifstream trig_fs("trig.bin", std::ios::binary);
    assert(trig_fs.good());
    trig_t trig;
    for (int i = 0; trig_fs.read((char*)(&trig), sizeof(trig_t)); i++) {
        *(volatile float*)(trig_ptr + i * 36 + 0)  = trig.p0_x;
        *(volatile float*)(trig_ptr + i * 36 + 4)  = trig.p0_y;
        *(volatile float*)(trig_ptr + i * 36 + 8)  = trig.p0_z;
        *(volatile float*)(trig_ptr + i * 36 + 12) = trig.e1_x;
        *(volatile float*)(trig_ptr + i * 36 + 16) = trig.e1_y;
        *(volatile float*)(trig_ptr + i * 36 + 20) = trig.e1_z;
        *(volatile float*)(trig_ptr + i * 36 + 24) = trig.e2_x;
        *(volatile float*)(trig_ptr + i * 36 + 28) = trig.e2_y;
        *(volatile float*)(trig_ptr + i * 36 + 32) = trig.e2_z;
    }

    std::ifstream ray_fs("ray.bin", std::ios::binary);
    std::ifstream generate_result_fs("generate_result.bin", std::ios::binary);
    assert(ray_fs.good());
    assert(generate_result_fs.good());
    ray_t ray;
    generate_result_t generate_result;
    int num_correct = 0;
    for (int i = 0; ray_fs.read((char*)(&ray), sizeof(ray_t)); i++) {
        assert(generate_result_fs.read((char*)(&generate_result), sizeof(generate_result_t)));
        *(volatile float*)(ray_ptr + i * 32 + 0 ) = ray.origin_x;
        *(volatile float*)(ray_ptr + i * 32 + 4 ) = ray.origin_y;
        *(volatile float*)(ray_ptr + i * 32 + 8 ) = ray.origin_z;
        *(volatile float*)(ray_ptr + i * 32 + 12) = ray.dir_x;
        *(volatile float*)(ray_ptr + i * 32 + 16) = ray.dir_y;
        *(volatile float*)(ray_ptr + i * 32 + 20) = ray.dir_z;
        *(volatile float*)(ray_ptr + i * 32 + 24) = ray.tmin;
        *(volatile float*)(ray_ptr + i * 32 + 28) = ray.tmax;

        write_dma_ctrl(MM2S, dma_ptr, ray_baseaddr + i * 32, 32);
        write_dma_ctrl(S2MM, dma_ptr, result_baseaddr + i * 16, 16);

        uint32_t intersected = *(volatile uint32_t*)(result_ptr + i * 16 + 0);
        float t              = *(volatile float*   )(result_ptr + i * 16 + 4);
        float u              = *(volatile float*   )(result_ptr + i * 16 + 8);
        float v              = *(volatile float*   )(result_ptr + i * 16 + 12);

        bool correct = false;
        if (generate_result.intersected) {
            if (intersected && generate_result.t == t && generate_result.u == u && generate_result.v == v)
                correct = true;
        } else {
            if (!intersected)
                correct = true;
        }

        if (correct) {
            num_correct++;
        } else {
            printf("i: %d <=> %d\n", generate_result.intersected, intersected);
            printf("t: %f <=> %f\n", generate_result.t, t);
            printf("u: %f <=> %f\n", generate_result.u, u);
            printf("v: %f <=> %f\n", generate_result.v, v);
        }
    }
    printf("num_correct: %d\n", num_correct);

    // munmap
    assert(munmap(dma_ptr, dma_size) == 0);
    assert(munmap(nbp_ptr, nbp_size) == 0);
    assert(munmap(trig_ptr, trig_size) == 0);
    assert(munmap(ray_ptr, ray_size) == 0);
    assert(munmap(result_ptr, result_size) == 0);
}