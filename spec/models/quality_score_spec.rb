require "rails_helper"

RSpec.describe QualityScore, type: :model do
  describe "associations" do
    it { should belong_to(:generated_component) }
  end

  describe "#grade" do
    it "returns A for 90+" do
      score = build(:quality_score, overall: 95)
      expect(score.grade).to eq("A")
    end

    it "returns B for 80-89" do
      score = build(:quality_score, overall: 85)
      expect(score.grade).to eq("B")
    end

    it "returns F for below 60" do
      score = build(:quality_score, overall: 40)
      expect(score.grade).to eq("F")
    end
  end

  describe "#passing?" do
    it "returns true for 70+" do
      expect(build(:quality_score, overall: 75).passing?).to be true
    end

    it "returns false for below 70" do
      expect(build(:quality_score, overall: 65).passing?).to be false
    end
  end
end
