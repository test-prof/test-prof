# frozen_string_literal: true

shared_examples "TestProf::MemoryProf::Printer" do
  subject { described_class.new(tracker) }

  let(:tracker) do
    instance_double(
      TestProf::MemoryProf::Tracker,
      top_count: 3,
      total_memory: 500,
      groups: groups,
      examples: examples
    )
  end

  let(:groups) do
    [
      {name: "AnswersController", location: "./spec/controllers/answers_controller_spec.rb:3", memory: 200},
      {name: "#publish", location: "./spec/nodels/question_spec.rb:179", memory: 100},
      {name: "when email and name are present", location: "./spec/lib/import_spec.rb:34", memory: 50}
    ]
  end

  let(:examples) do
    [
      {name: "returns nil", location: "./spec/models/reports_spec.rb:57", memory: 75},
      {name: "searches users by email", location: "./spec/searches/users_search_spec.rb:15", memory: 50},
      {name: "calculates the average number of answers", location: "./spec/lib/stats_spec.rb:44", memory: 25}
    ]
  end

  before do
    allow(subject).to receive(:log)
  end
end

describe TestProf::MemoryProf::AllocPrinter do
  include_examples "TestProf::MemoryProf::Printer"

  describe "#print" do
    let(:print) { subject.print }

    context "and there are both groups and examples" do
      let(:message) do
        <<~MESSAGE
          MemoryProf results
          
          Total allocations: 500
          
          Top 3 groups (by allocations):
          
          AnswersController (./spec/controllers/answers_controller_spec.rb:3) – +200 (40.0%)
          #publish (./spec/nodels/question_spec.rb:179) – +100 (20.0%)
          when email an...me are present (./spec/lib/import_spec.rb:34) – +50 (10.0%)
          
          Top 3 examples (by allocations):
          
          returns nil (./spec/models/reports_spec.rb:57) – +75 (15.0%)
          searches users by email (./spec/searches/users_search_spec.rb:15) – +50 (10.0%)
          calculates th...ber of answers (./spec/lib/stats_spec.rb:44) – +25 (5.0%)

        MESSAGE
      end

      it "prints results for groups and examples" do
        print

        expect(subject).to have_received(:log).with(:info, message)
      end
    end

    context "and there are no examples" do
      let(:examples) { [] }

      let(:message) {
        <<~MESSAGE
          MemoryProf results
          
          Total allocations: 500
        
          Top 3 groups (by allocations):
        
          AnswersController (./spec/controllers/answers_controller_spec.rb:3) – +200 (40.0%)
          #publish (./spec/nodels/question_spec.rb:179) – +100 (20.0%)
          when email an...me are present (./spec/lib/import_spec.rb:34) – +50 (10.0%)

        MESSAGE
      }

      it "prints results for groups only" do
        print

        expect(subject).to have_received(:log).with(:info, message)
      end
    end

    context "and there are no groups" do
      let(:groups) { [] }

      let(:message) {
        <<~MESSAGE
          MemoryProf results
          
          Total allocations: 500
        
          Top 3 examples (by allocations):
        
          returns nil (./spec/models/reports_spec.rb:57) – +75 (15.0%)
          searches users by email (./spec/searches/users_search_spec.rb:15) – +50 (10.0%)
          calculates th...ber of answers (./spec/lib/stats_spec.rb:44) – +25 (5.0%)

        MESSAGE
      }

      it "prints results for examples only" do
        print

        expect(subject).to have_received(:log).with(:info, message)
      end
    end

    context "and there are no groups or examples" do
      let(:groups) { [] }
      let(:examples) { [] }

      let(:message) {
        <<~MESSAGE
          MemoryProf results
          
          Total allocations: 500

        MESSAGE
      }

      it "prints results for examples only" do
        print

        expect(subject).to have_received(:log).with(:info, message)
      end
    end
  end
end

describe TestProf::MemoryProf::RssPrinter do
  include_examples "TestProf::MemoryProf::Printer"

  describe "#print" do
    let(:print) { subject.print }

    context "and there are both groups and examples" do
      let(:message) do
        <<~MESSAGE
          MemoryProf results
          
          Final RSS: 500B
          
          Top 3 groups (by RSS):
          
          AnswersController (./spec/controllers/answers_controller_spec.rb:3) – +200B (40.0%)
          #publish (./spec/nodels/question_spec.rb:179) – +100B (20.0%)
          when email an...me are present (./spec/lib/import_spec.rb:34) – +50B (10.0%)
          
          Top 3 examples (by RSS):
          
          returns nil (./spec/models/reports_spec.rb:57) – +75B (15.0%)
          searches users by email (./spec/searches/users_search_spec.rb:15) – +50B (10.0%)
          calculates th...ber of answers (./spec/lib/stats_spec.rb:44) – +25B (5.0%)

        MESSAGE
      end

      it "prints results for groups and examples" do
        print

        expect(subject).to have_received(:log).with(:info, message)
      end
    end

    context "and there are no examples" do
      let(:examples) { [] }

      let(:message) {
        <<~MESSAGE
          MemoryProf results
          
          Final RSS: 500B
        
          Top 3 groups (by RSS):
        
          AnswersController (./spec/controllers/answers_controller_spec.rb:3) – +200B (40.0%)
          #publish (./spec/nodels/question_spec.rb:179) – +100B (20.0%)
          when email an...me are present (./spec/lib/import_spec.rb:34) – +50B (10.0%)

        MESSAGE
      }

      it "prints results for groups only" do
        print

        expect(subject).to have_received(:log).with(:info, message)
      end
    end

    context "and there are no groups" do
      let(:groups) { [] }

      let(:message) {
        <<~MESSAGE
          MemoryProf results
          
          Final RSS: 500B
        
          Top 3 examples (by RSS):
        
          returns nil (./spec/models/reports_spec.rb:57) – +75B (15.0%)
          searches users by email (./spec/searches/users_search_spec.rb:15) – +50B (10.0%)
          calculates th...ber of answers (./spec/lib/stats_spec.rb:44) – +25B (5.0%)

        MESSAGE
      }

      it "prints results for examples only" do
        print

        expect(subject).to have_received(:log).with(:info, message)
      end
    end

    context "and there are no groups or examples" do
      let(:groups) { [] }
      let(:examples) { [] }

      let(:message) {
        <<~MESSAGE
          MemoryProf results
          
          Final RSS: 500B

        MESSAGE
      }

      it "prints results for examples only" do
        print

        expect(subject).to have_received(:log).with(:info, message)
      end
    end
  end
end
