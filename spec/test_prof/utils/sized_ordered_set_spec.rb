# frozen_string_literal: true

require "spec_helper"
require "test_prof/utils/sized_ordered_set"

describe TestProf::Utils::SizedOrderedSet do
  subject { described_class.new(5) }

  context "with implicit comparison" do
    it "stores only specified number of elements" do
      10.times do
        subject << 0
      end

      expect(subject.size).to eq 5
    end

    it "iterates over sorted elements" do
      subject << 3
      subject << 5
      subject << 1
      subject << 4
      subject << 6
      subject << 0
      subject << 21

      expect(subject.each.to_a).to eq([21, 6, 5, 4, 3])
    end
  end

  context "with explicit comparison" do
    subject { described_class.new(5) { |a, b| a[:val] >= b[:val] } }

    it "sorts using the comparison and preserves order" do
      subject << {val: 3, id: 0}
      subject << {val: 5}
      subject << {val: 3, id: 2}
      subject << {val: 4}
      subject << {val: 6}
      subject << {val: 0}
      subject << {val: 21}

      expect(subject.each.to_a)
        .to eq([{val: 21}, {val: 6}, {val: 5}, {val: 4}, {val: 3, id: 0}])
    end
  end

  context "with key comparison" do
    subject { described_class.new(5, sort_by: :val) }

    it "sorts by key" do
      subject << {val: 3, id: 0}
      subject << {val: 5}
      subject << {val: 3, id: 2}
      subject << {val: 4}
      subject << {val: 6}
      subject << {val: 0}
      subject << {val: 21}

      expect(subject.each.to_a)
        .to eq([{val: 21}, {val: 6}, {val: 5}, {val: 4}, {val: 3, id: 0}])
    end
  end
end
