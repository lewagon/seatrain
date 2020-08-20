require "hashie"
require_relative "yaml_anchor_support"

module Seatrain
  class DockerComposeTransformer
    include YamlAnchorSupport
    def initialize(path)
      # A path to docker-compose.yml file
      @path = path
      @from_yaml = load_yaml
    end

    def replace_image_name(new_name, old_name)
      # https://github.com/hashie/hashie#deeplocate
      @from_yaml.extend(Hashie::Extensions::DeepLocate)
      @from_yaml.deep_locate ->(k, v, o) { o["image"] = new_name if v == old_name }
      # https://stackoverflow.com/questions/13583588/read-and-write-yaml-files-without-destroying-anchors-and-aliases/13588273
      builder = MyYAMLTree.create
      builder << @from_yaml
      tree = builder.tree
      File.write(@path, tree.yaml, mode: "wb")
    end

    private

    def load_yaml
      str = File.open(@path).read
      tree = Psych.parse(str)
      ToRubyNoMerge.create.accept(tree)
    end
  end
end
