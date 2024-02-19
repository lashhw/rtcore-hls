#ifndef RTCORE_HLS_IST_MEM_SIM_H
#define RTCORE_HLS_IST_MEM_SIM_H

void ist_mem_sim(/* in  */ hls::stream<ist_mem_req_t>& ist_mem_req_stream,
                 /* out */ hls::stream<ist_mem_resp_t>& ist_mem_resp_stream,
                 /* out */ trig_t trig_[MAX_TRIGS_PER_NODE - 1][NUM_CONCURRENT_RAYS]) {
    
}

#endif // RTCORE_HLS_IST_MEM_SIM_H