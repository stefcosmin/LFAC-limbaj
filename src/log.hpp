#pragma once
#define DEBUG 0
#include <iostream>
#include <sstream>

#include "data.hpp"
#include "type_codex.hpp"

// would have called it log but it's reserved
// dsp stands for 'Display'
namespace dsp{
    enum Color{
        RED = 31,
        GREEN = 32,
        YELLOW = 33,
        MAGENTA = 35,
        CYAN = 36,
        WHITE = 37
    };

    static void debug(const char* str) {
#ifdef DEBUG
        std::cout << str << std::endl;
#endif
    }

    static std::string sprint_colored(const std::string_view msg, Color color){
        std::stringstream ss;
        ss << "\033[" << color << "m" << msg << "\033[0m";
        return ss.str();
    }
    static void print(const var_data& data, const type_codex& cdx) {
        std::cout << "Type: " << cdx.type_name(data.type_id) << '\n'
                  << " Name: " << data.name << '\n'
                  << " Value: " << data.value << '\n';
    }
    static std::string sprint(const var_data& data, const type_codex& cdx) {
        std::string stream;
        stream += sprint_colored(cdx.type_name(data.type_id), Color::CYAN);
        stream += " ";
        stream += data.name;
        stream += " Value: ";
        stream += data.value;
        return stream;
    }
    static std::string parameter_str(const func_data& data, const type_codex& cdx) {
        std::string result = "{ ";
        for(const auto& var : data.parameters){
            result += var.name + std::string(" : ");
            result += sprint_colored(cdx.type_name(var.type_id), Color::CYAN);
            result += "  ";
        }
        result += "}";
        return result;
    }


    static std::string sprint(const func_data& data, const type_codex& cdx) {
        std::string stream;
        stream += sprint_colored("function ", Color::MAGENTA) + data.name;
        stream += " --> ";
        stream += sprint_colored(cdx.type_name(data.type_id), Color::CYAN);
        stream += " Parameters: " + parameter_str(data, cdx);
        return stream;
    }

    static std::string tab(int n){
        return std::string (n, '\t');
    }
    static void print(scope_node* n, const type_codex& cdx, int level = 0){
       std::cout << tab(level) << sprint_colored(n->type_name(), Color::MAGENTA) << " " << sprint_colored(n->name, Color::YELLOW) << "\n";
       if(n->var_map.size()) {
           std::cout << tab(level + 1) << "Variables: \n";
           for(const auto& [key, value] : n->var_map){
               std::cout << tab(level + 2) << sprint(value, cdx) << '\n';
           }
       }

       if(n->func_map.size()){
           std::cout << tab(level + 1) << "Functions: \n";
           for(const auto& [key, value] : n->func_map){
               std::cout << tab(level + 2)  << sprint(value, cdx) << '\n';
           }
       }
       for(scope_node* child : n->children) {
           print(child, cdx, level + 1);
       }
    }
    static void print(const type_codex& cdx) {
        std::cout << "Custom types: \n";
        for( const auto& [id, name] : cdx.name_map ) {
            std::cout << id << " ---> " << name;
        }
    }

}


