#pragma once
#include "type_codex.hpp"
#include <cstring>
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

inline std::string value_to_string(const Value &v)
{
  switch (v.type)
  {
  case NType::INT:
    return std::to_string(v.i);
  case NType::FLOAT:
    return std::to_string(v.f);
  case NType::BOOL:
    return v.b ? "true" : "false";
  case NType::STRING:
    return v.s;
  case NType::VOID:
    return "void";
  case NType::INVALID:
    return "invalid";
  }
}
