require "rails_helper"

RSpec.describe Pipeline::Agents::ValidationAgent do
  let(:agent) { described_class.new }

  let(:valid_input) do
    {
      name: "TestButton",
      description: "A test button",
      component_type: "input",
      template: "<button>{{ label }}</button>",
      props: [
        { name: "label", type: "string", required: true }
      ],
      events: [
        { name: "click" }
      ],
      slots: [],
      accessibility: {},
      design_tokens: {}
    }
  end

  describe "#call" do
    it "returns a CanonicalSpec on success" do
      result = agent.call(valid_input)
      expect(result).to be_success
      expect(result.value!).to be_a(ComponentSpec::CanonicalSpec)
    end

    it "sanitizes component name" do
      result = agent.call(valid_input.merge(name: "my-component 123"))
      expect(result).to be_success
      expect(result.value!.name).to eq("mycomponent123")
    end

    it "defaults invalid component type to generic" do
      result = agent.call(valid_input.merge(component_type: "bogus"))
      expect(result).to be_success
      expect(result.value!.component_type).to eq("generic")
    end

    it "normalizes props with defaults" do
      result = agent.call(valid_input)
      expect(result.value!.props.first.name).to eq("label")
      expect(result.value!.props.first.type).to eq("string")
    end
  end
end
