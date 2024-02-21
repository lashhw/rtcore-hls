#ifndef RTCORE_HLS_IST_MEM_SIM_H
#define RTCORE_HLS_IST_MEM_SIM_H

void ist_mem_sim(/* in  */ hls::stream<ist_mem_req_t>& ist_mem_req_stream,
                 /* out */ hls::stream<ist_mem_resp_t>& ist_mem_resp_stream,
                 /* out */ trig_t trig_[MAX_TRIGS_PER_NODE - 1][NUM_CONCURRENT_RAYS]) {
    static bool initialized = false;
    static std::vector<trig_t> trig_mem;
    if (!initialized) {
        std::ifstream trig_stream(RTCORE_HLS_PREFIX"rtcore-hls/data/trig.bin", std::ios::binary);
        assert(trig_stream.good());
        for (trig_t trig; trig_stream.read((char*)(&trig), sizeof(trig_t)); )
            trig_mem.push_back(trig);
        initialized = true;
    }
    
    ist_mem_req_t ist_mem_req;
    if (!ist_mem_req_stream.read_nb(ist_mem_req))
        return;
    assert(ist_mem_req.num_trigs > 0);
    for (int i = ist_mem_req.num_trigs - 1; i > 0; i--)
        trig_[i - 1][ist_mem_req.rid] = trig_mem[ist_mem_req.trig_idx + i];
    ist_mem_resp_t ist_mem_resp = {
        .rid = ist_mem_req.rid,
        .first_trig = trig_mem[ist_mem_req.trig_idx]
    };
    ist_mem_resp_stream.write(ist_mem_resp);
}

#endif // RTCORE_HLS_IST_MEM_SIM_H