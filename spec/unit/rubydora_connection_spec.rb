require 'spec_helper'
require 'active_fedora/rubydora_connection'

describe ActiveFedora::RubydoraConnection do
  describe 'initialize' do
    it "should pass through valid options" do
      @instance = ActiveFedora::RubydoraConnection.new :timeout => 3600, :fake_option => :missing, :force => true, :validateChecksum=>true
      @instance.connection.client.options[:timeout].should == 3600
      @instance.connection.config[:validateChecksum].should == true
      @instance.connection.client.options.has_key?(:fake_option).should be_false
    end
  end
end
