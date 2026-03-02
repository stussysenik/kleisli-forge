module Functors
  # Functor F_svelte: C_spec -> C_svelte
  # Maps a CanonicalSpec to a Svelte component
  class SvelteFunctor < CategoryTheory::Functor
    def initialize
      super(name: "F_svelte")
    end

    # fmap: CanonicalSpec -> String (Svelte component)
    def fmap(spec)
      [
        generate_script(spec),
        "",
        generate_template(spec),
        "",
        generate_style(spec)
      ].join("\n")
    end

    private

    def generate_script(spec)
      parts = []
      parts.concat(generate_props(spec.props)) if spec.props.any?
      parts.concat(generate_events(spec.events)) if spec.events.any?

      if spec.script.present?
        parts << ""
        parts << convert_script(spec.script)
      end

      <<~SVELTE.strip
        <script>
        #{parts.join("\n")}
        </script>
      SVELTE
    end

    def generate_props(props)
      props.map do |prop|
        default = prop.default_value
        if default.present?
          "  export let #{prop.name} = #{default};"
        elsif prop.required
          "  export let #{prop.name};"
        else
          "  export let #{prop.name} = #{default_for_type(prop.type)};"
        end
      end
    end

    def generate_events(events)
      lines = ["  import { createEventDispatcher } from 'svelte';", "  const dispatch = createEventDispatcher();"]
      events.each do |event|
        lines << "  // dispatch('#{event.name}', payload)"
      end
      lines
    end

    def generate_template(spec)
      template = spec.template.presence || "<div><!-- #{spec.name} --></div>"
      convert_template(template)
    end

    def generate_style(spec)
      css = spec.styles.presence || generate_default_styles(spec)

      <<~SVELTE.strip
        <style>
        #{css}
        </style>
      SVELTE
    end

    def convert_template(template)
      result = template.dup

      # Vue v-if -> Svelte {#if}
      result.gsub!(/\s*v-if="([^"]+)"/) { |_| "" }
      result.gsub!(/<(\w+)([^>]*)\s+v-if="([^"]+)"([^>]*)>(.+?)<\/\1>/m) do
        tag, pre, condition, post, content = $1, $2, $3, $4, $5
        "{#if #{condition}}\n<#{tag}#{pre}#{post}>#{content}</#{tag}>\n{/if}"
      end

      # Vue v-for -> Svelte {#each}
      result.gsub!(/<(\w+)([^>]*)\s+v-for="(\w+)\s+in\s+(\w+)"([^>]*)>(.*?)<\/\1>/m) do
        tag, pre, item, list, post, content = $1, $2, $3, $4, $5, $6
        "{#each #{list} as #{item}}\n<#{tag}#{pre}#{post}>#{content}</#{tag}>\n{/each}"
      end

      # Vue {{ expr }} -> Svelte { expr }
      result.gsub!(/\{\{\s*(.+?)\s*\}\}/) { "{ #{$1} }" }

      # Vue v-on:event -> Svelte on:event
      result.gsub!(/v-on:(\w+)/, 'on:\1')
      result.gsub!(/@(\w+)=/, 'on:\1=')

      # Vue v-bind:attr -> Svelte attr= (but not on: which is event)
      result.gsub!(/v-bind:(\w+)="([^"]+)"/) { "#{$1}={#{$2}}" }
      result.gsub!(/(?<!\w):(\w+)="([^"]+)"/) { "#{$1}={#{$2}}" }

      # Vue v-model -> Svelte bind:value
      result.gsub!(/v-model="([^"]+)"/) { "bind:value={#{$1}}" }

      # Vue v-show -> Svelte style:display
      result.gsub!(/v-show="([^"]+)"/) { "style:display={#{$1} ? '' : 'none'}" }

      result
    end

    def convert_script(script)
      result = script.dup
      # Remove Vue-specific APIs
      result.gsub!(/defineProps\([^)]*\)/, "// props defined above")
      result.gsub!(/defineEmits\([^)]*\)/, "// events via dispatch")
      result
    end

    def default_for_type(type)
      case type
      when "string" then "''"
      when "number" then "0"
      when "boolean" then "false"
      when "array" then "[]"
      when "object" then "{}"
      else "undefined"
      end
    end

    def generate_default_styles(spec)
      tokens = spec.design_tokens
      return "" if tokens.empty?

      vars = tokens.map { |k, v| "  #{k}: #{v};" }.join("\n")
      ":root {\n#{vars}\n}"
    end
  end
end
