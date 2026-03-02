require "dry/struct"

module ComponentSpec
  class SlotDefinition < Dry::Struct
    attribute :name, Types::Strict::String
    attribute :description, Types::Strict::String.optional.default(nil)
    attribute :scoped, Types::Strict::Bool.default(false)
    attribute :scope_props, Types::Strict::Array.of(Types::Strict::String).default([].freeze)
  end
end
