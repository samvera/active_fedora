require 'spec_helper'

RSpec.describe ActiveFedora::Indexing::Inserter do
  let(:solr_doc) { {} }

  it "handles many field types" do
    described_class.create_and_insert_terms('my_name', 'value', [:displayable, :searchable, :sortable], solr_doc)
    expect(solr_doc).to eq('my_name_ssm' => ['value'], 'my_name_si' => 'value', 'my_name_teim' => ['value'])
  end

  it "handles dates that are searchable" do
    described_class.create_and_insert_terms('my_name', Date.parse('2013-01-10'), [:stored_searchable], solr_doc)
    expect(solr_doc).to eq('my_name_dtsim' => ['2013-01-10T00:00:00Z'])
  end

  it "handles dates that are stored_sortable" do
    described_class.create_and_insert_terms('my_name', Date.parse('2013-01-10'), [:stored_sortable], solr_doc)
    expect(solr_doc).to eq('my_name_dtsi' => '2013-01-10T00:00:00Z')
  end

  it "handles dates that are displayable" do
    described_class.create_and_insert_terms('my_name', Date.parse('2013-01-10'), [:displayable], solr_doc)
    expect(solr_doc).to eq('my_name_ssm' => ['2013-01-10'])
  end

  it "handles dates that are sortable" do
    described_class.create_and_insert_terms('my_name', Date.parse('2013-01-10'), [:sortable], solr_doc)
    expect(solr_doc).to eq('my_name_dti' => '2013-01-10T00:00:00Z')
  end

  it "handles floating point integers" do
    described_class.create_and_insert_terms('my_number', (6.022140857 * 10**23).to_f, [:displayable, :searchable], solr_doc)
    expect(solr_doc).to eq('my_number_ssm' => ['6.0221408569999995e+23'], 'my_number_fim' => ['6.0221408569999995e+23'])
  end
end
