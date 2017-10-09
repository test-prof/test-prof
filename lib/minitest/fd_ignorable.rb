# frozen_string_literal: true

module Minitest
  module Assertions # :nodoc:
    def fd_ignore
      @fd_ignore = true
    end

    def fd_ignore?
      @fd_ignore == true
    end
  end
end
