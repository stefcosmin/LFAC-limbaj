#pragma once
#include <memory>
#include <string>
#include "value.hpp"
#include "scope_node.hpp"

enum class ASTKind
{
  LEAF,
  UNARY,
  BINARY,
  ASSIGN,
  PRINT
};

class ASTNode
{
public:
  ASTKind kind;
  std::string label; // operator / literal / identifier
  NType expr_type;

  std::unique_ptr<ASTNode> left;
  std::unique_ptr<ASTNode> right;

  ASTNode(ASTKind k, const std::string &lbl, NType t)
      : kind(k), label(lbl), expr_type(t) {}

  ASTNode(ASTKind k, const std::string &lbl,
          std::unique_ptr<ASTNode> l,
          std::unique_ptr<ASTNode> r,
          NType t)
      : kind(k), label(lbl), expr_type(t),
        left(std::move(l)), right(std::move(r)) {}

        
  std::string to_string() const;

  Value evaluate(scope_node *scope);
};
