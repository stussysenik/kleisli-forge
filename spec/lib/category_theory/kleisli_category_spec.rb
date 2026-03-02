require "rails_helper"

RSpec.describe CategoryTheory::KleisliCategory do
  include Dry::Monads[:result]

  let(:category) { described_class.new(name: "test") }

  let(:double_arrow) { CategoryTheory::KleisliArrow.new(name: "double") { |x| Success(x * 2) } }
  let(:add_one_arrow) { CategoryTheory::KleisliArrow.new(name: "add_one") { |x| Success(x + 1) } }
  let(:negate_arrow) { CategoryTheory::KleisliArrow.new(name: "negate") { |x| Success(-x) } }

  before do
    category.add_arrow(double_arrow)
    category.add_arrow(add_one_arrow)
    category.add_arrow(negate_arrow)
  end

  describe "#compose" do
    it "composes named arrows in sequence" do
      composed = category.compose("double", "add_one")
      expect(composed.call(5)).to eq(Success(11))
    end
  end

  describe "#compose_all" do
    it "composes all arrows in insertion order" do
      composed = category.compose_all
      # double(5)=10, add_one(10)=11, negate(11)=-11
      expect(composed.call(5)).to eq(Success(-11))
    end
  end

  describe "#associative?" do
    it "verifies associativity of three arrows" do
      expect(category.associative?("double", "add_one", "negate", 5)).to be true
    end
  end

  describe "#left_identity?" do
    it "verifies left identity" do
      expect(category.left_identity?("double", 7)).to be true
    end
  end

  describe "#right_identity?" do
    it "verifies right identity" do
      expect(category.right_identity?("double", 7)).to be true
    end
  end
end
