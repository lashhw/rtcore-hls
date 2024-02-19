#ifndef RTCORE_HLS_TB_RTCORE_H
#define RTCORE_HLS_TB_RTCORE_H

#include "rtcore_sim.h"

int main() {
    hls_thread_local hls::stream<trv_req_t> trv_req_stream;
    hls_thread_local hls::stream<trv_resp_t> trv_resp_stream;

    trv_req_t trv_req;
    trv_req_stream.write(trv_req);

    hls_thread_local hls::task t1(rtcore_sim, trv_req_stream, trv_resp_stream); 

    //trv_resp_t trv_resp;
    //trv_resp_stream.read(trv_resp);
}

#endif // RTCORE_HLS_TB_RTCORE_H