def mock_client
  return @mock_client if @mock_client
  @mock_client = mock("client")
  @getter = mock("getter")
  @getter.stubs(:get).returns('')
  @mock_client 
end
  
def stub_get(pid, record_exists=false)
  pid.gsub!(/:/, '%3A')
  mock_client.stubs(:[]).with("objects/#{pid}?format=xml").returns(stub('get getter', :get=>'foobar')) if record_exists
 # @mock_client.expects(:[]).with("objects/#{pid}?format=xml").raises(RestClient::ResourceNotFound) unless record_exists
  mock_client.stubs(:[]).with("objects/#{pid}/datastreams?format=xml").returns(@getter)
  ['someData', 'withText', 'withText2', 'RELS-EXT'].each do |dsid|
    mock_client.stubs(:[]).with("objects/#{pid}/datastreams/#{dsid}?format=xml").returns(@getter)
  end
end
def stub_ingest(pid)
  mock_client.stubs(:[]).with("objects/#{pid || 'new'}").returns(stub("ingester", :post=>pid))
end

def stub_add_ds(pid, dsids)
  dsids.each do |dsid|
    client = mock_client.stubs(:[]).with do |params|
      /objects\/#{pid}\/datastreams\/#{dsid}/.match(params)
    end
    client.returns(stub("ds_adder", :post=>pid, :get=>''))
  end
end

def stub_get_content(pid, dsids)
  pid.gsub!(/:/, '%3A')
  dsids.each do |dsid|
    mock_client.stubs(:[]).with { |params| /objects\/#{pid}\/datastreams\/#{dsid}\/content/.match(params)}.returns(stub("content_accessor", :post=>pid, :get=>''))
  end
end

