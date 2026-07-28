# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "active_support"
require "active_support/callbacks"
require "test-prof"

class Record
  include ActiveSupport::Callbacks

  define_callbacks :save

  set_callback :save, :before, :normalize
  set_callback :save, :after, :audit

  def normalize
  end

  def audit
  end

  def save
    run_callbacks(:save) { true }
  end
end

describe "Record callbacks" do
  it "runs before and after callbacks twice" do
    Record.new.save
    Record.new.save
    expect(true).to eq true
  end
end
