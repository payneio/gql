package main

import (
	"fmt"
	"os"
	"unicode"
)

type Node struct {
	Value    string
	Children []*Node
}

func (n *Node) Add(child *Node) {
	n.Children = append(n.Children, child)
}
func (n *Node) New() *Node {
	child := &Node{}
	n.Add(child)
	return child
}
func (n *Node) S() (s string) {
	s = n.Value
	for _, child := range n.Children {
		s = s + child.S()
	}
	return s
}

func main() {

	s := "Moment(f1 = v1, f2 <= v3).Item(f3 > v4).limit(10)"
	ast := parse(s)
	fmt.Println(ast.S())

}

type State int

const (
	Start State = iota
	Entity
	Directive
	Conditions
	Fields
)

type DirectiveState int

const (
	DDirective DirectiveState = iota
	DParam
)

type ConditionState int

const (
	Left ConditionState = iota
	Op
	Right
)

type Token []byte

func (t *Token) Add(c rune) {
	t = append(t, byte(c))
}
func (t *Token) Drain() string {
	s := string(t)
	t = t[:0]
	return s
}

func parse(s string) *Node {

	state := Start
	var conditionState ConditionState
	var directiveState DirectiveState

	var token Token = &Token{}

	var root = &Node{}

	entitiesNode := &Node{}
	directivesNode := &Node{}
	root.Add(entitiesNode)
	root.Add(directivesNode)

	for _, c := range s {
		if c == ' ' {
			continue
		}
		switch state {

		case Start:
			switch {
			case unicode.IsUpper(c):
				entityNode := entitiesNoed.New()

				state = Entity
			case unicode.IsLower(c):
				directiveNode := directivesNode.New()

				state = Directive
				directiveState = DDirective
			default:
				os.Exit(1)
			}

		case Entity:
			switch c {
			case '(':
				entityNode.Add(&Node{token.Drain()})
				conditionsNode := &Node{}
				conditionNode := conditionsNode.New()

				state = Conditions
				conditionState := Left
			case '[':
				entityNode.Add(&Node{token.Drain()})
				fieldsNode := &Node{}
				fieldNode := fieldsNode.New()

				state = Fields
			case '.':
				if token.len > 0 {
					entityNode.Value = token
				}
				state = Start
			default:
				token.Add(c)
			}

		case Conditions:
			switch conditionState {
			case Left:
				switch c {
				case ',':
					conditionNode.Value = token.Drain()
					conditionsNode = conditionsNode.New()

					conditionState = Op
				default:
					token.Add(c)
				}
			case Op:
				switch c {
				case '<', '>', '=', '!':
					token.Add(c)
				default:
					conditionNode.Value = token.Drain()
					conditionsNode = conditionsNode.New()

					conditionState = Right
				}
			case Right:
				switch c {
				case ')':
					conditionNode.Value = token.Drain()

					conditionState = Left
					state = Start
				default:
					token.Add(c)
				}
			}

		case Fields:
			switch c {
			case ',':
				fieldNode.Value = token.Drain()
				fieldNode := fieldsNode.New()
			case ']':
				fieldNode.Value = token.Drain()

				state = Entity
			default:
				token.Add(c)
			}

		case Directive:
			switch c {
			case '(':
				// Add token to directive
				directiveNode.Value = token.Drain()
				directiveParamNode = directiveNode.New()
				directiveState = DParam
			case ')':
				directiveParamNode.Value = token.Drain
				directiveState = DDirective
				state = Start
			default:
				token.Add(c)
			}
		}
	}

	// Add any remaining token to last entity
	if token.len > 0 {
		entityNode.Value = token
	}
	return root
}
