require "rails_helper"

RSpec.describe GeneratedComponent, type: :model do
  describe "associations" do
    it { should belong_to(:pipeline_run) }
    it { should have_one(:quality_score).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:framework) }
    it { should validate_inclusion_of(:framework).in_array(%w[vue svelte]) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:source_code) }
  end

  describe "#filename" do
    it "returns .vue for vue components" do
      component = build(:generated_component, framework: "vue", name: "MyButton")
      expect(component.filename).to eq("MyButton.vue")
    end

    it "returns .svelte for svelte components" do
      component = build(:generated_component, framework: "svelte", name: "MyButton")
      expect(component.filename).to eq("MyButton.svelte")
    end
  end
end
