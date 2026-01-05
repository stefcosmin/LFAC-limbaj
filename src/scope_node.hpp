#pragma once
#include <string>
#include <unordered_map>
#include <vector>
#include <iostream>
#include <assert.h>

#include "data.hpp"


// TS stands for "tracked symbols"

enum class ScopeNodeType{
    DEFAULT, // default aka global scope/normal scope
    FUNCTION,
    CLASS
};

constexpr std::string_view sntype_names[] = {
    "default",
    "function",
    "class"
};


typedef ScopeNodeType SNType;


class scope_node{
    public:
        scope_node(SNType type0, const std::string& name0, scope_node* parent0 = nullptr)
            :type(type0), name(name0), parent(parent0)
        {
            std::cout << "Scope node\n";
        }
        ~scope_node() {
            for(scope_node* child : children) {
                delete child;
            }
        }
        bool variable_exists(const std::string& name) const{
            const scope_node* current = this;
            while(current != nullptr){
                auto it = current->var_map.find(name);
                if (it != current->var_map.end()) {
                    return true;
                }
                current = current->parent;
            }
            return false;
        }

        void add_func(const func_data& data){
            assert(type != SNType::FUNCTION &&
                "LOGIC ERROR: A function symbol should only be added to class scopes or global scopes");
            if(function_exists(data.name)) {
                std::string msg = "Redefinition of function '";
                msg += data.name;
                msg += "'";
                yyerror(msg.c_str());

                return;
            }

            std::cout << "Adding function '" << data.name << "'\n";
            func_map[data.name] = data;
        }
        void add_variable(const var_data& data, bool custom_type = false){
            if(custom_type == false && variable_exists(data.name)) {
                std::string msg = "Redefinition of variable '";
                msg += data.name;
                msg += "'";
                yyerror(msg.c_str());

                return;
            }
            var_map[data.name] = data;
        }
        void add_variables(const std::vector<var_data>& list){
            for(const auto& data : list){
                add_variable(data);
            }
        }
        void add_child(scope_node* node){
            children.emplace_back(node);
        } 
        const std::string_view type_name() const{
            return sntype_names[(int)type];
        }
        bool function_exists(const std::string& str) const {
            const scope_node* current = this;
            while(current != nullptr){
                auto it = current->func_map.find(str);
                if (it != current->func_map.end()) {
                    return true;
                }
                current = current->parent;
            }
            return false;
        }

       
    
        SNType type;
        std::string name;
        scope_node* parent;
        // name to variable map
        std::unordered_map<std::string, var_data> var_map;
        std::unordered_map<std::string, func_data> func_map;

        std::vector<scope_node*> children;
};
