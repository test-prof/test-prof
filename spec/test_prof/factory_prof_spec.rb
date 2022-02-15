# frozen_string_literal: true

# Init FactoryProf and patch TestProf::FactoryBot, Fabrication
TestProf::FactoryProf.init
TestProf::FactoryProf.configure do |config|
  # turn on stacks collection
  config.mode = :flamegraph
end

describe TestProf::FactoryProf, :transactional do
  before { described_class.start }
  after { described_class.stop }

  # Ensure meta-queries have been performed
  before(:all) { User.first }

  def without_time(xs)
    xs.map do |x|
      expect(x.delete(:total_time)).to be_a(Float)
      expect(x.delete(:top_level_time)).to be_a(Float)
      x
    end
  end

  describe "#print" do
    let(:started_at) { Time.now }

    subject(:print) { described_class.print(started_at) }

    it "calls the customer printer" do
      expect(TestProf::FactoryProf::Printers::Simple).to receive(:dump)

      print
    end

    context "when the printer is customized" do
      class CustomPrinter
        def self.dump(result, start_time: nil)
        end
      end

      before do
        described_class.configure do |config|
          config.printer = CustomPrinter
        end
      end

      it "calls the customer printer" do
        expect(CustomPrinter).to receive(:dump)
        print
      end
    end
  end

  describe "#result" do
    subject(:result) { described_class.result }

    context "when factory_bot used" do
      it "has no stacks when no data created" do
        TestProf::FactoryBot.build_stubbed(:user)
        User.first
        expect(result.stacks.size).to eq 0
      end

      it "contains simple stack" do
        TestProf::FactoryBot.create(:user)
        expect(result.stacks.size).to eq 1
        expect(result.total_count).to eq 1
        expect(result.stacks.first).to eq([:user])
      end

      it "handles associations" do
        TestProf::FactoryBot.create(:post)

        expect(result.stacks).to contain_exactly(
          %i[post user]
        )
        expect(without_time(result.stats)).to eq(
          [
            {name: :post, total_count: 1, top_level_count: 1},
            {name: :user, total_count: 1, top_level_count: 0}
          ]
        )
      end

      it "contains many stacks" do
        TestProf::FactoryBot.create_pair(:user)
        TestProf::FactoryBot.create(:post)
        TestProf::FactoryBot.create(:user, :with_posts)

        expect(result.stacks.size).to eq 4
        expect(result.total_count).to eq 9
        expect(result.stacks).to contain_exactly(
          [:user],
          [:user],
          %i[post user],
          %i[user post user post user]
        )
        expect(without_time(result.stats)).to eq(
          [
            {name: :user, total_count: 6, top_level_count: 3},
            {name: :post, total_count: 3, top_level_count: 1}
          ]
        )
      end
    end

    context "when fabrication used" do
      it "has no stacks when no data created" do
        Fabricate.build(:user)
        User.first
        expect(result.stacks.size).to eq 0
      end

      it "contains simple stack" do
        Fabricate.create(:user)
        expect(result.stacks.size).to eq 1
        expect(result.total_count).to eq 1
        expect(result.stacks.first).to eq([:user])
      end

      it "contains many stacks" do
        Fabricate.times(2, :user)
        Fabricate.create(:post)
        Fabricate.create(:user) { Fabricate.times(2, :post) }

        expect(result.stacks.size).to eq 4
        expect(result.total_count).to eq 9
        expect(result.stacks).to contain_exactly(
          [:user],
          [:user],
          %i[post user],
          %i[user post user post user]
        )
        expect(without_time(result.stats)).to eq(
          [
            {name: :user, total_count: 6, top_level_count: 3},
            {name: :post, total_count: 3, top_level_count: 1}
          ]
        )
      end
    end
  end
end
