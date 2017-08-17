require "spec_helper"

describe TestProf::Configuration do


  context "#output_dir=" do
    subject { described_class.new.output_dir = path }
    let(:path) { "tmp/test_dir/nested" }

    before { FileUtils.rmdir path }

    it { expect { subject }.to change { File.exists? path } }
  end
end
