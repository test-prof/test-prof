# frozen_string_literal: true

module TestProf
  # Helper for output printing
  module Logging
    COLORS = {
      info: "\e[34m", # blue
      error: "\e[31m", # red
    }.freeze

    def log(level, msg)
      TestProf.config.output.puts(build_log_msg(level, msg))
    end

    def build_log_msg(level, msg)
      colorize(level, "\n[TEST PROF #{level.to_s.upcase}] #{msg}")
    end

    def colorize(level, msg)
      return msg unless TestProf.config.color?

      "#{COLORS[level]}#{msg}\e[0m"
    end
  end
end
