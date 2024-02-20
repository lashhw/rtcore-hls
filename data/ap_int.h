#ifndef RTCORE_HLS_AP_INT_H
#define RTCORE_HLS_AP_INT_H

template <size_t N>
using ap_uint = typename std::conditional<(N > 32), void,
                typename std::conditional<(N > 16), uint32_t,
                typename std::conditional<(N > 8), uint16_t, uint8_t>
                ::type>::type>::type;

#endif //RTCORE_HLS_AP_INT_H
