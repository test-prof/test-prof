# frozen_string_literal: true

if RSpec::Core::Version::STRING >= "4.0.0"
  # RSpec 4 removes monkey-patching (so bad); we bring it back
  def describe(...)
    RSpec.describe(...)
  end

  def context(...)
    RSpec.context(...)
  end

  def shared_context(...)
    RSpec.shared_context(...)
  end

  def shared_examples(...)
    RSpec.shared_examples(...)
  end

  RSpec.configure do |config|
    config.order = :defined
  end
end
