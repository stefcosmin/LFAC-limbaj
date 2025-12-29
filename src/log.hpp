#pragma once
#define DEBUG 1
#include <iostream>

// would have called it log but it's reserved
// dsp stands for 'Display'
namespace dsp{
    static void debug(const char* str) {
#ifdef DEBUG
        std::cout << str << std::endl;
#endif
    }
}


