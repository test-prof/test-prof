# frozen_string_literal: true

require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"

require "test_prof/recipes/rspec/let_it_be"

RSpec.describe "Overriding detection", :transactional do
  context "when report_duplicates was set as :raise" do
    context "when let_it_be redefined" do
      context "when on same nested level" do
        it "raises a duplication error" do
          expect do
            TestProf::LetItBe.configure do |config|
              config.report_duplicates = :raise
            end

            RSpec.describe "let_it_be on same nested level" do
              include TestProf::FactoryBot::Syntax::Methods

              let_it_be(:user) { create(:user) }
              let_it_be(:user) { create(:user) }
            end
          end.to raise_error(TestProf::LetItBe::DuplicationError)
        end
      end

      context "when nested level is 2" do
        it "raises a duplication error" do
          expect do
            TestProf::LetItBe.configure do |config|
              config.report_duplicates = :raise
            end

            RSpec.describe "let_it_be in nested context" do
              include TestProf::FactoryBot::Syntax::Methods

              let_it_be(:user) { create(:user) }

              context "nested context level 2" do
                let_it_be(:user) { create(:user) }
              end
            end
          end.to raise_error(TestProf::LetItBe::DuplicationError)
        end
      end

      context "when nested level is 3" do
        it "raises a duplication error" do
          expect do
            TestProf::LetItBe.configure do |config|
              config.report_duplicates = :raise
            end

            RSpec.describe "let_it_be in nested context" do
              include TestProf::FactoryBot::Syntax::Methods

              let_it_be(:user) { create(:user) }

              context "nested context level 2" do
                context "nested context level 3" do
                  let_it_be(:user) { create(:user) }
                end
              end
            end
          end.to raise_error(TestProf::LetItBe::DuplicationError)
        end
      end
    end

    context "when defined let and let_it_be" do
      it "does not raise a duplication error" do
        expect do
          TestProf::LetItBe.configure do |config|
            config.report_duplicates = :raise
          end

          RSpec.describe "let_it_be and let" do
            include TestProf::FactoryBot::Syntax::Methods

            let(:user) { create(:user) }

            context "nested context level 2" do
              let_it_be(:user) { create(:user) }
            end
          end
        end.not_to raise_error
      end
    end
  end

  context "when report_duplicates was set as :warn" do
    let(:warning_msg) { "let_it_be(:user) was redefined in nested group" }

    before do
      allow(::RSpec).to receive(:warn_with).with(warning_msg)
    end

    context "when let_it_be redefined" do
      context "when on same nested level" do
        it "warns a duplication message" do
          RSpec.describe "let_it_be on same nested level" do
            include TestProf::FactoryBot::Syntax::Methods

            TestProf::LetItBe.configure do |config|
              config.report_duplicates = :warn
            end

            let_it_be(:user) { create(:user) }
            let_it_be(:user) { create(:user) }
          end.run

          expect(::RSpec).to have_received(:warn_with).with(warning_msg).once
        end
      end

      context "when nested level is 2" do
        it "warns a duplication message" do
          RSpec.describe "let_it_be in nested context" do
            include TestProf::FactoryBot::Syntax::Methods

            TestProf::LetItBe.configure do |config|
              config.report_duplicates = :warn
            end

            let_it_be(:user) { create(:user) }

            context "nested context" do
              let_it_be(:user) { create(:user) }
            end
          end.run

          expect(::RSpec).to have_received(:warn_with).with(warning_msg).once
        end
      end

      context "when nested level is 3" do
        it "warns a duplication message" do
          RSpec.describe "let_it_be in nested context" do
            include TestProf::FactoryBot::Syntax::Methods

            TestProf::LetItBe.configure do |config|
              config.report_duplicates = :warn
            end

            let_it_be(:user) { create(:user) }

            context "nested context level 2" do
              context "nested context level 3" do
                let_it_be(:user) { create(:user) }
              end
            end
          end.run

          expect(::RSpec).to have_received(:warn_with).with(warning_msg).once
        end
      end
    end

    context "when defined let and let_it_be" do
      it "does not warn a duplication message" do
        RSpec.describe "let_it_be and let" do
          include TestProf::FactoryBot::Syntax::Methods

          TestProf::LetItBe.configure do |config|
            config.report_duplicates = :raise
          end

          let(:user) { create(:user) }

          context "nested context level 2" do
            let_it_be(:user) { create(:user) }
          end
        end.run

        expect(::RSpec).not_to have_received(:warn_with)
      end
    end
  end
end
