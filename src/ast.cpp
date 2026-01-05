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
      val.type = (NType)v.type_id;
      if (equal(v.type_id,NType::INT))
        val.i = std::stoi(v.value);
      if (equal(v.type_id,NType::FLOAT))
        val.f = std::stof(v.value);
      if (equal(v.type_id,NType::BOOL))
        val.b = (v.value == "true");
      if (equal(v.type_id,NType::STRING))
        val.s = v.value;
      return val;
    }
    scope = scope->parent;
  }
  return Value::makeDefault(NType::INVALID);
}

Value ASTNode::evaluate(scope_node *scope)
{

  /* LEAF */
  if (kind == ASTKind::LEAF)
  {
    if (expr_type == NType::INT)
    {
      Value v;
      v.type = NType::INT;
      v.i = std::stoi(label);
      return v;
    }
    if (expr_type == NType::FLOAT)
    {
      Value v;
      v.type = NType::FLOAT;
      v.f = std::stof(label);
      return v;
    }
    if (expr_type == NType::BOOL)
    {
      Value v;
      v.type = NType::BOOL;
      v.b = (label == "true");
      return v;
    }
    if (expr_type == NType::STRING)
    {
      Value v;
      v.type = NType::STRING;
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
            (rhs.type == NType::INT ? std::to_string(rhs.i) : rhs.type == NType::FLOAT ? std::to_string(rhs.f)
                                                            : rhs.type == NType::BOOL    ? (rhs.b ? "true" : "false")
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
    if (l.type == NType::INT)
    {
      Value v;
      v.type = NType::INT;
      v.i = l.i + r.i;
      return v;
    }
    if (l.type == NType::FLOAT)
    {
      Value v;
      v.type = NType::FLOAT;
      v.f = l.f + r.f;
      return v;
    }
  }

  if (label == "*")
  {
    if (l.type == NType::INT)
    {
      Value v;
      v.type = NType::INT;
      v.i = l.i * r.i;
      return v;
    }
    if (l.type == NType::FLOAT)
    {
      Value v;
      v.type = NType::FLOAT;
      v.f = l.f * r.f;
      return v;
    }
  }

  return Value::makeDefault(expr_type);
}
