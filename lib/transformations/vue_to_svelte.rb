module Transformations
  # Natural Transformation η: F_vue => F_svelte
  # Converts Vue SFC source code to Svelte component source code.
  #
  # Must satisfy naturality condition:
  #   η(F_vue(spec)) == F_svelte(spec)  for all specs
  class VueToSvelte < CategoryTheory::NaturalTransformation
    def initialize
      super(
        name: "vue_to_svelte",
        source_functor: Functors::VueFunctor.new,
        target_functor: Functors::SvelteFunctor.new
      )
    end

    # component_at: F_vue(spec) -> F_svelte(spec)
    # Takes a Vue SFC string, returns a Svelte component string
    def component_at(vue_source)
      script = transform_script(extract_section(vue_source, "script"))
      template = transform_template(extract_section(vue_source, "template"))
      styles = transform_styles(extract_section(vue_source, "style"))

      [
        "<script>",
        script,
        "</script>",
        "",
        template,
        "",
        "<style>",
        styles,
        "</style>"
      ].join("\n")
    end

    private

    def extract_section(source, section)
      match = source.match(/<#{section}[^>]*>(.*?)<\/#{section}>/m)
      match ? match[1].strip : ""
    end

    def transform_script(vue_script)
      result = vue_script.dup

      # defineProps -> export let
      result.gsub!(/const\s+\w+\s*=\s*defineProps\(\{(.*?)\}\)/m) do
        props_body = $1
        convert_define_props(props_body)
      end

      # defineEmits -> createEventDispatcher
      if result.include?("defineEmits")
        result.gsub!(/const\s+\w+\s*=\s*defineEmits\(\[([^\]]*)\]\)/) do
          "import { createEventDispatcher } from 'svelte';\n  const dispatch = createEventDispatcher();"
        end
      end

      # ref() -> let
      result.gsub!(/const\s+(\w+)\s*=\s*ref\(([^)]*)\)/) { "let #{$1} = #{$2}" }

      # reactive() -> let
      result.gsub!(/const\s+(\w+)\s*=\s*reactive\(([^)]*)\)/) { "let #{$1} = #{$2}" }

      # computed() -> $: reactive declaration
      result.gsub!(/const\s+(\w+)\s*=\s*computed\(\(\)\s*=>\s*(.+?)\)/) { "$: #{$1} = #{$2}" }

      # .value access (from ref) -> direct access
      result.gsub!(/(\w+)\.value/, '\1')

      # Remove Vue-specific imports
      result.gsub!(/import\s*\{[^}]*\}\s*from\s*['"]vue['"];?\n?/, "")

      result
    end

    def convert_define_props(props_body)
      lines = []
      # Parse each prop definition
      props_body.scan(/(\w+)\s*:\s*\{([^}]*)\}/) do |name, config|
        type_match = config.match(/type:\s*(\w+)/)
        default_match = config.match(/default:\s*(.+?)(?:,|\s*$)/)
        required = config.include?("required: true")

        if default_match
          lines << "  export let #{name} = #{default_match[1].strip};"
        elsif required
          lines << "  export let #{name};"
        else
          default = type_default(type_match&.[](1))
          lines << "  export let #{name} = #{default};"
        end
      end
      lines.join("\n")
    end

    def type_default(type)
      case type
      when "String" then "''"
      when "Number" then "0"
      when "Boolean" then "false"
      when "Array" then "[]"
      when "Object" then "{}"
      else "undefined"
      end
    end

    def transform_template(vue_template)
      result = vue_template.dup

      # v-if -> {#if}...{/if}
      result.gsub!(/<(\w+)([^>]*)\s+v-if="([^"]+)"([^>]*)>(.*?)<\/\1>/m) do
        tag, pre, cond, post, content = $1, $2, $3, $4, $5
        "{#if #{cond}}\n<#{tag}#{pre}#{post}>#{content}</#{tag}>\n{/if}"
      end

      # v-else-if
      result.gsub!(/<(\w+)([^>]*)\s+v-else-if="([^"]+)"([^>]*)>(.*?)<\/\1>/m) do
        tag, pre, cond, post, content = $1, $2, $3, $4, $5
        "{:else if #{cond}}\n<#{tag}#{pre}#{post}>#{content}</#{tag}>"
      end

      # v-else
      result.gsub!(/<(\w+)([^>]*)\s+v-else([^>]*)>(.*?)<\/\1>/m) do
        tag, pre, post, content = $1, $2, $3, $4
        "{:else}\n<#{tag}#{pre}#{post}>#{content}</#{tag}>"
      end

      # v-for -> {#each}
      result.gsub!(/<(\w+)([^>]*)\s+v-for="(\w+)\s+in\s+(\w+)"([^>]*)>(.*?)<\/\1>/m) do
        tag, pre, item, list, post, content = $1, $2, $3, $4, $5, $6
        "{#each #{list} as #{item}}\n<#{tag}#{pre}#{post}>#{content}</#{tag}>\n{/each}"
      end

      # v-for with index
      result.gsub!(/<(\w+)([^>]*)\s+v-for="\((\w+),\s*(\w+)\)\s+in\s+(\w+)"([^>]*)>(.*?)<\/\1>/m) do
        tag, pre, item, index, list, post, content = $1, $2, $3, $4, $5, $6, $7
        "{#each #{list} as #{item}, #{index}}\n<#{tag}#{pre}#{post}>#{content}</#{tag}>\n{/each}"
      end

      # {{ expr }} -> { expr }
      result.gsub!(/\{\{\s*(.+?)\s*\}\}/) { "{ #{$1} }" }

      # v-on: / @ -> on:
      result.gsub!(/v-on:(\w+)/, 'on:\1')
      result.gsub!(/@(\w+)=/, 'on:\1=')

      # v-bind: / : -> direct (but not on: which is already an event)
      result.gsub!(/v-bind:(\w+)="([^"]+)"/) { "#{$1}={#{$2}}" }
      result.gsub!(/(?<!\w):(\w+)="([^"]+)"/) { "#{$1}={#{$2}}" }

      # v-model -> bind:value
      result.gsub!(/v-model="([^"]+)"/) { "bind:value={#{$1}}" }

      # v-show -> style conditional
      result.gsub!(/v-show="([^"]+)"/) { "style:display={#{$1} ? '' : 'none'}" }

      # v-html -> {@html}
      result.gsub!(/v-html="([^"]+)"/) { "{@html #{$1}}" }

      # <slot> -> <slot> (same in Svelte)
      # <slot name="x"> -> <slot name="x"> (same)

      result
    end

    def transform_styles(vue_styles)
      result = vue_styles.dup

      # Vue deep selectors -> Svelte :global
      result.gsub!(/::v-deep\(([^)]+)\)/) { ":global(#{$1})" }
      result.gsub!(/:deep\(([^)]+)\)/) { ":global(#{$1})" }

      # Vue :slotted -> Svelte doesn't have equivalent, use :global
      result.gsub!(/:slotted\(([^)]+)\)/) { ":global(#{$1})" }

      result
    end
  end
end
