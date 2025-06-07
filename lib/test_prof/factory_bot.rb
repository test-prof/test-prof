# frozen_string_literal: true

module TestProf # :nodoc: all
  TestProf.require("active_support")

  TestProf.require("factory_bot") do
    TestProf::FactoryBot = Object.const_get("::FactoryBot")
  end
end
