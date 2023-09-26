# frozen_string_literal: true

describe TestProf::MemoryProf::Tracker::RssTool do
  subject { described_class }

  describe ".tool" do
    before do
      allow(subject).to receive(:os_type).and_return(os_type)
    end

    context "when an OS is supported" do
      let(:os_type) { :macosx }

      it "returns an rss tool" do
        expect(subject.tool).to be_kind_of(subject::PS)
      end
    end

    context "when an OS is not supported" do
      let(:os_type) { :invalid }

      it "returns nil" do
        expect(subject.tool).to eq(nil)
      end
    end
  end

  describe ".os_type" do
    before do
      @original_os = RbConfig::CONFIG["host_os"]
      RbConfig::CONFIG["host_os"] = host_os
    end

    after do
      RbConfig::CONFIG["host_os"] = @original_os
    end

    context "when the host OS is Linux" do
      let(:host_os) { "linux" }

      it "returns :linux" do
        expect(subject.os_type).to eq(:linux)
      end
    end

    context "when the host OS is macOS" do
      let(:host_os) { "darwin22" }

      it "returns :macosx" do
        expect(subject.os_type).to eq(:macosx)
      end
    end

    context "when the host OS is macOS" do
      let(:host_os) { "mac os 14" }

      it "returns :macosx" do
        expect(subject.os_type).to eq(:macosx)
      end
    end

    %w[solaris bsd].each do |os|
      context "when the host OS is #{os}" do
        let(:host_os) { "#{os} 17" }

        it "returns :unix" do
          expect(subject.os_type).to eq(:unix)
        end
      end
    end

    context "when the host OS is Windows" do
      let(:host_os) { "mswin" }

      it "returns :windows" do
        expect(subject.os_type).to eq(:windows)
      end
    end
  end
end

describe TestProf::MemoryProf::Tracker::RssTool::ProcFS do
  subject { described_class.new }

  describe "#track" do
    before do
      io = instance_double(IO, seek: nil, gets: "46441 196384 1804 1 0 24133 0\n")

      allow(File).to receive(:open).and_return(io)
      subject.instance_variable_set("@page_size", 1024)
    end

    it "retrieves rss via proc statm" do
      subject.track

      expect(File).to have_received(:open).with(/\/proc\/\d+\/statm/, "r")
    end

    it "returns the current rss" do
      expect(subject.track).to eq(201097216)
    end
  end
end

describe TestProf::MemoryProf::Tracker::RssTool::PS do
  subject { described_class.new }

  describe "#track" do
    before do
      allow(subject).to receive(:`).and_return("   RSS\n196384")
    end

    it "retrieves rss via ps" do
      subject.track

      expect(subject).to have_received(:`).with(/ps -o rss -p \d+/)
    end

    it "returns the current rss" do
      expect(subject.track).to eq(201097216)
    end
  end
end

describe TestProf::MemoryProf::Tracker::RssTool::GetProcess do
  subject { described_class.new }

  describe "#track" do
    before do
      allow(subject).to receive(:`).and_return("\n      WS\n      --\n201097216\n\n\n")
    end

    it "retrieves rss via Get-Process" do
      subject.track

      expect(subject).to have_received(:`).with(/powershell -Command "Get-Process -Id \d+ | select WS"/)
    end

    it "returns the current rss" do
      expect(subject.track).to eq(201097216)
    end
  end
end
