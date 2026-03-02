require "rails_helper"

RSpec.describe CategoryTheory::KleisliArrow do
  include Dry::Monads[:result]

  let(:double_arrow) do
    described_class.new(name: "double") { |x| Success(x * 2) }
  end

  let(:add_one_arrow) do
    described_class.new(name: "add_one") { |x| Success(x + 1) }
  end

  let(:to_string_arrow) do
    described_class.new(name: "to_string") { |x| Success(x.to_s) }
  end

  let(:failing_arrow) do
    described_class.new(name: "fail") { |_x| Failure(error: "boom") }
  end

  describe "#call" do
    it "applies the wrapped function" do
      expect(double_arrow.call(5)).to eq(Success(10))
    end
  end

  describe "#>>" do
    it "composes two arrows via Kleisli composition" do
      composed = double_arrow >> add_one_arrow
      # double(5) = 10, add_one(10) = 11
      expect(composed.call(5)).to eq(Success(11))
    end

    it "short-circuits on failure" do
      composed = failing_arrow >> add_one_arrow
      result = composed.call(5)
      expect(result).to be_failure
    end

    it "names the composed arrow" do
      composed = double_arrow >> add_one_arrow
      expect(composed.name).to eq("double >> add_one")
    end
  end

  describe "Kleisli laws" do
    let(:identity) { described_class.identity }

    it "satisfies left identity: id >> f == f" do
      test_input = 42
      expect((identity >> double_arrow).call(test_input)).to eq(double_arrow.call(test_input))
    end

    it "satisfies right identity: f >> id == f" do
      test_input = 42
      expect((double_arrow >> identity).call(test_input)).to eq(double_arrow.call(test_input))
    end

    it "satisfies associativity: (f >> g) >> h == f >> (g >> h)" do
      test_input = 5
      left = (double_arrow >> add_one_arrow) >> to_string_arrow
      right = double_arrow >> (add_one_arrow >> to_string_arrow)

      expect(left.call(test_input)).to eq(right.call(test_input))
    end
  end

  describe ".lift" do
    it "lifts a pure function into a Kleisli arrow" do
      arrow = described_class.lift(name: "square") { |x| x ** 2 }
      expect(arrow.call(4)).to eq(Success(16))
    end

    it "catches exceptions and returns Failure" do
      arrow = described_class.lift(name: "boom") { |_x| raise "explosion" }
      result = arrow.call(1)
      expect(result).to be_failure
    end
  end

  describe "#&" do
    it "runs both arrows in parallel on the same input" do
      composed = double_arrow & add_one_arrow
      result = composed.call(5)
      expect(result).to eq(Success({ left: 10, right: 6 }))
    end
  end
end
