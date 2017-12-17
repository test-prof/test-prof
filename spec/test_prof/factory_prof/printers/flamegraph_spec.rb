# frozen_string_literal: true

require "spec_helper"

describe TestProf::FactoryProf::Printers::Flamegraph do
  subject { described_class }

  # rubocop:disable Style/BracesAroundHashParameters
  describe ".convert_stacks" do
    it "converts stacks to hierarchy Hash" do
      stacks = []
      stacks << %i[user account]
      stacks << %i[user account]
      stacks << %i[post account user account]
      stacks << %i[comment post]
      stacks << %i[comment user account]
      stacks << [:user]
      stacks << [:account]

      result = subject.convert_stacks(
        TestProf::FactoryProf::Result.new(
          stacks,
          {
            user: { total: 5 },
            account: { total: 6 },
            comment: { total: 2 },
            post: { total: 2 }
          }
        )
      )

      expect(result).to contain_exactly(
        {
          name: :user,
          value: 3,
          total: 5,
          children: [
            {
              name: :account,
              value: 2,
              total: 6
            }
          ]
        },
        {
          name: :post,
          value: 1,
          total: 2,
          children: [
            {
              name: :account,
              value: 1,
              total: 6,
              children: [
                name: :user,
                value: 1,
                total: 5,
                children: [
                  name: :account,
                  value: 1,
                  total: 6
                ]
              ]
            }
          ]
        },
        {
          name: :comment,
          value: 2,
          total: 2,
          children: [
            {
              name: :post,
              value: 1,
              total: 2
            },
            {
              name: :user,
              value: 1,
              total: 5,
              children: [
                {
                  name: :account,
                  value: 1,
                  total: 6
                }
              ]
            }
          ]
        },
        {
          name: :account,
          value: 1,
          total: 6
        }
      )
    end
  end
  # rubocop:enable Style/BracesAroundHashParameters
end
