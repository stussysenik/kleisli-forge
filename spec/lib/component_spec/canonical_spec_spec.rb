require "rails_helper"

RSpec.describe ComponentSpec::CanonicalSpec do
  let(:valid_attrs) do
    {
      name: "MyButton",
      description: "A custom button",
      component_type: "input",
      template: "<button>Click me</button>",
      props: [
        { name: "label", type: "string", required: true }
      ],
      events: [
        { name: "click" }
      ],
      slots: [
        { name: "default", scoped: false }
      ]
    }
  end

  describe "construction" do
    it "creates a valid spec" do
      spec = described_class.new(valid_attrs)
      expect(spec.name).to eq("MyButton")
      expect(spec.component_type).to eq("input")
      expect(spec.props.first.name).to eq("label")
    end

    it "applies defaults" do
      spec = described_class.new(name: "Minimal", template: "<div></div>")
      expect(spec.component_type).to eq("generic")
      expect(spec.script).to eq("")
      expect(spec.props).to eq([])
      expect(spec.design_tokens).to eq({})
    end

    it "rejects invalid component types" do
      expect {
        described_class.new(valid_attrs.merge(component_type: "invalid"))
      }.to raise_error(Dry::Struct::Error)
    end
  end

  describe "#merge" do
    it "returns a new spec with merged attributes" do
      spec = described_class.new(valid_attrs)
      merged = spec.merge(description: "Updated description")
      expect(merged.description).to eq("Updated description")
      expect(spec.description).to eq("A custom button") # immutable
    end
  end

  describe "#with_design_tokens" do
    it "adds design tokens" do
      spec = described_class.new(valid_attrs)
      enhanced = spec.with_design_tokens("--color-primary" => "#ff0000")
      expect(enhanced.design_tokens["--color-primary"]).to eq("#ff0000")
    end
  end
end
