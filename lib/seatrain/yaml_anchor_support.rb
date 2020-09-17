require "psych"

# https://stackoverflow.com/questions/13583588/read-and-write-yaml-files-without-destroying-anchors-and-aliases/13588273#13588273

module YamlAnchorSupport
  class ToRubyNoMerge < Psych::Visitors::ToRuby
    def revive_hash hash, o
      if o.anchor
        @st[o.anchor] = hash
        hash.instance_variable_set "@_yaml_anchor_name", o.anchor
      end

      o.children.each_slice(2) do |k, v|
        key = accept(k)
        hash[key] = accept(v)
      end
      hash
    end
  end

  refine Psych::Visitors::YAMLTree::Registrar do
    # record object for future, using '@_yaml_anchor_name' rather
    # than object_id if it exists
    def register target, node
      @targets << target
      @obj_to_node[_anchor_name(target)] = node
    end

    def key? target
      @obj_to_node.key? _anchor_name(target)
    rescue NoMethodError
      false
    end

    def node_for target
      @obj_to_node[_anchor_name(target)]
    end

    private

    def _anchor_name(target)
      target.instance_variable_get("@_yaml_anchor_name") || target.object_id
    end
  end

  class MyYAMLTree < Psych::Visitors::YAMLTree
    # check to see if this object has been seen before
    def accept target
      if (anchor_name = target.instance_variable_get("@_yaml_anchor_name"))
        if @st.key? target
          node = @st.node_for target
          node.anchor = anchor_name
          return @emitter.alias anchor_name
        end
      end
      super
    end

    def visit_String o
      if o == "<<"
        style = Psych::Nodes::Scalar::PLAIN
        tag = "tag:yaml.org,2002:str"
        plain = true
        quote = false

        return @emitter.scalar o, nil, tag, plain, quote, style
      end
      super
    end
  end

  protected

  def rewrite_yaml(yaml)
    builder = MyYAMLTree.create
    builder << yaml
    tree = builder.tree
    File.write(@path, tree.yaml, mode: "wb")
  end

  def load_yaml
    str = File.open(@path).read
    tree = Psych.parse(str)
    ToRubyNoMerge.create.accept(tree)
  end
end
