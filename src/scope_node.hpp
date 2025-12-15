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
        scope_node(SNType type0, const std::string& name0)
            :type(type0), name(name0)
        {
            std::cout << "Scope node\n";
        }
        bool variable_exists(const std::string_view name) const;

        void add_function(const func_data& data){
            assert(type != SNType::DEFAULT &&
                "LOGIC ERROR: A function symbol should only be added to class scopes or global scopes");

            func_map[data.name] = data;
        }
        void add_variable(const var_data& data){
            var_map[data.name] = data;
        }
        void add_child(scope_node* node){
            children.emplace_back(node);
        } 
        const std::string_view type_name() const{
            return sntype_names[(int)type];
        }
        static void print(scope_node* n, int level = 0){
           std::cout << tab(level) << "Type name: " << n->type_name() << "Scope name: " << n->name << "\n";
           if(n->var_map.size()) {
               std::cout << tab(level) << "Variables: \n";
               for(const auto& [key, value] : n->var_map){
                   std::cout << tab(level + 1) << value.sprint() << '\n';
               }
           }

           if(n->func_map.size()){
               std::cout << tab(level) << "Functions: \n";
               for(const auto& [key, value] : n->func_map){
                   std::cout << tab(level + 1)  << value.sprint() << '\n';
               }
           }
        }
        static std::string tab(int n){
            return std::string (n, '\t');
        }
    private:
        SNType type;
        std::string name;
        scope_node* parent;
        // name to variable map
        std::unordered_map<std::string, var_data> var_map;
        std::unordered_map<std::string, func_data> func_map;

        std::vector<scope_node*> children;
};
