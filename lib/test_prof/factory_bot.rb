# frozen_string_literal: true

CONSTANT_NAMES = { 'factory_bot' => '::FactoryBot', 'factory_girl' => '::FactoryGirl' }.freeze

CONSTANT_NAMES.keys.each do |name|
  result = TestProf.require(name) do
    Object.const_get(CONSTANT_NAMES[name])
  end
  return TestProf::FactoryBot = result if result
end
