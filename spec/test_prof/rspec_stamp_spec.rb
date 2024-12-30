# frozen_string_literal: true

require "test_prof/rspec_stamp"

describe TestProf::RSpecStamp do
  subject { described_class }

  describe "#config" do
    after { described_class.remove_instance_variable(:@config) }

    subject { described_class.config }

    it "handles array tags" do
      subject.tags = [:todo]
      expect(subject.tags).to eq([:todo])
    end

    it "handles string tags" do
      subject.tags = "todo"
      expect(subject.tags).to eq([:todo])
    end

    it "handle string hash tags" do
      subject.tags = "fix:me"
      expect(subject.tags).to eq([{fix: :me}])
    end

    it "handle several tags" do
      subject.tags = "todo,fix:me"
      expect(subject.tags).to eq([:todo, {fix: :me}])
    end
  end

  describe ".apply_tags" do
    let(:code) { source.split("\n").map { _1 + "\n" } }

    let(:lines) { [1] }

    let(:tags) { [:todo] }

    subject { described_class.apply_tags(code, lines, tags) }

    let(:source) do
      <<~CODE
        it "doesn't do what it should do" do
          expect(subject.body).to eq("OK")
        end
      CODE
    end

    let(:expected) do
      <<~CODE
        it "doesn't do what it should do", :todo do
          expect(subject.body).to eq("OK")
        end
      CODE
    end

    specify do
      is_expected.to eq 0
      expect(code.join).to eq expected
    end

    context "with several examples" do
      let(:source) do
        <<~CODE
          it 'succeeds' do
            expect(subject.body).to eq("OK")
          end

          context "not found" do
            let(:post) { draft_post }

            it 'fails' do
              expect(subject.body).to eq("Not Found")
            end
          end
        CODE
      end

      let(:expected) do
        <<~CODE
          it 'succeeds' do
            expect(subject.body).to eq("OK")
          end

          context "not found" do
            let(:post) { draft_post }

            it 'fails', :todo do
              expect(subject.body).to eq("Not Found")
            end
          end
        CODE
      end

      let(:lines) { [8] }

      specify do
        is_expected.to eq 0
        expect(code.join).to eq expected
      end

      context "patch all" do
        let(:expected) do
          <<~CODE
            it 'succeeds', :todo do
              expect(subject.body).to eq("OK")
            end

            context "not found" do
              let(:post) { draft_post }

              it 'fails', :todo do
                expect(subject.body).to eq("Not Found")
              end
            end
          CODE
        end

        let(:lines) { [1, 8] }

        specify do
          is_expected.to eq 0
          expect(code.join).to eq expected
        end
      end
    end

    context "without description" do
      let(:source) do
        <<~CODE
          specify do
            expect(subject.body).to eq("Not Found")
          end
        CODE
      end

      let(:expected) do
        <<~CODE
          specify 'works', :todo do
            expect(subject.body).to eq("Not Found")
          end
        CODE
      end

      specify do
        is_expected.to eq 0
        expect(code.join).to eq expected
      end
    end

    context "with escaped single quotes" do
      let(:source) do
        <<~CODE
          it 'has a \\' in the description' do # with comment
            expect(subject.body).to eq("Not Found")
          end
        CODE
      end

      let(:expected) do
        <<~CODE
          it "has a \\' in the description", :todo do # with comment
            expect(subject.body).to eq("Not Found")
          end
        CODE
      end

      specify do
        is_expected.to eq 0
        expect(code.join).to eq expected
      end
    end

    context "one-liner" do
      let(:source) do
        <<~CODE
          it("is") { expect(subject.body).to eq("Not Found") }
        CODE
      end

      let(:expected) do
        <<~CODE
          it('is', :todo) { expect(subject.body).to eq("Not Found") }
        CODE
      end

      specify do
        is_expected.to eq 0
        expect(code.join).to eq expected
      end
    end

    context "one-liner without description" do
      let(:source) do
        <<~CODE
          it { expect(subject.body).to eq("Not Found") }
        CODE
      end

      let(:expected) do
        <<~CODE
          it('works', :todo) { expect(subject.body).to eq("Not Found") }
        CODE
      end

      specify do
        is_expected.to eq 0
        expect(code.join).to eq expected
      end
    end

    context "with existing tags" do
      let(:source) do
        <<~CODE
          it 'is "KOI"', :log do
            expect(subject.body).to eq("Not Found")
          end
        CODE
      end

      let(:expected) do
        <<~CODE
          it 'is "KOI"', :log, :todo do
            expect(subject.body).to eq("Not Found")
          end
        CODE
      end

      specify do
        is_expected.to eq 0
        expect(code.join).to eq expected
      end
    end

    context "with several tags" do
      let(:source) do
        <<~CODE
          specify do
            expect(subject.body).to eq("Not Found")
          end
        CODE
      end

      let(:expected) do
        <<~CODE
          specify 'works', :todo, a: :b, c: 'd' do
            expect(subject.body).to eq("Not Found")
          end
        CODE
      end

      let(:tags) { [{a: :b}, :todo, {c: "d"}] }

      specify do
        is_expected.to eq 0
        expect(code.join).to eq expected
      end

      context "with existing tags" do
        let(:source) do
          <<~CODE
            it 'is', :log, level: 'debug', elastic: true do
              expect(subject.body).to eq("Not Found")
            end
          CODE
        end

        let(:expected) do
          <<~CODE
            it 'is', :log, :todo, level: 'debug', elastic: true, a: :b, c: 'd' do
              expect(subject.body).to eq("Not Found")
            end
          CODE
        end

        specify do
          is_expected.to eq 0
          expect(code.join).to eq expected
        end
      end

      context "when tags already set" do
        let(:tags) { [{log: :none}, :todo, {level: :info}] }

        let(:source) do
          <<~CODE
            it 'is', :log, level: :debug do
              expect(subject.body).to eq("Not Found")
            end
          CODE
        end

        let(:expected) do
          <<~CODE
            it 'is', :todo, log: :none, level: :info do
              expect(subject.body).to eq("Not Found")
            end
          CODE
        end

        specify do
          is_expected.to eq 0
          expect(code.join).to eq expected
        end
      end
    end

    context "with multiline description" do
      let(:source) do
        <<~CODE
          it %q{
            succeeds
            this time
          } do
            expect(subject.body).to eq("OK")
          end
        CODE
      end

      specify do
        is_expected.to eq 1
        expect(code.join).to eq source
      end
    end

    context "with example groups" do
      let(:source) do
        <<~CODE
          RSpec.describe User::Story, :account do
            it 'succeeds' do
              expect(subject.body).to eq("OK")
            end

            context 'not found', sidekiq: :fake do
              let(:post) { draft_post }

              it 'fails' do
                expect(subject.body).to eq("Not Found")
              end
            end
          end
        CODE
      end

      let(:expected) do
        <<~CODE
          RSpec.describe User::Story, :account, :todo do
            it 'succeeds' do
              expect(subject.body).to eq("OK")
            end

            context 'not found', :todo, sidekiq: :fake do
              let(:post) { draft_post }

              it 'fails', :todo do
                expect(subject.body).to eq("Not Found")
              end
            end
          end
        CODE
      end

      let(:lines) { [1, 6, 9] }

      specify do
        is_expected.to eq 0
        expect(code.join).to eq expected
      end

      context "with existing tags" do
        let(:source) do
          <<~CODE
            RSpec.describe User::Story, :slow do
              it 'succeeds' do
                expect(subject.body).to eq("OK")
              end
            end
          CODE
        end

        let(:expected) do
          <<~CODE
            RSpec.describe User::Story, slow: :todo do
              it 'succeeds' do
                expect(subject.body).to eq("OK")
              end
            end
          CODE
        end

        let(:lines) { [1] }

        let(:tags) { [{slow: :todo}] }

        specify do
          is_expected.to eq 0
          expect(code.join).to eq expected
        end
      end

      context "with existing hash tags" do
        let(:source) do
          <<~CODE
            RSpec.describe User::Story, todo: :slow do
              it 'succeeds' do
                expect(subject.body).to eq("OK")
              end
            end
          CODE
        end

        let(:expected) do
          <<~CODE
            RSpec.describe User::Story, :todo do
              it 'succeeds' do
                expect(subject.body).to eq("OK")
              end
            end
          CODE
        end

        let(:lines) { [1] }

        specify do
          is_expected.to eq 0
          expect(code.join).to eq expected
        end
      end
    end
  end
end
