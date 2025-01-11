# frozen_string_literal: true

describe TestProf::YJIT do
  context "with YJIT usage warning" do
    context "by default" do
      specify "stays silent" do
        output = run_rspec("dummy")

        expect(output).to_not include("YJIT")
      end
    end

    # Should only Run on Rubies that have YJIT.
    if defined?(RubyVM) && defined?(RubyVM::YJIT)
      # Note that we should not really enable YJIT here to test if it detects
      # actual usage (`RubyVM::YJIT.enabled?`), as it is currently
      # impossible to programmatically disable it after enabling.
      context "with YJIT enabled" do
        specify "warns about using YJIT" do
          output = run_rspec("dummy", env: {"RUBY_YJIT_ENABLE" => "1"})

          expect(output).to include("YJIT")
          expect(output).to include("RUBY_YJIT_ENABLE")
        end

        context "when turned off" do
          specify "does not warn about using YJIT" do
            output = run_rspec("dummy",
              env: {"RUBY_YJIT_ENABLE" => "1", "YJIT_PROF" => "0"})

            expect(output).to_not include("YJIT")
          end
        end
      end
    end
  end
end
