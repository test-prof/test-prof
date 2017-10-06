# frozen_string_literal: true

require 'minitest/base_reporter'

module Minitest
  module TestProf
    class FactoryDoctorReporter < BaseReporter # :nodoc:
      def initialize(io = $stdout, options = {})
        super
      end
    end
  end
end
