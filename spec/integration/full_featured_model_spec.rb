require 'spec_helper'
require 'rexml/document'

include ActiveFedora

describe ActiveFedora::Base do

  before(:all) do
    class OralHistory < ActiveFedora::Base
        # These are all the properties that don't quite fit into Qualified DC
        # Put them on the object itself (in the properties datastream) for now.
        has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream do |m|
          m.field "narrator",  :string
          m.field "interviewer", :string
          m.field "transcript_editor", :text
          m.field "bio", :string
          m.field "notes", :text
          m.field "hard_copy_availability", :text
          m.field "hard_copy_location", :text
          m.field "other_contributor", :string
          m.field "restrictions", :text
          m.field "series", :string
          m.field "location", :string
        end


        has_metadata :name=>"mods_article", :type=> Hydra::ModsArticleDatastream

        has_metadata :name => "dublin_core", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
          # Default :multiple => true
          #
          # on retrieval, these will be pluralized and returned as arrays
          # ie. subject_entries = my_oral_history.dublin_core.subjects
          #
          # aimint to use method-missing to support calling methods like
          # my_oral_history.subjects  OR   my_oral_history.titles  OR EVEN my_oral_history.title whenever possible

          # Setting new Types for dates and text content
          #m.field "creation_date", :date, :xml_node => "date"
          #m.field "abstract", :text, :xml_node => "abstract"
          #m.field "rights", :text, :xml_node => "rights"

          # Setting up special named fields
          #m.field "subject_heading", :string, :xml_node => "subject", :encoding => "LCSH"
          #m.field "spatial_coverage", :string, :xml_node => "spatial", :encoding => "TGN"
          #m.field "temporal_coverage", :string, :xml_node => "temporal", :encoding => "Period"
          #m.field "type", :string, :xml_node => "type", :encoding => "DCMITYPE"
          #m.field "alt_title", :string, :xml_node => "alternative"
        end

        has_metadata :name => "significant_passages", :type => ActiveFedora::SimpleDatastream do |m|
          m.field "significant_passage", :text
        end

        has_metadata :name => "sensitive_passages", :type => ActiveFedora::SimpleDatastream do |m|
          m.field "sensitive_passage", :text
        end

    end
    sample_location = "Boston, Massachusetts"
    sample_notes = 'Addelson, Frances. (1973?) "The Induced Abortion," American Journal of Ortho-Psychiatry,  Addelson, Frances. "Abortion: Source of Guilt or Growth," National Journal of Gynecology and Obstetrics., Addelson, Frances. "First Zionist Novel," Jewish Frontier.'
    sample_other_contributor = 'any other contributors, people or corporate names (eg. Temple Israel)'
    sample_transcript_editor = 'Siegel, Cheryl'
    sample_hard_copy_availability = <<-END
    Yes, please contact the Jewish Women\\\'s Archive for more information on using this source.
    END
    sample_narrator = 'Addelson, Frances'
    sample_bio = <<-END
    Rochelle Ruthchild interviewed Frances Addleson on October 18, November 14, and December 10, 1997.   The interview thoroughly examined the trajectory of Frances\' life from birth until the time of the interview. As a young child, Frances\' father died during the influenza eidemic, and her mother was not equipped to care for her and her siblings.  Consequently, they were placed in a Jewish foster home. Although her experience was mostly positive, this experience would leave life-long effects.  Frances attended Radcliffe upon the urging of a mentor and later obtained her Master\'s degree in social work from Simmons College in 1954.  In the 1940\'s, she returned to work while her children were still young; a rather unusual event for that time period.  While working as a social worker at Beth Israel Hospital in the early 1970\'s, she helped counsel countless women who came to the hospital seeking abortions before the procedure was officially legalized during the landmark Roe vs. Wade decision in 1973.  Frances would later write two articles that were published in medical journals about her experience during this time.  Although not a very religious person, Frances felt connected to the Jewish notion of social justice and remained very active until an accident in the late 1990\'s.
    END
    sample_interviewer = "Ruthchild, & Rochelle"

    @properties_sample_values2 = Hash[:narrator => "Narrator1 & Narrator2", :interviewer => "Interviewer", :transcript_editor => "Transcript Editor", :bio => "Biographic info",
                                    :notes => "My Note\\\'s a good one", :hard_copy_availability => "Yes", :hard_copy_location => "Archives", :other_contributor => "Sally Ride",
                                    :restrictions => "None", :series => "My Series", :location => "location"]

    @properties_sample_values = Hash[:narrator => sample_narrator, :interviewer => sample_interviewer, :transcript_editor => sample_transcript_editor, :bio => sample_bio,
                                    :notes => sample_notes, :hard_copy_availability => sample_hard_copy_availability, :hard_copy_location => "Archives", :other_contributor => sample_other_contributor,
                                    :restrictions => "None", :series => "My Series", :location => sample_location]

    @dublin_core_sample_values = Hash[:creator => 'Matt && McClain', :publisher => "Jewish Womens's Archive", :description => "description", :identifier => "jwa:sample_id", 
                                    :title => "title", 
                                    #:alt_title => "alt_title", :subject => "subject", 
                                    #:subject_heading => "subject heading", 
                                    #:creation_date => "2008-07-02T05:09:42.015Z", 
                                    :language => "language", 
                                    #:spatial_coverage => "spatial coverage", 
                                    #:temporal_coverage => "temporal coverage", 
                                    #:abstract => "abstract",
                                    :rights => "rights", :type => "type",
                                    #:extent => "extent", 
                                    :format => "format", :medium => "medium"]
    @signigicant_passages_sample_values = {}
    @sensitive_passages_sample_values = {}
    @sample_xml = "<xml><fields><system_create_date>REMOVED</system_create_date><system_modified_date>REMOVED</system_modified_date><active_fedora_model_s>OralHistory</active_fedora_model_s><id>changeme:14527</id><subject_heading>subject heading</subject_heading><type>type</type><rights>rights</rights><publisher>publisher</publisher><creation_date>creation date</creation_date><identifier>jwa:sample_id</identifier><format>format</format><extent>extent</extent><language>language</language><description>description</description><title>title</title><medium>medium</medium><spatial_coverage>spatial coverage</spatial_coverage><alt_title>alt_title</alt_title><temporal_coverage>temporal coverage</temporal_coverage><subject>subject</subject><creator>creator</creator><abstract>abstract</abstract><other_contributor>Sally Ride</other_contributor><transcript_editor>Transcript Editor</transcript_editor><restrictions>None</restrictions><bio>Biographic info</bio><series>My Series</series><notes>My Note</notes><location>location</location><hard_copy_availability>Yes</hard_copy_availability><narrator>Narrator</narrator><hard_copy_location>Archives</hard_copy_location><interviewer>Interviewer</interviewer></fields><content/></xml>"

  end

  before(:each) do
    @test_history = OralHistory.new
  end

  after(:each) do
  end

  after(:all) do
    Object.send(:remove_const, :OralHistory)
  end

  it "should be an instance of ActiveFedora::Base" do
    expect(@test_history).to be_kind_of(ActiveFedora::Base)
  end


  it "should create proxies to all the attached_files" do
    properties_ds = @test_history.attached_files["properties"]
    dublin_core_ds = @test_history.attached_files["dublin_core"]
    expect(@test_history.properties).to be properties_ds
    expect(@test_history).to respond_to(:properties)
    expect(OralHistory.new).to respond_to(:properties)
  end


  it "should push all of the metadata fields into solr" do
    # TODO: test must test values using solr symbol names (ie. _field, _text and _date)
    properties_ds = @test_history.attached_files["properties"]
    dublin_core_ds = @test_history.attached_files["dublin_core"]

    @properties_sample_values.each_pair do |field, value|
      next if field == :hard_copy_availability #FIXME HYDRA-824
      properties_ds.send("#{field.to_s}=", [value])
    end

    @dublin_core_sample_values.each_pair do |field, value|
      next if [:format, :type].include?(field)  #format and type are methods declared on Object
      dublin_core_ds.send("#{field.to_s}=", [value])
    end

    @test_history.save

    @solr_result = OralHistory.find_with_conditions(:id=>@test_history.id)[0]
    @properties_sample_values.each_pair do |field, value|
      next if field == :hard_copy_availability #FIXME HYDRA-824
      next if field == :location #FIXME HYDRA-825
      expect((@solr_result[ActiveFedora::SolrQueryBuilder.solr_name(field, type: :string)] || @solr_result[ActiveFedora::SolrQueryBuilder.solr_name(field, type: :date)])).to eq [::Solrizer::Extractor.format_node_value(value)]
    end

    @dublin_core_sample_values.each_pair do |field, value|
      next if [:format, :type].include?(field)  #format and type are methods declared on Object
      expect(dublin_core_ds.send("#{field.to_s}")).to eq [value]
    end
  end

  it "should have Qualified Dublin core, with custom accessors" do

    dublin_core_ds = @test_history.attached_files["dublin_core"]

    dublin_core_ds.subject = "My Subject Heading"
    dc_xml = REXML::Document.new(dublin_core_ds.to_xml)

    expect(dc_xml.root.elements["dcterms:subject"].text).to eq "My Subject Heading"

  end

  it "should support #find_with_conditions" do
    solr_result = OralHistory.find_with_conditions({})
    expect(solr_result).to_not be_nil
  end
end
