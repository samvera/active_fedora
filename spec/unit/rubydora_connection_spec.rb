require File.join( File.dirname(__FILE__),  "../spec_helper" )
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

  describe 'find_model' do
    
  end

  
end


