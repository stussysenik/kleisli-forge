require "rails_helper"

RSpec.describe Functors::SvelteFunctor do
  let(:functor) { described_class.new }

  let(:spec) do
    ComponentSpec::CanonicalSpec.new(
      name: "MyCard",
      description: "A card component",
      component_type: "data-display",
      template: '<div class="card"><h2>{{ title }}</h2></div>',
      props: [
        { name: "title", type: "string", required: true },
        { name: "visible", type: "boolean", required: false, default_value: "true" }
      ],
      events: [
        { name: "select" }
      ]
    )
  end

  describe "#fmap" do
    let(:result) { functor.fmap(spec) }

    it "generates a Svelte component string" do
      expect(result).to be_a(String)
    end

    it "includes script section with export let props" do
      expect(result).to include("<script>")
      expect(result).to include("export let title;")
      expect(result).to include("export let visible = true;")
    end

    it "includes createEventDispatcher" do
      expect(result).to include("createEventDispatcher")
    end

    it "converts {{ expr }} to { expr }" do
      expect(result).to include("{ title }")
      expect(result).not_to include("{{ title }}")
    end

    it "includes style section (not scoped)" do
      expect(result).to include("<style>")
      expect(result).not_to include("<style scoped>")
    end
  end
end
