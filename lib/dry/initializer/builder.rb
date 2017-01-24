module Dry::Initializer
  class Builder
    def param(*args)
      @params = insert(@params, Param, *args)
      validate_collections
    end

    def option(*args)
      @options = insert(@options, Option, *args)
      validate_collections
    end

    def call(mixin)
      defaults = send(:defaults)
      coercers = send(:coercers)
      mixin.send(:define_method, :__defaults__) { defaults }
      mixin.send(:define_method, :__coercers__) { coercers }
      mixin.class_eval(code, __FILE__, __LINE__ + 1)
    end

    private

    def initialize
      @params  = []
      @options = []
    end

    def insert(collection, klass, source, *args)
      index = collection.index { |option| option.source == source.to_s }

      if index
        new_item = klass.new(source, *args)
        collection.dup.tap { |list| list[index] = new_item }
      else
        new_item = klass.new(source, *args)
        collection + [new_item]
      end
    end

    def code
      <<-RUBY.gsub(/^ +\|/, "")
        |def __initialize__(#{initializer_signatures})
        |  @__options__ = __options__
        |#{initializer_presetters}
        |#{initializer_setters}
        |end
        |private :__initialize__
        |private :__defaults__
        |private :__coercers__
        |
        |#{getters}
      RUBY
    end

    def attributes
      @params + @options
    end

    def duplications
      attributes.group_by(&:target)
                .reject { |_, val| val.count == 1 }
                .keys
    end

    def initializer_signatures
      sig = @params.map(&:initializer_signature).compact.uniq
      sig << (sig.any? && @options.any? ? "**__options__" : "__options__ = {}")
      sig.join(", ")
    end

    def initializer_presetters
      dups = duplications
      attributes
        .map { |a| "  #{a.presetter}" if dups.include? a.target }
        .compact.uniq.join("\n")
    end

    def initializer_setters
      dups = duplications
      attributes.map do |a|
        dups.include?(a.target) ? "  #{a.safe_setter}" : "  #{a.fast_setter}"
      end.compact.uniq.join("\n")
    end

    def getters
      attributes.map(&:getter).compact.uniq.join("\n")
    end

    def defaults
      attributes.map(&:default_hash).reduce({}, :merge)
    end

    def coercers
      attributes.map(&:coercer_hash).reduce({}, :merge)
    end

    def validate_collections
      optional_param = nil

      @params.each do |param|
        if param.optional
          optional_param = param.source if param.optional
        elsif optional_param
          fail ParamsOrderError.new(param.source, optional_param)
        end
      end

      self
    end
  end
end
