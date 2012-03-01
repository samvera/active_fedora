require 'spec_helper'
require 'active_fedora/rubydora_connection'

describe ActiveFedora::RubydoraConnection do


  describe 'connect' do
    it "should pass through valid options" do
      @instance = ActiveFedora::RubydoraConnection.connect :timeout => 3600, :fake_option => :missing, :force => true, :validateChecksum=>true
      @instance.client.options[:timeout].should == 3600
      @instance.config[:validateChecksum].should == true
      @instance.client.options.has_key?(:fake_option).should be_false
    end
  end


  
end


