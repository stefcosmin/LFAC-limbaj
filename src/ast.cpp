#include "ast.hpp"

static Value lookup_variable(scope_node *scope, const std::string &name)
{
  while (scope)
  {
    auto it = scope->var_map.find(name);
    if (it != scope->var_map.end())
    {
      const var_data &v = it->second;
      Value val;
      val.type = v.type;
      if (v.type == VarType::INT)
        val.i = std::stoi(v.value);
      if (v.type == VarType::FLOAT)
        val.f = std::stof(v.value);
      if (v.type == VarType::BOOL)
        val.b = (v.value == "true");
      if (v.type == VarType::STRING)
        val.s = v.value;
      return val;
    }
    scope = scope->parent;
  }
  return Value::makeDefault(VarType::INVALID);
}

Value ASTNode::evaluate(scope_node *scope)
{

  /* LEAF */
  if (kind == ASTKind::LEAF)
  {
    if (expr_type == VarType::INT)
    {
      Value v;
      v.type = VarType::INT;
      v.i = std::stoi(label);
      return v;
    }
    if (expr_type == VarType::FLOAT)
    {
      Value v;
      v.type = VarType::FLOAT;
      v.f = std::stof(label);
      return v;
    }
    if (expr_type == VarType::BOOL)
    {
      Value v;
      v.type = VarType::BOOL;
      v.b = (label == "true");
      return v;
    }
    if (expr_type == VarType::STRING)
    {
      Value v;
      v.type = VarType::STRING;
      v.s = label;
      return v;
    }

    /* identifier */
    return lookup_variable(scope, label);
  }

  /* ASSIGN */
  if (kind == ASTKind::ASSIGN)
  {
    Value rhs = right->evaluate(scope);

    scope_node *s = scope;
    while (s)
    {
      auto it = s->var_map.find(left->label);
      if (it != s->var_map.end())
      {
        it->second.value =
            (rhs.type == VarType::INT ? std::to_string(rhs.i) : rhs.type == VarType::FLOAT ? std::to_string(rhs.f)
                                                            : rhs.type == VarType::BOOL    ? (rhs.b ? "true" : "false")
                                                                                           : rhs.s);
        return rhs;
      }
      s = s->parent;
    }
  }

  /* PRINT */
  if (kind == ASTKind::PRINT)
  {
    Value v = left->evaluate(scope);
    v.print();
    std::cout << '\n';
    return v;
  }

  /* BINARY */
  Value l = left->evaluate(scope);
  Value r = right->evaluate(scope);

  if (label == "+")
  {
    if (l.type == VarType::INT)
    {
      Value v;
      v.type = VarType::INT;
      v.i = l.i + r.i;
      return v;
    }
    if (l.type == VarType::FLOAT)
    {
      Value v;
      v.type = VarType::FLOAT;
      v.f = l.f + r.f;
      return v;
    }
  }

  if (label == "*")
  {
    if (l.type == VarType::INT)
    {
      Value v;
      v.type = VarType::INT;
      v.i = l.i * r.i;
      return v;
    }
    if (l.type == VarType::FLOAT)
    {
      Value v;
      v.type = VarType::FLOAT;
      v.f = l.f * r.f;
      return v;
    }
  }

  return Value::makeDefault(expr_type);
}
