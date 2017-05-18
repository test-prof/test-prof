# frozen_string_literal: true

# Shared example for RSpec to profile specific examples with RubyProf
RSpec.shared_context "ruby-prof", rbprof: true do
  prepend_before do
    @ruby_prof_report = TestProf::RubyProf.profile
  end

  append_after do |ex|
    next unless @ruby_prof_report
    @ruby_prof_report.dump ex.full_description.parameterize
  end
end
