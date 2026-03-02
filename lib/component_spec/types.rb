require "dry/types"

module ComponentSpec
  module Types
    include Dry.Types()

    ComponentType = Types::Strict::String.enum(
      "form", "layout", "data-display", "navigation",
      "feedback", "input", "overlay", "generic"
    )

    Framework = Types::Strict::String.enum("vue", "svelte")

    PropType = Types::Strict::String.enum(
      "string", "number", "boolean", "array", "object", "function", "any"
    )

    EventName = Types::Strict::String.constrained(format: /\A[a-z][a-zA-Z0-9:_-]*\z/)

    SlotName = Types::Strict::String.constrained(min_size: 1)

    CssValue = Types::Strict::String

    HexColor = Types::Strict::String.constrained(format: /\A#[0-9a-fA-F]{3,8}\z/)

    PositiveInteger = Types::Strict::Integer.constrained(gt: 0)
  end
end
