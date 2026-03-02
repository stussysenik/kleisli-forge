require "dry/struct"

module ComponentSpec
  class StyleDefinition < Dry::Struct
    attribute :selector, Types::Strict::String
    attribute :properties, Types::Strict::Hash.default({}.freeze)
    attribute :scoped, Types::Strict::Bool.default(true)
    attribute :media_query, Types::Strict::String.optional.default(nil)
  end
end
