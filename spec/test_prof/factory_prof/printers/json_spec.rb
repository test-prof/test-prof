# frozen_string_literal: true

describe TestProf::FactoryProf::Printers::Json do
  let(:stacks) do
    stacks = []
    stacks << %i[user account]
    stacks << %i[user account]
    stacks << %i[post account user account]
    stacks << %i[comment post]
    stacks << %i[comment user account]
    stacks << [:user]
    stacks << [:account]
    stacks
  end

  let(:stats) do
    {
      user: {name: :user, total_count: 5, total_time: 1.0, top_level_count: 5, top_level_time: 0.1, variations: []},
      account: {name: :account, total_count: 6, total_time: 2.0, top_level_count: 6, top_level_time: 0.2, variations: []},
      comment: {name: :comment, total_count: 2, total_time: 3.0, top_level_count: 2, top_level_time: 0.3, variations: []},
      name: {name: :post, total_count: 2, total_time: 4.0, top_level_count: 0, top_level_time: 0.4, variations: []}
    }
  end

  let(:result) { TestProf::FactoryProf::Result.new(stacks, stats) }

  describe "#dump" do
    before do
      allow(File).to receive(:write)
      allow(TestProf).to receive(:artifact_path).and_return("test-prof.result.json")
    end

    it "write json" do
      described_class.dump(result, start_time: 0)
      outpath = TestProf.artifact_path("test-prof.result.json")
      expect(File).to have_received(:write).with(outpath, String).once
    end
  end

  describe "#convert_stats" do
    before do
      allow(TestProf).to receive(:now).and_return(2.0)
    end

    it "calculates factories usage" do
      stats = described_class.convert_stats(result, 0.0)

      expect(stats).to include({
        total_count: 15,
        total_top_level_count: 13,
        total_time: 1.0,
        total_run_time: 2.0,
        total_uniq_factories: 4
      })
    end
  end

  describe "#dump" do
    before do
      allow(TestProf).to receive(:now).and_return(2.0)
    end

    it "wraps results into the uniform envelope" do
      payload = nil
      allow(File).to receive(:write) { |_outpath, data| payload = data }

      described_class.dump(result, start_time: 0.0)

      expect(JSON.parse(payload)).to include(
        "profiler" => "factory_prof",
        "schema_version" => 1,
        "test_prof_version" => TestProf::VERSION,
        "data" => include(
          "total_count" => 15,
          "total_time" => 1.0,
          "total_run_time" => 2.0
        )
      )
    end
  end
end
