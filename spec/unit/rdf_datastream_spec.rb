require 'spec_helper'

describe ActiveFedora::RDFDatastream do
  its(:metadata?) { should be_true}
end
