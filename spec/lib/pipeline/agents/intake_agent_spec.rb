require "rails_helper"

RSpec.describe Pipeline::Agents::IntakeAgent do
  let(:agent) { described_class.new }

  describe "#call" do
    context "with a string prompt" do
      it "normalizes to a hash" do
        result = agent.call("Create a button component with a click event")
        expect(result).to be_success
        expect(result.value![:source]).to eq(:prompt)
        expect(result.value![:component_name]).to eq("Button")
      end
    end

    context "with a hash input" do
      it "normalizes the hash" do
        result = agent.call({ name: "MyCard", description: "A card" })
        expect(result).to be_success
        expect(result.value![:source]).to eq(:json)
        expect(result.value![:component_name]).to eq("MyCard")
      end
    end

    context "with blank input" do
      it "returns failure" do
        result = agent.call("")
        expect(result).to be_failure
      end
    end

    context "with nil input" do
      it "returns failure" do
        result = agent.call(nil)
        expect(result).to be_failure
      end
    end
  end

  describe "#to_kleisli" do
    it "converts to a KleisliArrow" do
      arrow = agent.to_kleisli
      expect(arrow).to be_a(CategoryTheory::KleisliArrow)
      expect(arrow.call("Create a modal component")).to be_success
    end
  end
end
