#pragma once
#include "data.hpp"
#include <string>
#include <iostream>

struct Value
{
  VarType type = VarType::INVALID;
  int i;
  float f;
  bool b;
  std::string s;

  static Value makeDefault(VarType t)
  {
    Value v;
    v.type = t;
    return v;
  }

  void print() const
  {
    switch (type)
    {
    case VarType::INT:
      std::cout << i;
      break;
    case VarType::FLOAT:
      std::cout << f;
      break;
    case VarType::BOOL:
      std::cout << (b ? "true" : "false");
      break;
    case VarType::STRING:
      std::cout << s;
      break;
    default:
      break;
    }
  }
};
