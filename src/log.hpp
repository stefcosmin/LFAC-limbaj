#pragma once
#define DEBUG 0
#include <iostream>

#include "data.hpp"
#include "type_codex.hpp"

// would have called it log but it's reserved
// dsp stands for 'Display'
namespace dsp{
    static void debug(const char* str) {
#ifdef DEBUG
        std::cout << str << std::endl;
#endif
    }
    static void print(const var_data& data, const type_codex& cdx) {
        std::cout << "Type: " << cdx.type_name(data.type_id) << '\n'
                  << " Name: " << data.name << '\n'
                  << " Value: " << data.value << '\n';
    }
    static std::string sprint(const var_data& data, const type_codex& cdx) {
        std::string stream;
        stream += "Type: ";
        stream += cdx.type_name(data.type_id);
        stream += " Name: ";
        stream += data.name;
        stream += " Value: ";
        stream += data.value;
        return stream;
    }
    static std::string parameter_str(const func_data& data, const type_codex& cdx) {
        std::string result;
        for(const auto& var : data.parameters){
            result += var.name + std::string(" : ");
            result += cdx.type_name(var.type_id);
            result += "  ";
        }
        return result;
    }
    static std::string sprint(const func_data& data, const type_codex& cdx) {
        std::string stream;
        stream += "Name: '" + data.name;
        stream += "'";
        stream += " Return type: ";
        stream += cdx.type_name(data.type_id);
        stream += " Parameters: " + parameter_str(data, cdx);
        return stream;
    }

    static std::string tab(int n){
        return std::string (n, '\t');
    }
    static void print(scope_node* n, const type_codex& cdx, int level = 0){
       std::cout << tab(level) << "Type name: " << n->type_name() << " Scope name: " << n->name << "\n";
       if(n->var_map.size()) {
           std::cout << tab(level) << "Variables: \n";
           for(const auto& [key, value] : n->var_map){
               std::cout << tab(level + 1) << sprint(value, cdx) << '\n';
           }
       }

       if(n->func_map.size()){
           std::cout << tab(level) << "Functions: \n";
           for(const auto& [key, value] : n->func_map){
               std::cout << tab(level + 1)  << sprint(value, cdx) << '\n';
           }
       }
       for(scope_node* child : n->children) {
           print(child, cdx, level + 1);
       }
    }
}


