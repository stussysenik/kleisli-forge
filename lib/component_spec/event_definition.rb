require "dry/struct"

module ComponentSpec
  class EventDefinition < Dry::Struct
    attribute :name, Types::Strict::String
    attribute :payload_type, Types::Strict::String.optional.default(nil)
    attribute :description, Types::Strict::String.optional.default(nil)
  end
end
