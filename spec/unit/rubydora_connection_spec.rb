require 'spec_helper'
require 'active_fedora/rubydora_connection'

describe ActiveFedora::RubydoraConnection do

  describe 'nextid' do
    before do
      @instance = ActiveFedora::RubydoraConnection.instance
    end
    it "should get nextid" do
      one = @instance.nextid
      two = @instance.nextid
      one = one.gsub('changeme:', '').to_i
      two = two.gsub('changeme:', '').to_i
      two.should == one + 1
    end
  end

  describe 'connect' do
    before do
      @instance = ActiveFedora::RubydoraConnection.instance
      @reconfig = { :force => true, :url => @instance.connection.client.url }.merge(@instance.connection.client.options)
    end
    
    after do
      ActiveFedora::RubydoraConnection.connect @reconfig
    end
    
    it "shouldn't reconnect by default" do
      client_id = @instance.connection.client.object_id
      ActiveFedora::RubydoraConnection.connect :timeout => 3600
      @instance.connection.client.object_id.should == client_id
    end
    
    it "should reconnect with force" do
      client_id = @instance.connection.client.object_id
      ActiveFedora::RubydoraConnection.connect :force => true
      @instance.connection.client.object_id.should_not == client_id
    end
    
    it "should pass through valid options" do
      ActiveFedora::RubydoraConnection.connect :timeout => 3600, :fake_option => :missing, :force => true
      @instance.connection.client.options[:timeout].should == 3600
      @instance.connection.client.options.has_key?(:fake_option).should be_false
    end
  end

  describe 'find_model' do
    
  end

  
end


