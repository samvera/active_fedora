require 'spec_helper'
require 'generators/active_fedora/config/solr/solr_generator'

describe ActiveFedora::Config::SolrGenerator do
  describe "#solr_wrapper_config" do
    let(:generator) { described_class.new }
    let(:files_to_test) { [
      'config/solr_wrapper_test.yml',
      '.solr_wrapper'
    ]}

    it "creates config files" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          generator.solr_wrapper_config
          files_to_test.each do |file|
            expect(File).to exist(file), "Expected #{file} to exist"
          end
        end
      end
    end
  end
end
