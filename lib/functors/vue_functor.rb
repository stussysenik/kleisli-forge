module Functors
  # Functor F_vue: C_spec -> C_vue
  # Maps a CanonicalSpec to a Vue 3 Single File Component (SFC)
  class VueFunctor < CategoryTheory::Functor
    def initialize
      super(name: "F_vue")
    end

    # fmap: CanonicalSpec -> String (Vue SFC)
    def fmap(spec)
      [
        generate_template(spec),
        "",
        generate_script(spec),
        "",
        generate_style(spec)
      ].join("\n")
    end

    private

    def generate_template(spec)
      template = spec.template.presence || "<div><!-- #{spec.name} --></div>"

      <<~VUE.strip
        <template>
          #{indent(template, 2)}
        </template>
      VUE
    end

    def generate_script(spec)
      parts = []
      parts << generate_props(spec.props) if spec.props.any?
      parts << generate_emits(spec.events) if spec.events.any?

      if spec.script.present?
        parts << ""
        parts << spec.script
      end

      script_body = parts.join("\n")

      <<~VUE.strip
        <script setup>
        #{script_body}
        </script>
      VUE
    end

    def generate_props(props)
      prop_defs = props.map do |prop|
        type_map = {
          "string" => "String",
          "number" => "Number",
          "boolean" => "Boolean",
          "array" => "Array",
          "object" => "Object",
          "function" => "Function",
          "any" => nil
        }

        vue_type = type_map[prop.type] || "String"
        parts = []
        parts << "type: #{vue_type}" if vue_type
        parts << "required: true" if prop.required
        parts << "default: #{prop.default_value}" if prop.default_value.present?

        "  #{prop.name}: { #{parts.join(', ')} }"
      end

      "const props = defineProps({\n#{prop_defs.join(",\n")}\n})"
    end

    def generate_emits(events)
      event_names = events.map { |e| "'#{e.name}'" }.join(", ")
      "const emit = defineEmits([#{event_names}])"
    end

    def generate_style(spec)
      css = spec.styles.presence || generate_default_styles(spec)

      <<~VUE.strip
        <style scoped>
        #{css}
        </style>
      VUE
    end

    def generate_default_styles(spec)
      tokens = spec.design_tokens
      return "" if tokens.empty?

      vars = tokens.map { |k, v| "  #{k}: #{v};" }.join("\n")
      ":root {\n#{vars}\n}"
    end

    def indent(text, spaces)
      text.lines.map { |line| " " * spaces + line.rstrip }.join("\n").strip
    end
  end
end
