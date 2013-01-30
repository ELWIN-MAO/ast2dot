#!/opt/local/bin/ruby

#########################################################################################
# Created by: Dannie M. Stanley <dannie.stanley|@|gmail.com>
# License: GPLv2
# Purpose: Convert GCC AST raw dump to the DOT graphing language for visualization
#
# (1) Use the -fdump-tree-original-raw to produce a textual representation of the AST
#            gcc -fdump-tree-original-raw test.c
#
# (2) Process output with this script:
#            ./ast2dot.rb test.c.003t.original
#
# (option) If you want to specify an application to read the dot output (else STDOUT):
#            $dotreader = 'open -a OmniGraffle\ 5.app'
#
# (option) If you want to skip the output of certain attributes:
#            $skip_attributes = ['size', 'scpe', 'max', 'min', 'bpos']
#
# (option) If you want to output a subtree, specify the root node by ID:
#            $root_node = 4
#
#########################################################################################

$dotreader = 'open -a OmniGraffle\ 5.app'
$skip_attributes = ['size', 'scpe', 'max', 'min', 'bpos']
#$root_node = 16

if ARGV[1] != nil then
    $root_node = ARGV[1].to_i
end

class Node
    attr_accessor :id, :attribs, :typename, :display, :visited
    def initialize(id)
        @id = id
        @attribs = Hash.new
		@display = true
		@visited = false
    end

    def addTypename(t)
        @typename = t
    end

    def addAttrib(k, v)
        @attribs[k] = v
    end

    def to_s
        ret = String.new
        ret += "[@" + @id.to_s + " " + @typename + "]"

        ret += " { "
        @attribs.each_pair do |k,v|
            ret += k.to_s + "="
            if v.class == Node then
                 ret += "#" + v.id.to_s + " "
            else
                 ret += "\"" + v.to_s + "\" "
            end
        end
        ret += "}"

        ret += "\n"
        ret
    end
end

class Graph
    attr_accessor :nodes
    def initialize
        @nodes = Array.new
    end

    def addNode(n)
        if @nodes[n.id] == nil then
            @nodes[n.id] = n 
        end
        @nodes[n.id]
    end

    def getNodeById(id)
        if @nodes[id] == nil then
            @nodes[id] = Node.new(id)
        end
        @nodes[id]
    end

    def to_s
        ret = String.new
        @nodes.each do |n|
            ret += n.to_s
        end
        ret
    end

    def to_dot
        sep = " -> "

        r = String.new
        r << "digraph G {\n"
        r << "node [shape=box width=0.1 height=0.1 fontsize=10];edge [color=black style=solid];\n"
        @nodes.each do |n|
            next if n == nil
			next if n.display == false
            r << n.id.to_s + ' '
            r << '['
            r << 'label="' + '@' + n.id.to_s + ":" + n.typename
			r << "\n" + n.attribs['strg'] if n.attribs['strg'] != nil
            r << '"'
            r << ']'
            r << "\n"
        end
        @nodes.each do |n|
            next if n == nil
			next if n.display == false
            n.attribs.each_pair do |k,v|
                if v.class == Node then
					next if $skip_attributes and $skip_attributes.index(k) != nil
                    r += n.id.to_s
                    r += sep
                    r += v.id.to_s
					r << '['
					r << 'label="' + k
					r << '"'
					r << ' fontsize=10 '
					r << ']'
                    r += "\n"
                end
            end
        end
        r += "}\n"

        return r
    end

    def viz
		if $dotreader != nil then
			File.open("/tmp/tmp.dot", 'w') do |f|
				f.write(to_dot)
			end
			`#{$dotreader} /tmp/tmp.dot` 
		else
			puts to_dot
		end
    end

	def marker(x) 
		x.each do |markthis|
			@nodes[markthis].display = true
		end
	end

	def setAllInvisible
		@nodes.each do |n|
			next if n == nil
			n.display = false
		end
	end

	def reset_visited
		@nodes.each do |n| 
			next if n == nil
			n.visited = false
		end
	end

	def mark_desc_rec(n) 
		return if n.visited
		n.visited = true
		n.display = true
		n.attribs.each_pair do |k,v|
            if v.class == Node then
				next if $skip_attributes and $skip_attributes.index(k) != nil
				mark_desc_rec(v)
			end
		end
	end

	def mark_desc(id)
		n = @nodes[id]
		setAllInvisible
		reset_visited
		mark_desc_rec(n)
	end
end


cur = nil
g = Graph.new
File.open(ARGV[0], "r") do |f|
    f.each_line do |l|
        if l.match(/^;;/) then
            next
        end

        if l.match(/^@(\d+)\s*([\w\_]+)/) then
            cur = Node.new($1.to_i)
            cur = g.addNode(cur)
            cur.addTypename($2)
        end

        l.scan(/((op |)\w+)\s*:\s+([@\w\.\:]+)/) do |m|
            k = m[0].strip
            v = m[2].strip

            if v.match(/^@(\d+)$/) then
                cur.addAttrib(k, g.getNodeById($1.to_i))
            else
                cur.addAttrib(k, v)
            end
        end

    end
end

if ($root_node != nil) then
	g.mark_desc($root_node)
end

g.viz
