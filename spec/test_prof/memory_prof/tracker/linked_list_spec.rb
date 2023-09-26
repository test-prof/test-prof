# frozen_string_literal: true

describe TestProf::MemoryProf::Tracker::LinkedList do
  subject { described_class.new(100) }

  it "initializes a head node" do
    expect(subject.head).to have_attributes(item: :total, previous: nil, memory_at_start: 100)
  end

  describe "#add_node" do
    let(:add_node) { subject.add_node(:item, 200) }

    it "add a new node to the beginning of the list" do
      previous = subject.head
      add_node

      expect(subject.head).to have_attributes(item: :item, previous: previous, memory_at_start: 200)
    end
  end

  describe "#remove_node" do
    let(:remove_node) { subject.remove_node(:item, 300) }

    before do
      subject.add_node(:item, 200)
      allow(subject.head).to receive(:finish)
    end

    it "finishes the current head node" do
      current = subject.head
      remove_node

      expect(current).to have_received(:finish).with(300)
    end

    it "moves the head to the previous node" do
      previous = subject.head.previous
      remove_node

      expect(subject.head).to eq(previous)
    end

    it "return the current head node" do
      current = subject.head

      expect(remove_node).to eq(current)
    end
  end
end

describe TestProf::MemoryProf::Tracker::LinkedListNode do
  subject do
    described_class.new(
      item: :item,
      memory_at_start: 100,
      previous: previous
    )
  end

  let(:previous) { nil }

  describe "#total_memory" do
    before do
      subject.instance_variable_set("@memory_at_start", memory_at_start)
      subject.instance_variable_set("@memory_at_finish", memory_at_finish)
    end

    context "when memory_at_finish is nil" do
      let(:memory_at_start) { 100 }
      let(:memory_at_finish) { nil }

      it "returns 0" do
        expect(subject.total_memory).to eq(0)
      end
    end

    context "when memory_at_start > memory_at_finish" do
      let(:memory_at_start) { 200 }
      let(:memory_at_finish) { 100 }

      it "returns 0" do
        expect(subject.total_memory).to eq(0)
      end
    end

    context "when memory_at_start < memory_at_finish" do
      let(:memory_at_start) { 100 }
      let(:memory_at_finish) { 200 }

      it "calculates the difference between memory_at_finish and memory_at_start" do
        expect(subject.total_memory).to eq(100)
      end
    end
  end

  describe "#hooks_memory" do
    before do
      subject.instance_variable_set("@memory_at_start", 100)
      subject.instance_variable_set("@memory_at_finish", 200)
      subject.instance_variable_set("@nested_memory", 50)
    end

    it "calculates the difference between total_memory and nested_memory" do
      expect(subject.hooks_memory).to eq(50)
    end
  end

  describe "#finish" do
    let(:finish) { subject.finish(200) }

    context "when previous node exists" do
      let(:previous) do
        described_class.new(
          item: :previous,
          memory_at_start: 50,
          previous: nil
        )
      end

      it "sets memory_at_finish" do
        finish

        expect(subject.memory_at_finish).to eq(200)
      end

      it "updates previous.nested_memory" do
        finish

        expect(previous.nested_memory).to eq(100)
      end
    end

    context "when previous node does not exist" do
      let(:previous) { nil }

      it "sets memory_at_finish" do
        finish

        expect(subject.memory_at_finish).to eq(200)
      end
    end
  end
end
