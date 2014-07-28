require 'spec_helper'

describe "A versionable class" do
  before do
    class WithVersions < ActiveFedora::Base
      has_many_versions
      attribute :title, [ RDF::DC.title, FedoraLens::Lenses.single, FedoraLens::Lenses.literal_to_string ]
    end
  end

  after do
    Object.send(:remove_const, :WithVersions)
  end

  subject { WithVersions.new }

  it "should be versionable" do
    expect(subject).to be_versionable
  end

  context "after saving" do
    before do
      subject.title = "Greetings Earthlings"
      subject.save
      subject.create_version
      puts "First save"
    end

    it "should have one version (plus the root version)" do
      expect(subject.versions.size).to eq 2
      expect(subject.versions.first).to be_kind_of RDF::URI
    end

    context "two times" do
      before do
        subject.title= "Surrender and prepare to be boarded"
        subject.save
        subject.create_version
        puts "second save"
      end

      it "should have two versions (plus the root version)" do
        expect(subject.versions.size).to eq 3
        subject.versions.each do |version|
          expect(version).to be_kind_of RDF::URI
        end
      end
    end


  end

end
