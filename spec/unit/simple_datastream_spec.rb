require 'spec_helper'

describe ActiveFedora::SimpleDatastream do

  let(:sample_xml) { "<fields><coverage>coverage1</coverage><coverage>coverage2</coverage><creation_date>2012-01-15</creation_date><mydate>fake-date</mydate><publisher>publisher1</publisher></fields>" }

  before do
    @test_ds = ActiveFedora::SimpleDatastream.new
    allow(@test_ds).to receive(:retrieve_content).and_return('') # DS grabs the old content to compare against the new
    @test_ds.content = sample_xml
    @test_ds.field :coverage
    @test_ds.field :creation_date, :date
    @test_ds.field :mydate
    @test_ds.field :publisher

  end

  it "ng_xml should parse everything correctly" do
    expect(@test_ds.ng_xml).to be_equivalent_to sample_xml
  end


  describe '#new' do
    describe "model methods" do

      [:coverage, :mydate, :publisher].each do |el|
        it "should respond to getters and setters for the string typed #{el} element" do
          value = "Hey #{el}"
          @test_ds.send("#{el.to_s}=", value)
          expect(@test_ds.send(el).first).to eq value  #Looking at first because creator has 2 nodes
        end
      end

      it "should set date elements" do
        d = Date.parse('1939-05-23')
        @test_ds.creation_date = d
        expect(@test_ds.creation_date.first).to eq d
      end
    end
  end

  describe '.to_xml' do
    it 'should output the fields hash as Qualified Dublin Core XML' do
      @test_ds.publisher= "charlie"
      @test_ds.coverage= ["80%", "20%"]

      expect(@test_ds.to_xml).to be_equivalent_to('
        <fields>
          <coverage>80%</coverage>
          <coverage>20%</coverage>
          <creation_date>2012-01-15</creation_date>
          <mydate>fake-date</mydate>
          <publisher>charlie</publisher>
        </fields>')
    end
  end

  describe "#to_solr" do
    it "should have title" do
      solr = @test_ds.to_solr
      expect(solr[ActiveFedora::SolrQueryBuilder.solr_name('publisher', type: :string)]).to eq "publisher1"
      expect(solr[ActiveFedora::SolrQueryBuilder.solr_name('creation_date', type: :date)]).to eq "2012-01-15"
    end
  end
  
  describe "datastream configuration" do
    let(:foo) do
      ActiveFedora::Base.create! do |obj|
        obj.add_file(%{<?xml version="1.0"?>\n<fields><fubar>test</fubar></fields>}, path:'someData')
      end
    end
    let(:resource) { Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, foo.uri) }
    let(:orm) { Ldp::Orm.new(resource) }

    before do
      class FooHistory < ActiveFedora::Base
        has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
          m.field "fubar", :string
        end
        Deprecation.silence(ActiveFedora::Attributes) do
          has_attributes :fubar, datastream: 'someData', multiple: false
        end
      end

      orm.graph.delete([orm.resource.subject_uri, ActiveFedora::RDF::Fcrepo::Model.hasModel, nil])
      orm.graph.insert([orm.resource.subject_uri, ActiveFedora::RDF::Fcrepo::Model.hasModel, 'FooHistory'])
      orm.save
      foo.reload
      foo.update_index
    end
    
    after do
      Object.send(:remove_const, :FooHistory)
    end
    
    subject { FooHistory.find(foo.id) }
    its(:fubar) { is_expected.to eq 'test' }
  end

end
