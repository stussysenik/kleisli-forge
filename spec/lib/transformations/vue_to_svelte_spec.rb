require "rails_helper"

RSpec.describe Transformations::VueToSvelte do
  let(:transformation) { described_class.new }
  let(:vue_functor) { Functors::VueFunctor.new }
  let(:svelte_functor) { Functors::SvelteFunctor.new }

  let(:simple_spec) do
    ComponentSpec::CanonicalSpec.new(
      name: "SimpleButton",
      component_type: "input",
      template: "<button>Click</button>",
      props: [
        { name: "label", type: "string", required: true }
      ]
    )
  end

  describe "#component_at" do
    it "converts Vue SFC to Svelte component" do
      vue_source = vue_functor.fmap(simple_spec)
      svelte_output = transformation.component_at(vue_source)

      expect(svelte_output).to include("<script>")
      expect(svelte_output).to include("</script>")
      expect(svelte_output).to include("<style>")
      expect(svelte_output).not_to include("<style scoped>")
    end

    it "converts defineProps to export let" do
      vue_source = vue_functor.fmap(simple_spec)
      svelte_output = transformation.component_at(vue_source)

      expect(svelte_output).to include("export let")
    end
  end

  describe "template conversion" do
    it "converts v-on: to on:" do
      vue = '<template><button v-on:click="handler">Go</button></template><script setup></script><style scoped></style>'
      result = transformation.component_at(vue)
      expect(result).to include("on:click")
    end

    it "converts v-bind: to direct binding" do
      vue = '<template><div v-bind:class="cls">Hi</div></template><script setup></script><style scoped></style>'
      result = transformation.component_at(vue)
      expect(result).to include("class={cls}")
    end

    it "converts v-model to bind:value" do
      vue = '<template><input v-model="name"></template><script setup></script><style scoped></style>'
      result = transformation.component_at(vue)
      expect(result).to include("bind:value={name}")
    end
  end

  describe "style conversion" do
    it "converts ::v-deep to :global" do
      vue = '<template><div></div></template><script setup></script><style scoped>::v-deep(.child) { color: red; }</style>'
      result = transformation.component_at(vue)
      expect(result).to include(":global(.child)")
    end
  end
end
