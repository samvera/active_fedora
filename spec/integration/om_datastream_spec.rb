require 'spec_helper'

describe ActiveFedora::OmDatastream do
  before(:all) do
    class ModsArticle2 < ActiveFedora::Base
      # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
      has_subresource "descMetadata", class_name: 'Hydra::ModsArticleDatastream'
    end
  end

  after(:all) do
    Object.send(:remove_const, :ModsArticle2)
  end

  let(:obj) { ModsArticle2.create.reload }

  after(:each) do
    obj.destroy
  end

  subject(:desc_metadata) { obj.descMetadata }

  describe "#changed?" do
    it "is not changed when no fields have been set" do
      expect(desc_metadata).to_not be_content_changed
    end
    it "is changed when a field has been set" do
      desc_metadata.title = 'Foobar'
      expect(desc_metadata).to be_content_changed
    end
    it "is not changed if the new xml matches the old xml" do
      desc_metadata.content = desc_metadata.content
      expect(desc_metadata).to_not be_content_changed
    end

    it "is changed if there are minor differences in whitespace" do
      desc_metadata.content = "<a><b>1</b></a>"
      obj.save
      expect(desc_metadata).to_not be_content_changed
      desc_metadata.content = "<a>\n<b>1</b>\n</a>"
      expect(desc_metadata).to be_content_changed
    end
  end

  describe "empty datastream content" do
    it "does not break when there is empty datastream content" do
      desc_metadata.content = ""
      obj.save
    end
  end

  describe '.update_values' do
    before do
      desc_metadata.content = File.read(fixture('mods_articles/mods_article1.xml'))
      obj.save
      obj.reload
    end

    it "is not dirty after .update_values is saved" do
      obj.descMetadata.update_values([{ name: 0 }, { role: 0 }, :text] => "Funder")
      expect(obj.descMetadata).to be_content_changed
      obj.save
      expect(obj.descMetadata).to_not be_content_changed
      expect(obj.descMetadata.term_values({ name: 0 }, { role: 0 }, :text)).to eq ["Funder"]
    end
  end

  describe ".to_solr" do
    before do
      desc_metadata.journal.issue.publication_date = Date.parse('2012-11-02')
      obj.save!
      obj.reload
    end
    it "solrizes terms with :type=>'date' to *_dt solr terms" do
      expect(obj.to_solr[ActiveFedora.index_field_mapper.solr_name('desc_metadata__journal_issue_publication_date', type: :date)]).to eq ['2012-11-02T00:00:00Z']
    end
  end
end
