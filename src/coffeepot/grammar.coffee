root: exports ? this
CoffeePot: (root.CoffeePot ?= {})
Helper: CoffeePot.Helper ? require('coffeepot/helper').CoffeePot.Helper
p: Helper.option

# grammar for the CoffeeScript language's parser
grammar: {

  Start: [
    p("Block") =>
      "(function () {\n" + (("  " + line) for line in $1.split("\n")).join("\n") + "\n}());"
  ]

  # Any list of expressions or method body, seperated by line breaks or semis.
  Block: [
    p("Block Statement") => $1 + '\n' + $2
    p("Statement") => $1
  ]

  Statement: [
    p("Comment Terminator") => $1
    p("Expression Terminator") => $1 + ';'
  ]

  Comment: [
    p("COMMENT") => '//' + yytext
  ]

  Terminator: [
    p("NEWLINE")
    p(";")
  ]


#
# Statement: g([
#   p("COMMENT")
#   p("PostCond")
#   p("Expression")
#   p("Compound")
# ]) => this[0]
#
# PostCond: g([
#   p("Expression if Expression") => [this[2], this[0]]
#   p("Expression unless Expression") => [["Not", this[2]], this[0]]
# ]) name => ["If", this[0], this[1]]
#
# # All types of expressions in our language. The basic unit of CoffeeScript
# # is the expression.
# Expression: g([
#   p("Binop")
#   p("Assign")
#   p("Function")
#   p("Call")
#   p("Source")
#   p("Value")
#   p("( Expression )") => [this[1]]
# ]) name => this[0]
#
# Compound: g([
#   p("Expression Chain") => [this[0]].concat(this[1][1])
# ])
#
# Chain: g([
#   p("PROPERTY")
#   p("PROPERTY Chain") => [this[0]].concat(this[1][1])
# ])
#
# Call: g([
#   p("Source ( )") => [this[0], ["ExpressionList", []]]
#   p("Source ( ExpressionList )") => [this[0], this[2]]
# ]) name => [name, this[0], this[1]]
#
# ExpressionList: g([
#   p("Expression")
#   p("Expression , ExpressionList") => [this[0]].concat(this[2][1])
# ])
#
# Source: g([
#   p("ID") => this[0]
#   p("ID Chain") => ["Source", [this[0]].concat(this[1][1])]
# ]) => this
#
# Args: g([
#   p("Expression , Args") => [this[0]].concat(this[2])
#   p("Expression")
# ]) name => this
#
# Value: g([
#   p("Source")
#   p("Literal")
# ]) name => this[0]
#
# # Assignment to a variable.
# Assign: g([
#   p("Source : Expression")
#   p("Source = Expression")
# ]) name => [name, this[0], this[2]]
#
# Function: g([
#   p("ArgsList ROCKET Expression") => [this[0], this[2]]
#   p("ArgsList ROCKET NEWLINE INDENT Block NEWLINE DEDENT") => [this[0], this[4]]
#   p("ROCKET Expression") => [[], this[1]]
#   p("ROCKET NEWLINE INDENT Block NEWLINE DEDENT") => [[], this[3]]
# ]) name => [name, this[0], this[1]]
#
# ArgsList: g([
#   p("ID , ArgsList") => [this[0]].concat(this[2])
#   p("ID")
# ]) => this
#
# Binop: g([
#   p("Value OPERATOR Expression")
# ]) name => [name, this[1], this[0], this[2]]
#
# Literal: g([
#   p("NUMBER")
#   p("STRING")
#   p("BOOLEAN")
#   p("REGEXP")
#   p("Array")
#   p("Object")
# ]) name => this[0]
#
# Array: g([
#   p("[ NEWLINE INDENT ArrayItems NEWLINE DEDENT ]") => this[3]
#   p("[ ArrayItems ]") => this[1]
#   p("[ ]") => []
# ]) name => [name, this]
#
#
# ArrayItems: g([
#   p("Expression ItemSeperator ArrayItems") => [this[0]].concat(this[2])
#   p("Expression")
# ]) => this
#
# Object: g([
#   p("{ NEWLINE INDENT ObjectPairs NEWLINE DEDENT }") => this[3]
#   p("{ ObjectPairs }") => this[1]
#   p("{ }") => []
# ])
#
# ObjectPairs: g([
#   p("ID : Expression ItemSeperator ObjectPairs") => [[this[0][1], this[2]]].concat(this[4])
#   p("ID : Expression") => [[this[0][1], this[2]]]
# ]) => this
#
# ItemSeperator: g([
#   p(",")
#   p("NEWLINE")
# ]) => this

}

CoffeePot.grammar: grammar
