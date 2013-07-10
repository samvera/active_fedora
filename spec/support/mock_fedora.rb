def mock_client
  return @mock_client if @mock_client
  @mock_client = double("client")
  @getter = double("getter")
  @getter.stub(:get).and_return('')
  @mock_client.stub(:[]).with("describe?xml=true").and_return('')
  @mock_client 
end
  
def stub_get(pid, datastreams=nil, record_exists=false)
  pid.gsub!(/:/, '%3A')
  if record_exists
    mock_client.stub(:[]).with("objects/#{pid}?format=xml").and_return(double('get getter', :get=>'foobar'))
  else
    mock_client.stub(:[]).with("objects/#{pid}?format=xml").and_raise(RestClient::ResourceNotFound)
  end
  mock_client.stub(:[]).with("objects/#{pid}/datastreams?format=xml").and_return(@getter)
  datastreams ||= ['someData', 'withText', 'withText2', 'RELS-EXT']
  datastreams.each do |dsid|
    mock_client.stub(:[]).with("objects/#{pid}/datastreams/#{dsid}?format=xml").and_return(@getter)
  end
end

def stub_ingest(pid=nil)
  n = pid ? pid.gsub(/:/, '%3A') : nil
  mock_client.should_receive(:[]).with("objects/#{n || 'new'}").and_return(double("ingester", :post=>pid))
end

def stub_add_ds(pid, dsids)
  pid.gsub!(/:/, '%3A')
  dsids.each do |dsid|
    client = mock_client.stub(:[]).with do |params|
      /objects\/#{pid}\/datastreams\/#{dsid}/.match(params)
    end
    client.and_return(double("ds_adder", :post=>pid, :get=>''))
  end
end

def stub_get_content(pid, dsids)
  pid.gsub!(/:/, '%3A')
  dsids.each do |dsid|
    mock_client.stub(:[]).with { |params| /objects\/#{pid}\/datastreams\/#{dsid}\/content/.match(params)}.and_return(double("content_accessor", :post=>pid, :get=>''))
  end
end

