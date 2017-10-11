# frozen_string_literal: true

require "json"

module TestProf::FactoryProf
  module Printers
    module Flamegraph # :nodoc: all
      class << self
        include TestProf::Logging

        def dump(result)
          return log(:info, "No factories detected") if result.raw_stats == {}
          report_data = {
            total_stacks: result.stacks.size,
            total: result.total
          }

          report_data[:roots] = convert_stacks(result)

          path = generate_html(report_data)

          log :info, "FactoryFlame report generated: #{path}"
        end

        def convert_stacks(result)
          res = []

          paths = {}

          result.stacks.each do |stack|
            parent = nil
            path = ""

            stack.each do |sample|
              path = "#{path}/#{sample}"

              if paths[path]
                node = paths[path]
                node[:value] += 1
              else
                node = { name: sample, value: 1, total: result.raw_stats.fetch(sample)[:total] }
                paths[path] = node

                if parent.nil?
                  res << node
                else
                  parent[:children] ||= []
                  parent[:children] << node
                end
              end

              parent = node
            end
          end

          res
        end

        private

        def generate_html(data)
          template = File.read(TestProf.asset_path("flamegraph.template.html"))
          template.sub! '/**REPORT-DATA**/', data.to_json

          outpath = TestProf.artifact_path("factory-flame.html")
          File.write(outpath, template)
          outpath
        end
      end
    end
  end
end
