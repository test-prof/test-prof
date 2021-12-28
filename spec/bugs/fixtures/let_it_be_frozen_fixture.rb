# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../support/ar_models"

require "test-prof"
require "test_prof/recipes/rspec/let_it_be"

RSpec.configure do |config|
  config.include TestProf::FactoryBot::Syntax::Methods
end

# ======== models and factories =========
class Parent
  include ActiveModel::Model

  attr_accessor :count

  def initialize(*args)
    super
    self.count ||= 0
  end

  def reload
    self.class.new(count: count)
  end

  def save!
    self
  end
end

class Child
  include ActiveModel::Model

  attr_accessor :parent

  def reload
    self.class.new(parent: parent)
  end

  def save!
    self
  end
end

FactoryBot.define do
  factory :parent, class: Parent do
  end

  factory :child, class: Child do
    parent { Parent.new }

    after(:create) do |child|
      puts "child.parent.frozen? (#{child.parent.frozen?})"
      child.parent.count += 1
    end
  end
end

# ======= specs =======

RSpec.shared_context "models A" do
  let_it_be(:child) { create(:child) }
  let_it_be(:parent, reload: true) { child.parent }
end

RSpec.shared_context "models B" do
  let_it_be(:child2) { create(:child, parent: parent) }
end

RSpec.shared_examples "count models" do |number|
  it { expect(parent.count).to eq(number) }
end

RSpec.shared_examples "some shared example" do
  include_context "models A"

  context "some context" do
    it { is_expected.to eq("something") }

    context "nested with extra context will fail if the model is referenced in the main describe" do
      include_context "models B"

      it_behaves_like "count models", 2
    end

    context "nested with extra context will not fail due to the workaround" do
      # workaround, it will work but will create all "models A" shared context once again.
      include_context "models A"
      include_context "models B"

      it_behaves_like "count models", 2
    end
  end
end

RSpec.describe "test-prof contexts", type: :model do
  it_behaves_like "some shared example" do
    # here the factory will receive a frozen object
    subject(:references_the_model) do
      parent.frozen? # can be anything, just call the model
      "something"
    end
  end

  it_behaves_like "some shared example" do
    # here, the factory does not receives a frozen object
    subject(:not_references_the_model) do
      "something"
    end
  end
end
