# frozen_string_literal: true

require 'rubocop/rspec/support'
require 'test_prof/cops/rspec/aggregate_failures'

describe RuboCop::Cop::RSpec::AggregateFailures, :config do
  subject(:cop) { described_class.new(config) }

  it 'rejects two one-liners in a row' do
    inspect_source(['context "request" do',
                    '  it { is_expected.to be_success }',
                    '  it { expect(response.body).to eq "OK" }',
                    'end'])

    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to eq('Use :aggregate_failures instead of several one-liners.')
  end

  it 'rejects two one-liners when blank lines and non-example blocks' do
    inspect_source(['context "request" do',
                    '  let(:user) { create(:user) } ',
                    '  before { get "/" }',
                    '',
                    '  it { is_expected.to be_success }',
                    '  ',
                    '      ',
                    '  it { expect(response.body).to eq "OK" }',
                    'end'])
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to eq('Use :aggregate_failures instead of several one-liners.')
  end

  it 'rejects one-liners with nested context' do
    inspect_source(['context "request" do',
                    '  it { is_expected.to be_success }',
                    '  it "works" do',
                    '    expect(subject).to be_ok',
                    '  end',
                    '  it { expect(response.body).to eq "OK" }',
                    '',
                    '  context "sub-request" do',
                    '    let(:params) { "?q=1" }',
                    '    it { is_expected.to be_valid }',
                    '  end',
                    'end'])
    expect(cop.offenses).to be_empty
  end

  it 'accepts single one-liner' do
    inspect_source(['context "request" do',
                    '  it { is_expected.to be_success }',
                    'end'])
    expect(cop.offenses).to be_empty
  end

  it 'accepts non-regular one-liners' do
    inspect_source(['context "request" do',
                    '  its(:foo) { is_expected.to be_success }',
                    '  pending { is_expected.to fail }',
                    'end'])
    expect(cop.offenses).to be_empty
  end

  it 'accepts one-liners separated by multiliners' do
    inspect_source(['context "request" do',
                    '  it { is_expected.to be_success }',
                    '  it "works" do',
                    '    expect(subject).to be_ok',
                    '  end',
                    '  it { expect(response.body).to eq "OK" }',
                    'end'])
    expect(cop.offenses).to be_empty
  end

  it 'handles edge cases' do
    inspect_source(['context "request" do',
                    '  include_examples "edges"',
                    '  xdescribe "POST #create" do',
                    '  end',
                    '',
                    '  pending {}',
                    'end'])
    expect(cop.offenses).to be_empty
  end

  it 'handles edge cases 2' do
    inspect_source(['context "request" do',
                    '  include_examples "edges"',
                    'end'])
    expect(cop.offenses).to be_empty
  end

  describe "#autocorrect" do
    it "corrects two one-liners" do
      new_source = autocorrect_source(
        ['context "request" do',
         '  it { is_expected.to be_success }',
         '  it { expect(response.body).to eq "OK" }',
         'end']
      )

      expect(new_source).to eq(
        ['context "request" do',
         '  it "works", :aggregate_failures do',
         '    is_expected.to be_success',
         '    expect(response.body).to eq "OK"',
         '  end',
         'end'].join("\n")
      )
    end

    it 'corrects indented one-liners when blank lines and non-example blocks' do
      new_source = autocorrect_source(
        ['describe "GET #index" do',
         '  context "request" do',
         '    let(:user) { create(:user) } ',
         '    before { get "/" }',
         '',
         '    it { is_expected.to be_success }',
         '      ',
         '      ',
         '    it { expect(response.body).to eq "OK" }',
         '  end',
         'end']
      )
      expect(new_source).to eq(
        ['describe "GET #index" do',
         '  context "request" do',
         '    let(:user) { create(:user) } ',
         '    before { get "/" }',
         '',
         '    it "works", :aggregate_failures do',
         '      is_expected.to be_success',
         '      expect(response.body).to eq "OK"',
         '    end',
         '  end',
         'end'].join("\n")
      )
    end

    it "corrects several groups" do
      new_source = autocorrect_source(
        [
          'describe "GET #index" do',
          '  context "request" do',
          '    let(:user) { create(:user) } ',
          '    before { get "/" }',
          '',
          '    it { is_expected.to be_success }',
          '      ',
          '      ',
          '    it { expect(response.body).to eq "OK" }',
          '',
          '    context "sub-request", :invalid do',
          '      it { is_expected.not_to be_success }',
          '      it { expect(response.body).to eq "FAILED" }',
          '    end',
          '  end',
          'end'
        ]
      )

      expect(new_source).to eq(
        ['describe "GET #index" do',
         '  context "request" do',
         '    let(:user) { create(:user) } ',
         '    before { get "/" }',
         '',
         '    it "works", :aggregate_failures do',
         '      is_expected.to be_success',
         '      expect(response.body).to eq "OK"',
         '    end',
         '',
         '    context "sub-request", :invalid do',
         '      it "works", :aggregate_failures do',
         '        is_expected.not_to be_success',
         '        expect(response.body).to eq "FAILED"',
         '      end',
         '    end',
         '  end',
         'end'].join("\n")
      )
    end
  end
end
