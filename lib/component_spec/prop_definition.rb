require "dry/struct"

module ComponentSpec
  class PropDefinition < Dry::Struct
    attribute :name, Types::Strict::String
    attribute :type, Types::PropType
    attribute :required, Types::Strict::Bool.default(false)
    attribute :default_value, Types::Strict::String.optional.default(nil)
    attribute :description, Types::Strict::String.optional.default(nil)
    attribute :validator, Types::Strict::String.optional.default(nil)
  end
end
