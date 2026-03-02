require "dry/struct"

module ComponentSpec
  class CanonicalSpec < Dry::Struct
    attribute :name, Types::Strict::String
    attribute :description, Types::Strict::String.optional.default(nil)
    attribute :component_type, Types::Strict::String.default("generic".freeze).enum(
      "form", "layout", "data-display", "navigation",
      "feedback", "input", "overlay", "generic"
    )
    attribute :template, Types::Strict::String
    attribute :script, Types::Strict::String.default("".freeze)
    attribute :styles, Types::Strict::String.default("".freeze)
    attribute :props, Types::Strict::Array.of(PropDefinition).default([].freeze)
    attribute :events, Types::Strict::Array.of(EventDefinition).default([].freeze)
    attribute :slots, Types::Strict::Array.of(SlotDefinition).default([].freeze)
    attribute :accessibility, Types::Strict::Hash.default({}.freeze)
    attribute :design_tokens, Types::Strict::Hash.default({}.freeze)

    def to_hash
      super.deep_symbolize_keys
    end

    # Merge additional attributes (returns new instance)
    def merge(**attrs)
      self.class.new(to_hash.merge(attrs))
    end

    def with_design_tokens(tokens)
      merge(design_tokens: design_tokens.merge(tokens))
    end

    def with_accessibility(a11y)
      merge(accessibility: accessibility.merge(a11y))
    end
  end
end
