require 'spec_helper'

class Test < ActiveFedora::Base
  include ActiveFedora::ServiceDefinitions
  #has_service_definition "monkey:100"
end

describe ActiveFedora::ServiceDefinitions do
  before(:each) do
    mmap = <<-MMAP
<fmm:MethodMap xmlns:fmm="http://fedora.comm.nsdlib.org/service/methodmap" name="Fedora MethodMap for listing collection members">
<fmm:Method operationName="getDocumentStyle1"/>
<fmm:Method operationName="getDocumentStyle2"/>
</fmm:MethodMap>
    MMAP
    @repository = ActiveFedora::Base.connection_for_pid(0)
    allow(@repository).to receive(:datastream_dissemination).with({:pid => 'test:12', :dsid => 'METHODMAP'}).and_return mmap
    Test.has_service_definition 'test:12'
  end

  subject {
      obj = Test.new()
      allow(obj).to receive(:pid).and_return('monkey:99')
      obj
    }
  describe 'method lookup' do
    it 'should find method keys in the YAML config' do
      expect(ActiveFedora::ServiceDefinitions.lookup_method('fedora-system:3', 'viewObjectProfile')).to eq(:object_profile)
    end
  end
  describe 'method creation' do
    it 'should create the system sdef methods' do
      expect(subject).to respond_to(:object_profile)
    end
    it 'should create the declared sdef methods' do
      expect(subject).to respond_to(:document_style_1)
    end
  end
  describe 'generated method' do
    it 'should call the appropriate rubydora rest api method' do
      expect(@repository).to receive(:dissemination).with({:pid => 'monkey:99', :sdef => 'test:12', :method => 'getDocumentStyle1'})
      #@mock_client.stub(:[]).with('objects/monkey%3A99/methods/test%3A12/getDocumentStyle1')

      subject.document_style_1
    end
    it 'should call the appropriate rubydora rest api method with parameters' do
      expect(@repository).to receive(:dissemination).with({:pid => 'monkey:99', :sdef => 'test:12', :method => 'getDocumentStyle1', :format => 'xml'})
      obj = Test.new()
      allow(obj).to receive(:pid).and_return('monkey:99')
      obj.document_style_1({:format => 'xml'})
    end
    it 'should call the appropriate rubydora rest api method with a block' do
      allow(@repository).to receive(:dissemination).with({:pid => 'monkey:99', :sdef => 'test:12', :method => 'getDocumentStyle1'}).and_yield 'ping!', 'pang!'
      obj = Test.new()
      allow(obj).to receive(:pid).and_return('monkey:99')
      block_response = ''
      obj.document_style_1 {|res, req|
        block_response += 'pong!' if res == 'ping!' and req == 'pang!'
      }
      expect(block_response).to eq('pong!')
    end
  end
end
