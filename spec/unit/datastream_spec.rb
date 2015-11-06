require 'spec_helper'

require 'active_fedora'
require 'nokogiri'

describe ActiveFedora::Datastream do

  before(:each) do
    @test_object = ActiveFedora::Base.new
    @test_datastream = ActiveFedora::Datastream.new(@test_object.inner_object, 'abcd')
    @test_datastream.content = 'hi there'
  end

  describe '#metadata?' do
    subject { super().metadata? }
    it { is_expected.to be_falsey}
  end

  it 'should escape dots in  to_param' do
    allow(@test_datastream).to receive(:dsid).and_return('foo.bar')
    expect(@test_datastream.to_param).to eq('foo%2ebar')
  end

  it 'should be inspectable' do
    expect(@test_datastream.inspect).to match /#<ActiveFedora::Datastream @pid=\"\" @dsid=\"abcd\" @controlGroup=\"M\" changed=\"true\" @mimeType=\"\" >/
  end

  describe '#validate_content_present' do
    before :each do
      @test_datastream.content = nil
      @test_datastream.dsLocation = nil
    end

    it 'should expect content on an Inline (X) datastream' do
      @test_datastream.controlGroup = 'X'
      @test_datastream.dsLocation = 'http://example.com/test/content/abcd'
      expect(@test_datastream.validate_content_present).to be_falsey
      @test_datastream.content = '<foo><xmlelement/></foo>'
      expect(@test_datastream.validate_content_present).to be_truthy
    end

    context 'on a Managed (M) datastream' do
      before { @test_datastream.controlGroup = 'M' }
      it 'should be false when neither dsLocation nor content is present' do
        expect(@test_datastream.validate_content_present).to be_falsey
      end
      it 'should be true when dsLocation is present' do
        @test_datastream.dsLocation = 'http://example.com/test/content/abcd'
        expect(@test_datastream.validate_content_present).to be_truthy
      end
      it 'should be true when content is present' do
        @test_datastream.content = '<foo><xmlelement/></foo>'
        expect(@test_datastream.validate_content_present).to be_truthy
      end
    end

    it 'should expect a dsLocation on an External (E) datastream' do
      @test_datastream.controlGroup = 'E'
      @test_datastream.content = '<foo><xmlelement/></foo>'
      expect(@test_datastream.validate_content_present).to be_falsey
      @test_datastream.dsLocation = 'http://example.com/test/content/abcd'
      expect(@test_datastream.validate_content_present).to be_truthy
      expect(@test_datastream).to be_external
    end

    it 'should expect a dsLocation on a Redirect (R) datastream' do
      @test_datastream.controlGroup = 'R'
      @test_datastream.content = '<foo><xmlelement/></foo>'
      expect(@test_datastream.validate_content_present).to be_falsey
      @test_datastream.dsLocation = 'http://example.com/test/content/abcd'
      expect(@test_datastream.validate_content_present).to be_truthy
    end
  end

  it 'should have mimeType accessors' do
    ds1 = ActiveFedora::Datastream.new
    ds1.mimeType = 'text/foo'
    expect(ds1.mimeType).to eq('text/foo')
    ds2 = ActiveFedora::Datastream.new
    ds2.mimeType = 'text/bar'
    expect(ds2.mimeType).to eq('text/bar')
  end

  describe '.size' do
    it 'should lazily load the datastream size attribute from the fedora repository' do
      ds_profile = <<-EOS
        <datastreamProfile
            xmlns=\"http://www.fedora.info/definitions/1/0/management/\"
            xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
            xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
            xsi:schemaLocation=\"http://www.fedora.info/definitions/1/0/management/ http://www.fedora.info/definitions/1/0/datastreamProfile.xsd\"
            pid=\"#{@test_object.pid}\"
            dsID=\"#{@test_datastream.dsid}\" >
         <dsLabel></dsLabel>
         <dsVersionID>#{@test_datastream.dsid}.1</dsVersionID>
         <dsCreateDate>2011-07-11T16:48:13.536Z</dsCreateDate>
         <dsState>A</dsState>
         <dsMIME>text/xml</dsMIME>
         <dsFormatURI></dsFormatURI>
         <dsControlGroup>X</dsControlGroup>
         <dsSize>9999</dsSize>
         <dsVersionable>true</dsVersionable>
         <dsInfoType></dsInfoType>
         <dsLocation>#{@test_object.pid}+#{@test_datastream.dsid}+#{@test_datastream.dsid}.1</dsLocation>
         <dsLocationType></dsLocationType>
         <dsChecksumType>DISABLED</dsChecksumType>
         <dsChecksum>none</dsChecksum>
         </datastreamProfile>"
      EOS

      mock_repo = Rubydora::Repository.new
      allow(@test_object.inner_object).to receive(:repository).and_return(mock_repo)
      expect(mock_repo.api).to receive(:datastream).with(:dsid => 'abcd', :pid => @test_object.pid).and_return(ds_profile)
      expect(@test_datastream.size).to eq(9999)
    end

    it 'should default to an empty string if ds has not been saved' do
      expect(@test_datastream.size).to be_nil
    end
  end
end
