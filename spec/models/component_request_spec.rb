require "rails_helper"

RSpec.describe ComponentRequest, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_one(:pipeline_run).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:input_type) }
    it { should validate_inclusion_of(:input_type).in_array(%w[prompt json file]) }

    context "when input_type is prompt" do
      subject { build(:component_request, input_type: "prompt") }
      it { should validate_presence_of(:raw_prompt) }
    end
  end

  describe "#display_name" do
    it "truncates long prompts" do
      request = build(:component_request, raw_prompt: "A" * 100)
      expect(request.display_name.length).to be <= 63
    end
  end
end
