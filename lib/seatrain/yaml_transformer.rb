require "hashie"
require_relative "yaml_anchor_support"

module Seatrain
  class YamlTransformer
    include YamlAnchorSupport
    def initialize(path)
      @path = path
      @obj = File.exist?(path) ? load_yaml : {}
      @obj.extend(Hashie::Extensions::DeepLocate)
    end

    def [](key)
      @obj.[](key)
    end

    def dig(*args)
      @obj.dig(*args)
    end

    def deep_replace_key(key_name, old_value, new_value)
      return unless File.exist?(@path)
      @obj.deep_locate ->(k, v, o) { o[key_name] = new_value if v == old_value }
      rewrite_yaml(@obj)
    end

    def deep_replace_first_key(key_name, new_value)
      return unless File.exist?(@path)
      @obj.deep_locate ->(k, v, o) { o[key_name] = new_value if k == key_name }
      rewrite_yaml(@obj)
    end

    def deep_delete_key(key_name)
      return unless File.exist?(@path)
      @obj.deep_locate ->(k, v, o) { o.delete(k) if k == key_name }
      rewrite_yaml(@obj)
    end
  end
end
