# frozen_string_literal: true

require "cop_helper"
require "rubocop/test_prof/cops/rspec/aggregate_examples"

RSpec.describe RuboCop::Cop::RSpec::AggregateExamples, ".its", :config do
  let(:all_cops_config) do
    {"DisplayCopNames" => false}
  end

  let(:cop_config) do
    {"AddAggregateFailuresMetadata" => false}
  end

  subject(:cop) { described_class.new(config) }

  # Regular `its` call with an attribute/method name, or a chain of methods
  # expressed as a string with dots.
  it "flags `its`" do
    expect_offense(<<~RUBY)
      describe do
        its(:one) { is_expected.to be(true) }
        it { is_expected.to be_cool }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
        its('phone_numbers.size') { is_expected.to be(2) }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
        its(:historical_values) { are_expected.to be([true, true]) }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        specify do
          expect(subject.one).to be(true)
          is_expected.to be_cool
          expect(subject.phone_numbers.size).to be(2)
          expect(subject.historical_values).to be([true, true])
        end
      end
    RUBY
  end

  # For single-element array argument, it's possible to make a proper
  # correction for `its`.
  it "flags `its` with single element array syntax" do
    expect_offense(<<~RUBY)
      describe do
        its([:one]) { is_expected.to be(true) }
        its(['two']) { is_expected.to be(false) }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        specify do
          expect(subject[:one]).to be(true)
          expect(subject['two']).to be(false)
        end
      end
    RUBY
  end

  # `its` with multi-element array argument is ambiguous, and depends on
  # the type of the subject, and depending on in and on argument passed:
  # - a Hash: `hash[element1][element2]...`
  # - and arbitrary type: `hash[element1, element2, ...]`
  # It is impossible to infer the type to propose a proper correction.
  it "flags `its` with multiple element array syntax, but does not autocorrect" do
    expect_offense(<<~RUBY)
      describe do
        its([:one, :two]) { is_expected.to be(true) }
        it { is_expected.to be_cool }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_no_corrections
  end

  # Supports single-element `its` array argument with metadata.
  it "flags `its` with metadata" do
    expect_offense(<<~RUBY)
      describe do
        its([:one], night_mode: true) { is_expected.to be(true) }
        its(['two']) { is_expected.to be(false) }
        its(:three, night_mode: true) { is_expected.to be(true) }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        specify(night_mode: true) do
          expect(subject[:one]).to be(true)
          expect(subject.three).to be(true)
        end
        its(['two']) { is_expected.to be(false) }
      end
    RUBY
  end

  # This might be a future improvement to detect this. There's no certainty
  # if the following is a correct replacement:
  #
  #   describe do
  #     specify do
  #       expect(subject.public_send(one)).to ... }
  #       expect(subject.public_send(two)).to ... }
  #     end
  #   end
  #
  # NOTE: The same applies to method calls, instance, class, global vars and
  #       constants.
  it "flags `its` with a send node, but does not autocorrect" do
    expect_offense(<<~RUBY)
      describe do
        its(one) { is_expected.to be(false) }
        its(two) { is_expected.to be(true) }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_no_corrections
  end
end
