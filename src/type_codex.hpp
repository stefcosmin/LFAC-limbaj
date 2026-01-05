#pragma once
#include <string_view>
#include <string>
#include <stdint.h>
#include <limits>
#include "constexpr_map.hpp"
#include "scope_node.hpp"
extern void yyerror(const char* s);

//Native Type
enum class NType : uint16_t{
    INT,
    BOOL,
    STRING,
    FLOAT,
    VOID, 
    COUNT,
    INVALID
};

constexpr bool equal(uint16_t type_id, NType ntype) {
    return type_id == (uint16_t)ntype;
}
enum VarType{
    NATIVE,
    CUSTOM,
    INVALID
};
typedef NType NativeType;
constexpr std::string_view type_name_arr[] = {
    "int",
    "bool",
    "string",
    "float",
    "void",
};
constexpr constexpr_map<std::string_view, NType, (size_t)NType::COUNT> var_map = {
    std::make_pair("int", NType::INT),
    std::make_pair("bool", NType::BOOL),
    std::make_pair("string", NType::STRING),
    std::make_pair("float", NType::FLOAT),
    std::make_pair("void", NType::VOID),
};
static NType name_to_type(const std::string_view view){
    auto it = var_map.at(view);
    if(it == var_map.end()){
        std::string msg = std::string("Invalid variable type '") + std::string(view) + std::string("'");
        yyerror(msg.c_str());
        return NType::INVALID;
    }
    return it->second;
}
static void invalid_type_err(const std::string_view name){
    std::string msg = "Unrecognized type '";
    msg += name;
    msg += "'";
    yyerror(msg.c_str());
}
struct custom_type_data{
    uint16_t id;
    scope_node* details;
};
class type_codex{
    public:
        static constexpr uint16_t invalid_t = std::numeric_limits<uint16_t>::max();
        static constexpr std::string_view invalid_t_name = "INVALID";
        static constexpr uint16_t custom_t_id_start = 10;
    public:
        type_codex()
            // all class IDs start from 10
            :next_id(custom_t_id_start)
        {}
        void add(const std::string& name, scope_node* data){
            if(class_exists(name)) {
                std::string msg = "Redefinition of class '";
                msg += name;
                msg += "'";
                yyerror(msg.c_str());
                return;
            }
            table[name] = custom_type_data{next_id, data};
            next_id++;
        }
        uint16_t class_exists(const std::string& name) const {
            auto it = table.find(name);
            if(it != table.end()) {
                return it->second.id;
            }
            return invalid_t;
        }
        uint16_t type_id(const std::string& type_name)const {
            auto id = class_exists(type_name);
            if(id != invalid_t){
                return id;
            }
            id = native_exists(type_name);
            if(id != invalid_t) {
                return id;
            }
            return invalid_t;
        }
        std::string_view type_name(uint16_t id) const { 
            if(id < (uint16_t)NType::COUNT){
                return type_name_arr[id];
            }
            auto it = name_map.find(id);
            if(it != name_map.end()) {
                return it->second;
            }
            
            return invalid_t_name;
        }
        static uint16_t native_exists(const std::string& name) {
            auto it = var_map.at(name);
            if(it != var_map.end()) {
                return (uint16_t)it->second;
            }
            return invalid_t;
        }
        std::unordered_map<std::string, custom_type_data> table;
        std::unordered_map<uint16_t, std::string> name_map;
        uint16_t next_id;
};
