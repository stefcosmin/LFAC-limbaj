#pragma once
#include <string>
#include <string_view>
#include <vector>
#include <stdint.h>
#include "constexpr_map.hpp"

extern void yyerror(const char* s);

struct var_data{
    /* variables */
    uint16_t type_id;
    std::string name;
    std::string value;


    /* methods */ 
    var_data() = default;
    var_data(uint16_t type_id, const std::string_view name0, const std::string_view value0)
        :type_id(type_id), name(name0), value(value0)
    {}
};

struct func_data{
   uint16_t type_id; 
   std::string name;
   std::vector<var_data> parameters;
    
   func_data() = default;
   // trebuie updatat ca sa fie adaugati si parametri. Dar mai tz
   func_data(uint16_t type_id, const std::string_view name0, const std::vector<var_data>& param)
       :type_id(type_id), name(name0), parameters(param)
   {}
};

typedef var_data variable_data;
typedef func_data function_data;
