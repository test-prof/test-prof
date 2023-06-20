# frozen_string_literal: true

require "cop_helper"
require "test_prof/cops/rspec/aggregate_examples"

RSpec.describe RuboCop::Cop::RSpec::AggregateExamples,
  ".matchers_with_side_effects", :config do
  let(:all_cops_config) do
    {"DisplayCopNames" => false}
  end

  subject(:cop) { described_class.new(config) }

  context "without side effect matchers defined in configuration" do
    let(:cop_config) do
      {"MatchersWithSideEffects" => []}
    end

    it "flags all examples" do
      expect_offense(<<~RUBY)
        describe do
          it { expect(entry).to validate_absence_of(:comment) }
          it { expect(entry).to validate_presence_of(:description) }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
        end
      RUBY

      expect_correction(<<~RUBY)
        describe do
          specify(:aggregate_failures) do
            expect(entry).to validate_absence_of(:comment)
            expect(entry).to validate_presence_of(:description)
          end
        end
      RUBY
    end
  end

  context "with default configuration" do
    let(:cop_config) { {} }

    it "flags without qualifiers, but does not autocorrect" do
      expect_offense(<<~RUBY)
        describe 'with and without side effects' do
          it { expect(fruit).to be_good }
          it { expect(fruit).to validate_presence_of(:color) }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2. IMPORTANT! Pay attention to the expectation order, some of the matchers have side effects.
        end
      RUBY

      expect_no_corrections
    end

    it "flags with qualifiers, but does not autocorrect" do
      expect_offense(<<~RUBY)
        describe 'with and without side effects' do
          it { expect(fruit).to be_good }
          it { expect(fruit).to allow_value('green').for(:color) }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2. IMPORTANT! Pay attention to the expectation order, some of the matchers have side effects.
          it { expect(fruit).to allow_value('green').for(:color).for(:type => :apple) }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2. IMPORTANT! Pay attention to the expectation order, some of the matchers have side effects.
          it { expect(fruit).to allow_value('green').for(:color).for(:type => :apple).during(:summer) }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2. IMPORTANT! Pay attention to the expectation order, some of the matchers have side effects.
        end
      RUBY

      expect_no_corrections
    end
  end
end
