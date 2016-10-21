require 'spec_helper'

describe ActiveFedora::ReloadOnSave do
  let(:file) {  ActiveFedora::Base.new  }

  it 'defaults to call not reload' do
    expect(file).not_to receive(:reload)
    file.save
  end

  it 'reload can be turned on' do
    file.reload_on_save = true
    expect(file).to receive(:reload)
    file.save
  end

  it 'allows reload to be turned off and on' do
    file.reload_on_save = true
    expect(file).to receive(:reload).once
    file.save
    file.reload_on_save = false
    file.save
  end
end
