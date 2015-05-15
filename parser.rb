#!/usr/bin/env ruby
# coding: utf-8
#
# Author: Jordan Ritter <jpr5@ivysoftworks.com>
#
# Demo script for showing how we could implement a quick-and-dirty GQL that
# would produce something equivalent to the JSON-based nested-AST Charles first
# introduced (and which the corresponding Fridge SL understood).
#
# Concepts:
#
#   - entities: objects, real or materialized vs. directives (order, limit, etc)
#   - edges: walking a graph with left-to-right, '.'-based imperatives
#   - accumulative field capture, visitor-style, as the graph is walked
#
# Objects:
#
#   Entities   = [Moment, Item, Snapshot] (always capitalized, proper noun-style)
#   Directives = [limit, offset, order]   (always lowercased)
#   Fields     = [anything]               (alphanumeric for now, mixed case)
#
# Future Ideas:
#
#   - captures as hash: [f1 -> something], caller owns cross-entity fieldname
#     collision
#
# References (post-facto):
#   - http://hueypetersen.com/posts/2015/02/02/first-thoughts-on-graph-ql/
#   - https://facebook.github.io/react/blog/2015/05/01/graphql-introduction.html
#   - http://facebook.github.io/react/blog/2015/02/20/introducing-relay-and-graphql.html
#   - http://hueypetersen.com/posts/2015/02/08/modeling-queries-graph-ql-like/

EXAMPLE_STATEMENTS = [

    # Use 1: walk the graph to get to objects at end
    "Moment(f1 = v1, f2 <= v3).Item(f3 > v4).limit(10)",

    # Use 2: walk the graph and capture information into composite
    # - maybe OK: all Entities are pre-composed as materialized views for us,
    #   but then what would it look like?
    "Moment()[f1, f2].Item(f3 != v4, f6 = nil)[f3]",

]

# Parsing logic:
#
# (1) Split statement on . to get consecutive/ordered nuggets
# (2) For each nugget, parse as THING + optional( conditions ) + optional[ captures ]
# (3) For each THING, interpret as Entity or Directive()
# (4) Split various param chunks on ',' to build lists (conditions, captures, params, etc)
#
def parse(statement)
    # (1) split into nuggets -> something.something.something
    nugz = statement.split(".")

    # (2) grok each nugget into buds -> anything(?anything)[?anything]
    budz = nugz.map{ |nugget| /(\w+)(?:\(([^\)]*)\))?(?:\[([^\]]*)\])?/.match(nugget).captures }
    pp(budz)
    print("\n")

    # (3) scan each bud for whether it's an Entity or Directive, and refine the AST
    ast = budz.map do |bud|
        case bud.first
            when /(order|limit|offset)/ then
                Hash[ [:directive, :params].zip(bud) ]
            when /^[A-Z]/ then
                Hash[ [:entity, :conditions, :fields].zip(bud) ]
            else puts "whoa duuuude: #{bud.inspect}"
        end
    end

    # (4) explode conditions, captures, params chunks
    ast.each do |chunk|
        chunk[:conditions] &&= chunk[:conditions].split(',').map(&:strip).map { |cond| cond.split(/\s+/) }
        chunk[:params]     &&= chunk[:params].split(',').map(&:strip)
        chunk[:fields]     &&= chunk[:fields].split(',').map(&:strip)
    end

    return ast
end

##
## MAIN
##

require 'pp'
EXAMPLE_STATEMENTS.each do |s|
    print(s+"\n")
    parse(s)
end

__END__

⦗master⦘ jpr5@crucible(~)⇒ ruby parser.rb
[{:entity=>"Moment",
  :conditions=>[["f1", "=", "v1"], ["f2", "<=", "v3"]],
  :fields=>nil},
 {:entity=>"Item", :conditions=>[["f3", ">", "v4"]], :fields=>nil},
 {:directive=>"limit", :params=>["10"]}]
[{:entity=>"Moment", :conditions=>[], :fields=>["f1", "f2"]},
 {:entity=>"Item",
  :conditions=>[["f3", "!=", "v4"], ["f6", "=", "nil"]],
  :fields=>["f3"]}]
