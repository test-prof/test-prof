# frozen_string_literal: true

module TestProf
  module AnyFixture
    class Dump
      module Digest
        class << self
          def call(*paths)
            paths.size.to_s
          end
        end
      end
    end
  end
end
