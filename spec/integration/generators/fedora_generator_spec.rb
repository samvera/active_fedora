require 'spec_helper'
require 'generators/active_fedora/config/fedora/fedora_generator'

describe ActiveFedora::Config::FedoraGenerator do
  describe "#fcrepo_wrapper_config" do
    let(:generator) { described_class.new }
    let(:files_to_test) { [
      'config/fcrepo_wrapper_test.yml',
      '.fcrepo_wrapper'
    ]}

    before do
      generator.fcrepo_wrapper_config
    end

    after do
      files_to_test.each { |file| File.delete(file) if File.exist?(file) }
    end

    it "creates config files" do
      files_to_test.each do |file|
        expect(File).to exist(file), "Expected #{file} to exist"
      end
    end
  end
end
