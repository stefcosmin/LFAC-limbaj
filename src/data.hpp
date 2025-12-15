#include <iostream>
#include <string>
#include <string_view>
#include <unordered_map>
#include "constexpr_map.hpp"

extern void yyerror(const char* s);

enum class VarType{
    INT,
    BOOL,
    STRING,
    FLOAT,
    VOID, // vad cum facem pt proceduri
    COUNT,
    INVALID
};

constexpr std::string_view type_name_arr[] = {
    "int",
    "bool",
    "string",
    "float",
    "void"
};

constexpr constexpr_map<std::string_view, VarType, (size_t)VarType::COUNT> var_map = {
    std::make_pair("", VarType::INT),
    std::make_pair("", VarType::BOOL),
    std::make_pair("", VarType::STRING),
    std::make_pair("", VarType::FLOAT),
    std::make_pair("", VarType::VOID)
};

constexpr VarType name_to_type(const std::string_view view){
    auto it = var_map.at(view);
    if(it == var_map.end()){
        yyerror("Invalid variable type");
        return VarType::INVALID;
    }
    return it->second;
}


struct var_data{
    /* variables */
    VarType type;
    std::string name;
    std::string value;


    /* methods */ 
    var_data() = default;
    var_data(const std::string_view type0, const std::string_view name0, const std::string_view value0)
        :type(name_to_type(type0)), name(name0), value(value0)
    {}
    static std::string_view type_name(VarType type){
        return type_name_arr[(int)type];
    }   
    void print() const{
        std::cout << "Type: " << type_name(type) << '\n'
                  << "Name: " << name << '\n'
                  << "Value: " << value << '\n';
    }
    std::string sprint() const{
        std::string stream;
        stream += "Type: ";
        stream += type_name(type);
        stream += "Name: ";
        stream += name;
        stream += "Value: ";
        stream += value;
        return stream;
    }
};

struct func_data{
   VarType return_type; 
   std::string name;
   std::unordered_map<std::string, var_data> parameters;
    
   func_data() = default;
   std::string parameter_str() const {
        std::string result;
        for(const auto& [key, value] : parameters){
            result += key + std::string(" : ");
            result += var_data::type_name(value.type);
        }
        return result;
   }
   std::string sprint() const{
        std::string stream;
        stream += "Name: " + name;
        stream += " Return type: ";
        stream += var_data::type_name(return_type);
        stream += " Parameters: " + parameter_str();
        return stream;
   }
};

typedef var_data variable_data;
typedef func_data function_data;
