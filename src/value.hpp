#pragma once
#include "type_codex.hpp"
#include <string>
#include <iostream>

struct Value
{
  NType type = NType::INVALID;
  int i;
  float f;
  bool b;
  std::string s;

  static Value makeDefault(NType t)
  {
    Value v;
    v.type = t;
    return v;
  }

  void print() const
  {
    switch (type)
    {
    case NType::INT:
      std::cout << i;
      break;
    case NType::FLOAT:
      std::cout << f;
      break;
    case NType::BOOL:
      std::cout << (b ? "true" : "false");
      break;
    case NType::STRING:
      std::cout << s;
      break;
    default:
      break;
    }
  }
};
