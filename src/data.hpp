#include <iostream>
#include <string>
#include <string_view>
#include <vector>
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
    std::make_pair("int", VarType::INT),
    std::make_pair("bool", VarType::BOOL),
    std::make_pair("string", VarType::STRING),
    std::make_pair("float", VarType::FLOAT),
    std::make_pair("void", VarType::VOID)
};


static VarType name_to_type(const std::string_view view){
    auto it = var_map.at(view);
    if(it == var_map.end()){
        std::string msg = std::string("Invalid variable type '") + std::string(view) + std::string("'");
        yyerror(msg.c_str());
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
                  << " Name: " << name << '\n'
                  << " Value: " << value << '\n';
    }
    std::string sprint() const{
        std::string stream;
        stream += "Type: ";
        stream += type_name(type);
        stream += " Name: ";
        stream += name;
        stream += " Value: ";
        stream += value;
        return stream;
    }
};

struct func_data{
   VarType return_type; 
   std::string name;
   std::vector<var_data> parameters;
    
   func_data() = default;
   // trebuie updatat ca sa fie adaugati si parametri. Dar mai tz
   func_data(const std::string_view ret, const std::string_view name0, const std::vector<var_data>& param)
       :return_type(name_to_type(ret)), name(name0), parameters(param)
   {
   }
   std::string parameter_str() const {
        std::string result;
        for(const auto& var : parameters){
            result += var.name + std::string(" : ");
            result += var_data::type_name(var.type);
            result += "  ";
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
