# frozen_string_literal: true

shared_examples "TestProf::MemoryProf::Tracker" do
  let(:list) { TestProf::MemoryProf::Tracker::LinkedList.new(100) }

  describe "#start" do
    it "initializes a linked list" do
      subject.start

      expect(subject.list).to be_kind_of(TestProf::MemoryProf::Tracker::LinkedList)
    end
  end

  describe "#finish" do
    before do
      allow(subject).to receive(:track).and_return(200)
      allow(subject).to receive(:list).and_return(list)
    end

    it "sets total_memory" do
      subject.finish

      expect(subject.total_memory).to eq(100)
    end
  end

  describe "#example_started" do
    let(:example_started) { subject.example_started({name: :example}) }

    before do
      allow(subject).to receive(:track).and_return(200)
      allow(subject).to receive(:list).and_return(list)
    end

    it "tracks memory at the start of an example" do
      example_started

      expect(subject.list.head).to have_attributes(item: {name: :example}, memory_at_start: 200)
    end
  end

  describe "#example_finished" do
    let(:example_finished) { subject.example_finished({name: :example}) }

    before do
      list.add_node({name: :example}, 200)

      allow(subject).to receive(:track).and_return(350)
      allow(subject).to receive(:list).and_return(list)
    end

    context "when the example memory > the memory of the top examples" do
      before do
        [75, 100, 125, 175, 200].each do |memory|
          subject.examples << {memory: memory}
        end
      end

      it "adds the example to the top examples" do
        example_finished

        expect(subject.examples).to match_array([
          {memory: 200},
          {memory: 175},
          {name: :example, memory: 150},
          {memory: 125},
          {memory: 100}
        ])
      end
    end

    context "when the example memory <= the memory of the top examples" do
      before do
        [175, 200, 225, 250, 275].each do |memory|
          subject.examples << {memory: memory}
        end
      end

      it "adds the example to the top examples" do
        example_finished

        expect(subject.examples).to match_array([
          {memory: 275},
          {memory: 250},
          {memory: 225},
          {memory: 200},
          {memory: 175}
        ])
      end
    end
  end

  describe "#group_started" do
    let(:group_started) { subject.group_started({name: :group}) }

    before do
      allow(subject).to receive(:track).and_return(200)
      allow(subject).to receive(:list).and_return(list)
    end

    it "tracks memory at the start of a group" do
      group_started

      expect(subject.list.head).to have_attributes(item: {name: :group}, memory_at_start: 200)
    end
  end

  describe "#group_finished" do
    let(:group_finished) { subject.group_finished({name: :group}) }

    before do
      list.add_node({name: :group}, 200)

      allow(subject).to receive(:track).and_return(350)
      allow(subject).to receive(:list).and_return(list)
    end

    context "when the group memory > the memory of the top groups" do
      before do
        [75, 100, 125, 175, 200].each do |memory|
          subject.groups << {memory: memory}
        end
      end

      it "adds the group to the top groups" do
        group_finished

        expect(subject.groups).to match_array([
          {memory: 200},
          {memory: 175},
          {name: :group, memory: 150},
          {memory: 125},
          {memory: 100}
        ])
      end
    end

    context "when the group memory <= the memory of the top groups" do
      before do
        [175, 200, 225, 250, 275].each do |memory|
          subject.groups << {memory: memory}
        end
      end

      it "adds the group to the top groups" do
        group_finished

        expect(subject.groups).to match_array([
          {memory: 275},
          {memory: 250},
          {memory: 225},
          {memory: 200},
          {memory: 175}
        ])
      end
    end
  end
end

describe TestProf::MemoryProf::AllocTracker do
  subject { described_class.new(5) }

  if RUBY_ENGINE == "jruby"
    it "raises an error" do
      expect { subject }.to raise_error("Your Ruby Engine or OS is not supported")
    end
  else
    it_behaves_like "TestProf::MemoryProf::Tracker"

    describe "#track" do
      before do
        allow(GC).to receive(:stat).and_return({total_allocated_objects: 100})
      end

      it "returns the current number of allocations" do
        expect(subject.track).to eq(100)
      end
    end

    describe "#supported?" do
      it "returns true" do
        expect(subject.supported?).to be_truthy
      end
    end
  end
end

describe TestProf::MemoryProf::RssTracker do
  subject { described_class.new(5) }

  let(:tool) { instance_double(TestProf::MemoryProf::Tracker::RssTool::PS, track: 100) }

  before do
    allow(TestProf::MemoryProf::Tracker::RssTool).to receive(:tool).and_return(tool)
  end

  it_behaves_like "TestProf::MemoryProf::Tracker"

  describe "#track" do
    it "returns the current rss" do
      expect(subject.track).to eq(100)
    end
  end

  describe "#supported?" do
    context "when the host OS is supported" do
      it "returns true" do
        expect(subject.supported?).to be_truthy
      end
    end

    context "when the host OS is not supported" do
      let(:tool) { nil }

      it "raises an error" do
        expect { subject }.to raise_error("Your Ruby Engine or OS is not supported")
      end
    end
  end
end
