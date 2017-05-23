# frozen_string_literal: true

# Shared example for RSpec to profile specific examples with StackProf
RSpec.shared_context "stackprof", sprof: true do
  prepend_before do
    @stack_prof_report = TestProf::StackProf.profile
  end

  append_after do |ex|
    next unless @stack_prof_report
    TestProf::StackProf.dump ex.full_description.parameterize
  end
end
