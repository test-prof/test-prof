# frozen_string_literal: true

require "test_prof/tag_prof/result"
require "test_prof/tag_prof/printers/simple"
require "test_prof/tag_prof/printers/json"
require "test_prof/tag_prof/printers/html"

module TestProf
  module TagProf # :nodoc:
    class << self
      def printer
        case ENV["TAG_PROF_FORMAT"]
        when "html"
          Printers::HTML
        when "json"
          Printers::Json
        else
          TestProf.json_format? ? Printers::Json : Printers::Simple
        end
      end
    end
  end
end

require "test_prof/tag_prof/rspec" if TestProf.rspec?
