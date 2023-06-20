# frozen_string_literal: true

require "cop_helper"
require "test_prof/cops/rspec/aggregate_examples"

RSpec.describe RuboCop::Cop::RSpec::AggregateExamples, :config do
  let(:all_cops_config) do
    {"DisplayCopNames" => false}
  end

  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    {"AddAggregateFailuresMetadata" => false}
  end

  shared_examples "flags in example group" do |group|
    it "flags examples in '#{group}'" do
      expect_offense(<<~RUBY)
        #{group} 'some docstring' do
          it { is_expected.to be_awesome }
          it { expect(subject).to be_amazing }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
          it { expect(article).to be_brilliant }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
        end
      RUBY

      expect_correction(<<~RUBY)
        #{group} 'some docstring' do
          specify do
            is_expected.to be_awesome
            expect(subject).to be_amazing
            expect(article).to be_brilliant
          end
        end
      RUBY
    end
  end

  # Detects aggregatable examples inside all aliases of example groups.
  it_behaves_like "flags in example group", :context
  it_behaves_like "flags in example group", :describe
  it_behaves_like "flags in example group", :feature
  it_behaves_like "flags in example group", :example_group

  # Non-expectation statements can have side effects, when e.g. being
  # part of the setup of the example.
  # Examples containing expectations wrapped in a method call, e.g.
  # `expect_no_corrections` are not considered aggregatable.
  it "ignores examples with non-expectation statements" do
    expect_no_offenses(<<~RUBY)
      describe do
        specify do
          something
          expect(book).to be_cool
        end
        it { expect(book).to be_awesome }
      end
    RUBY
  end

  # Both one-line examples and examples spanning multiple lines can be
  # aggregated, in case they consist only of expectation statements.
  it "flags a leading single expectation example" do
    expect_offense(<<~RUBY)
      describe do
        it { expect(candidate).to be_positive }
        specify do
        ^^^^^^^^^^ Aggregate with the example at line 2.
          expect(subject).to be_enthusiastic
          is_expected.to be_skilled
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        specify do
          expect(candidate).to be_positive
          expect(subject).to be_enthusiastic
          is_expected.to be_skilled
        end
      end
    RUBY
  end

  it "flags a following single expectation example" do
    expect_offense(<<~RUBY)
      describe do
        specify do
          expect(subject).to be_enthusiastic
          is_expected.to be_skilled
        end
        it { expect(candidate).to be_positive }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        specify do
          expect(subject).to be_enthusiastic
          is_expected.to be_skilled
          expect(candidate).to be_positive
        end
      end
    RUBY
  end

  it "flags an expectation with compound matchers" do
    expect_offense(<<~RUBY)
      describe do
        specify do
          expect(candidate)
            .to be_enthusiastic
            .and be_hard_working
        end
        it { is_expected.to be_positive }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        specify do
          expect(candidate)
            .to be_enthusiastic
            .and be_hard_working
          is_expected.to be_positive
        end
      end
    RUBY
  end

  # Not just consecutive examples can be aggregated.
  it "flags scattered aggregatable examples" do
    expect_offense(<<~RUBY)
      describe do
        it { expect(life).to be_first }
        specify do
          foo
          expect(bar).to be_foo
        end
        it { expect(work).to be_second }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
        specify do
          bar
          expect(foo).to be_bar
        end
        it { expect(other).to be_third }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        specify do
          expect(life).to be_first
          expect(work).to be_second
          expect(other).to be_third
        end
        specify do
          foo
          expect(bar).to be_foo
        end
        specify do
          bar
          expect(foo).to be_bar
        end
      end
    RUBY
  end

  # When examples have docstrings, it is incorrect to aggregate them, since
  # either docstring is lost, either it needs to be joined with the others,
  # which is an error-prone transformation.
  it "flags example with docstring, but does not autocorrect" do
    expect_offense(<<~RUBY)
      describe do
        it('is awesome') { expect(drink).to be_awesome }
        it { expect(drink).to be_cool }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_no_corrections
  end

  it "flags several examples with docstrings, but does not autocorrect" do
    expect_offense(<<~RUBY)
      describe do
        it('is awesome') { expect(drink).to be_awesome }
        it('is cool') { expect(drink).to be_cool }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_no_corrections
  end

  # Breaks examples into groups with similar metadata.
  # `aggregate_failures: true` is considered a helper metadata, and is
  # removed during aggregation.
  it "flags examples with hash metadata" do
    expect_offense(<<~RUBY)
      describe do
        it { expect(ambient_temperature).to be_mild }
        it(freeze: -30) { expect(ambient_temperature).to be_cold }
        it(aggregate_failures: true) { expect(ambient_temperature).to be_warm }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
        it(freeze: -30, aggregate_failures: true) { expect(ambient_temperature).to be_chilly }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 3.
        it(aggregate_failures: true, freeze: -30) { expect(ambient_temperature).to be_cool }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 3.
        it(aggregate_failures: false) { expect(ambient_temperature).to be_tolerable }
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        specify do
          expect(ambient_temperature).to be_mild
          expect(ambient_temperature).to be_warm
        end
        specify(freeze: -30) do
          expect(ambient_temperature).to be_cold
          expect(ambient_temperature).to be_chilly
          expect(ambient_temperature).to be_cool
        end
        it(aggregate_failures: false) { expect(ambient_temperature).to be_tolerable }
      end
    RUBY
  end

  # Same as above
  it "flags examples with symbol metadata" do
    expect_offense(<<~RUBY)
      describe do
        it { expect(fruit).to be_so_so }
        it(:peach) { expect(fruit).to be_awesome }
        it(:peach, aggregate_failures: true) { expect(fruit).to be_cool }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 3.
        it(:peach, :aggregate_failures) { expect(fruit).to be_amazing }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 3.
        it(aggregate_failures: false) { expect(ambient_temperature).to be_tolerable }
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        it { expect(fruit).to be_so_so }
        specify(:peach) do
          expect(fruit).to be_awesome
          expect(fruit).to be_cool
          expect(fruit).to be_amazing
        end
        it(aggregate_failures: false) { expect(ambient_temperature).to be_tolerable }
      end
    RUBY
  end

  it "flags examples with both metadata and docstrings, but does not autocorrect" do
    expect_offense(<<~RUBY)
      describe do
        it { expect(dragonfruit).to be_so_so }
        it(:awesome) { expect(dragonfruit).to be_awesome }
        it('is ok', :awesome) { expect(dragonfruit).to be_ok }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 3.
      end
    RUBY

    expect_no_corrections
  end

  # Examples with similar metadata of mixed types are aggregated.
  it "flags examples with mixed types of metadata" do
    expect_offense(<<~RUBY)
      describe do
        it { expect(data).to be_ok }
        it(:model, isolation: :full) { expect(data).to be_isolated }
        it(:model, isolation: :full) { expect(data).to be_saved }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 3.
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        it { expect(data).to be_ok }
        specify(:model, isolation: :full) do
          expect(data).to be_isolated
          expect(data).to be_saved
        end
      end
    RUBY
  end

  it "ignores examples defined in the loop" do
    expect_no_offenses(<<~RUBY)
      describe do
        [1, 2, 3].each do
          it { expect(weather).to be_mild }
        end
      end
    RUBY
  end

  it "flags examples with HEREDOC, but does not autocorrect" do
    expect_offense(<<~RUBY)
      describe do
        specify do
          expect(text).to span_couple_lines <<~TEXT
            Multiline text.
            Second line.
          TEXT
        end
        it { expect(text).to be_ok }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_no_corrections
  end

  it "flags examples with HEREDOC interleaved with parenthesis and curly brace, but does not autocorrect" do
    expect_offense(<<~RUBY)
      describe do
        it { expect(text).to span_couple_lines(<<~TEXT) }
          I would be quite surprised to see this in the code.
          But it's real!
        TEXT
        it { expect(text).to be_ok }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_no_corrections
  end

  it "ignores block expectation syntax" do
    expect_no_offenses(<<~RUBY)
      describe do
        specify do
          expect { something }.to do_something
        end

        specify do
          expect { something }.to do_something_else
        end
      end
    RUBY
  end

  it "flags examples with expectations with a property of something as subject" do
    expect_offense(<<~RUBY)
      describe do
        it { expect(division.result).to eq(5) }
        it { expect(division.modulo).to eq(3) }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        specify do
          expect(division.result).to eq(5)
          expect(division.modulo).to eq(3)
        end
      end
    RUBY
  end

  # Helper methods have a good chance of having side effects, and are
  # not aggregated.
  it "ignores helper method as subject" do
    expect_no_offenses(<<~RUBY)
      describe do
        specify do
          expect(multiply_by(2)).to be_multiple_of(2)
        end

        specify do
          expect(multiply_by(3)).to be_multiple_of(3)
        end
      end
    RUBY
  end

  # Examples from different contexts (examples groups) are not aggregated.
  it "ignores nested example groups" do
    expect_no_offenses(<<~RUBY)
      describe do
        it { expect(syntax_check).to be_ok }

        context do
          it { expect(syntax_check).to be_ok }
        end

        context do
          it { expect(syntax_check).to be_ok }
        end
      end
    RUBY
  end

  it "flags aggregatable examples and nested example groups" do
    expect_offense(<<~RUBY)
      describe do
        it { expect(pressure).to be_ok }
        it { expect(pressure).to be_alright }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.

        context do
          it { expect(pressure).to be_awful }
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        specify do
          expect(pressure).to be_ok
          expect(pressure).to be_alright
        end

        context do
          it { expect(pressure).to be_awful }
        end
      end
    RUBY
  end

  it "flags in the root context" do
    expect_offense(<<~RUBY)
      RSpec.describe do
        it { expect(person).to be_positive }
        it { expect(person).to be_enthusiastic }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_correction(<<~RUBY)
      RSpec.describe do
        specify do
          expect(person).to be_positive
          expect(person).to be_enthusiastic
        end
      end
    RUBY
  end

  it "flags several examples separated by newlines" do
    expect_offense(<<~RUBY)
      describe do
        it { expect(person).to be_positive }

        it { expect(person).to be_enthusiastic }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        specify do
          expect(person).to be_positive
          expect(person).to be_enthusiastic
        end
      end
    RUBY
  end

  it "flags scattered examples separated by newlines" do
    expect_offense(<<~RUBY)
      describe do
        it { expect(person).to be_positive }

        it { expect { something }.to do_something }
        it { expect(person).to be_enthusiastic }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
      end
    RUBY

    expect_correction(<<~RUBY)
      describe do
        specify do
          expect(person).to be_positive
          expect(person).to be_enthusiastic
        end

        it { expect { something }.to do_something }
      end
    RUBY
  end

  context "when AddAggregateFailuresMetadata is true" do
    let(:cop_config) do
      {"AddAggregateFailuresMetadata" => true}
    end

    it "flags examples" do
      expect_offense(<<~RUBY)
        describe do
          it { expect(life).to be_first }
          it { expect(work).to be_second }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 2.
          it(:follow, allow: true) { expect(life).to be_first }
          it(:follow, allow: true) { expect(work).to be_second }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Aggregate with the example at line 4.
        end
      RUBY

      expect_correction(<<~RUBY)
        describe do
          specify(:aggregate_failures) do
            expect(life).to be_first
            expect(work).to be_second
          end
          specify(:aggregate_failures, :follow, allow: true) do
            expect(life).to be_first
            expect(work).to be_second
          end
        end
      RUBY
    end
  end
end
