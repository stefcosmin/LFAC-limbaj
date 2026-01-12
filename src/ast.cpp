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
      if (equal(v.type_id, NType::INT))
        try
        {
          val.i = v.value.empty() ? 0 : std::stoi(v.value);
        }
        catch (...)
        {
          val.i = 0;
        }

      if (equal(v.type_id, NType::FLOAT))
        val.f = std::stof(v.value);
      if (equal(v.type_id, NType::BOOL))
        val.b = (v.value == "true");
      if (equal(v.type_id, NType::STRING))
        val.s = v.value;
      return val;
    }
    scope = scope->parent;
  }
  return Value::makeDefault(NType::INVALID);
}

Value ASTNode::evaluate(scope_node *scope)
{

  Value result;

  /* LEAF */
  if (kind == ASTKind::LEAF)
  {
    if (expr_type == NType::INT)
    {
      result.type = NType::INT;
      result.i = std::stoi(label);
    }
    else if (expr_type == NType::FLOAT)
    {
      result.type = NType::FLOAT;
      result.f = std::stof(label);
    }
    else if (expr_type == NType::BOOL)
    {
      result.type = NType::BOOL;
      result.b = (label == "true");
    }
    else if (expr_type == NType::STRING)
    {
      result.type = NType::STRING;
      result.s = label;
    }
    else
    {
      result = lookup_variable(scope, label);
    }

    std::cout << "[EVAL] " << to_string()
              << " => " << value_to_string(result) << '\n';

    return result;
  }

  /* ASSIGNMENT */
  if (kind == ASTKind::ASSIGN)
  {
    Value rhs = right->evaluate(scope);

    scope_node *s = scope;
    while (s)
    {
      auto it = s->var_map.find(left->label);
      if (it != s->var_map.end())
      {
        it->second.value = value_to_string(rhs);
        break;
      }
      s = s->parent;
    }

    std::cout << "[EVAL] " << to_string()
              << " => " << value_to_string(rhs) << '\n';

    return rhs;
  }

  /* PRINT */
  if (kind == ASTKind::PRINT)
  {
    Value v = left->evaluate(scope);
    std::cout << "[PRINT] ";
    v.print();
    std::cout << '\n';

    std::cout << "[EVAL] " << to_string()
              << " => " << value_to_string(v) << '\n';

    return v;
  }

  /* BINARY OPERATOR */
  Value l = left->evaluate(scope);
  Value r = right->evaluate(scope);

  if (label == "+")
  {
    result.type = l.type;
    if (l.type == NType::INT)
      result.i = l.i + r.i;
    if (l.type == NType::FLOAT)
      result.f = l.f + r.f;
  }
  else if (label == "*")
  {
    result.type = l.type;
    if (l.type == NType::INT)
      result.i = l.i * r.i;
    if (l.type == NType::FLOAT)
      result.f = l.f * r.f;
  }
  else if (label == "-")
  {
    result.type = l.type;
    if (l.type == NType::INT)
      result.i = l.i - r.i;
    if (l.type == NType::FLOAT)
      result.f = l.f - r.f;
  }
  else if (label == "/")
  {
    result.type = l.type;
    // Basic zero check for safety
    if (l.type == NType::INT)
    {
      if (r.i == 0)
        std::cerr << "Runtime Error: Division by zero\n";
      else
        result.i = l.i / r.i;
    }
    if (l.type == NType::FLOAT)
    {
      if (r.f == 0.0f)
        std::cerr << "Runtime Error: Division by zero\n";
      else
        result.f = l.f / r.f;
    }
  }

  std::cout << "[EVAL] " << to_string()
            << " => " << value_to_string(result) << '\n';

  return result;
}

std::string ASTNode::to_string() const
{
  if (kind == ASTKind::LEAF)
    return label;

  if (kind == ASTKind::ASSIGN)
    return left->to_string() + " := " + right->to_string();

  if (kind == ASTKind::PRINT)
    return "Print(" + left->to_string() + ")";

  // binary operator
  return "(" + left->to_string() + " " + label + " " + right->to_string() + ")";
}
