# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"

require "sidekiq/testing"

require "isolator"

Isolator.config.raise_exceptions = true

require "test_prof/recipes/rspec/before_all"

class SampleJob
  include Sidekiq::Worker

  def perform(*_args)
    true
  end
end

class FailingJob
  include Sidekiq::Worker

  def perform(*_args)
    true
  end
end

class User < ApplicationRecord
  attr_accessor :commited
end

describe "before_all + Isolator", :transactional do
  before_all do
    @user = User.create
    SampleJob.perform_async(true)
    @user.commited = true
  end

  before_all do
    @user2 = User.create
    SampleJob.perform_async(true)
  end

  it "doesn't raise in after_commit callback" do
    expect(@user.commited).to eq true
    expect(@user2.commited).to be_nil
  end

  it "doesn't raise without transaction" do
    User.first
    SampleJob.perform_async(true)
  end

  it "fails when within transaction" do
    User.transaction do
      User.first
      FailingJob.perform_async(false)
    end
  end
end
