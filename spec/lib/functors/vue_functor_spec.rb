require "rails_helper"

RSpec.describe Functors::VueFunctor do
  let(:functor) { described_class.new }

  let(:spec) do
    ComponentSpec::CanonicalSpec.new(
      name: "MyCard",
      description: "A card component",
      component_type: "data-display",
      template: '<div class="card"><h2>{{ title }}</h2><p>{{ content }}</p></div>',
      props: [
        { name: "title", type: "string", required: true },
        { name: "content", type: "string", required: false, default_value: "''" }
      ],
      events: [
        { name: "click" }
      ],
      slots: [
        { name: "default", scoped: false }
      ]
    )
  end

  describe "#fmap" do
    let(:result) { functor.fmap(spec) }

    it "generates a Vue SFC string" do
      expect(result).to be_a(String)
    end

    it "includes template section" do
      expect(result).to include("<template>")
      expect(result).to include("</template>")
    end

    it "includes script setup section" do
      expect(result).to include("<script setup>")
      expect(result).to include("</script>")
    end

    it "includes scoped style section" do
      expect(result).to include("<style scoped>")
    end

    it "generates defineProps" do
      expect(result).to include("defineProps")
      expect(result).to include("title")
      expect(result).to include("String")
    end

    it "generates defineEmits" do
      expect(result).to include("defineEmits")
      expect(result).to include("'click'")
    end
  end

  describe "functor law: identity" do
    it "preserves identity for simple specs" do
      # fmap should produce consistent output for the same input
      result1 = functor.fmap(spec)
      result2 = functor.fmap(spec)
      expect(result1).to eq(result2)
    end
  end
end
