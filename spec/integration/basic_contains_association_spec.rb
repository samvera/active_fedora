require 'spec_helper'

describe ActiveFedora::Associations::BasicContainsAssociation do
  context "with a file" do
    before do
      class Source < ActiveFedora::Base
        is_a_container
      end
    end

    let(:model) { Source.new }

    after do
      Object.send(:remove_const, :Source)
    end

    it 'is empty' do
      expect(model.contains).to eq []
    end

    it 'can build a child' do
      child = model.contains.build
      expect(child).to be_kind_of ActiveFedora::File
      child.content = "hello"
      model.save!
      expect(child).to be_persisted
      expect(child.uri.to_s).to include model.uri.to_s
    end

    it 'can create a child on a persisted parent' do
      model.save!
      child = model.contains.build
      expect(child).to be_kind_of ActiveFedora::File
      child.content = "hello"
      model.save!
      expect(child).to be_persisted
      expect(child.uri.to_s).to include model.uri.to_s
    end
  end

  context "with an AF::Base object" do
    before do
      class Thing < ActiveFedora::Base
        property :title, predicate: ::RDF::Vocab::DC.title
      end
      class Source < ActiveFedora::Base
        is_a_container class_name: 'Thing'
      end
    end
    after do
      Object.send(:remove_const, :Source)
      Object.send(:remove_const, :Thing)
    end

    let(:model) { Source.new }

    it 'is empty' do
      expect(model.contains).to eq []
    end

    describe "creating" do
      it 'can build a child' do
        child = model.contains.build
        expect(model.contains.build(title: ['my title'])).to be_kind_of Thing
        model.save!
        expect(child).to be_persisted
        expect(child.uri.to_s).to include model.uri.to_s
      end

      it 'can create a child on a persisted parent' do
        model.save!
        child = model.contains.create(title: ['my title'])
        expect(child).to be_kind_of Thing
        expect(child).to be_persisted
        expect(child.uri.to_s).to include model.uri.to_s
      end
    end

    describe "loading" do
      before do
        model.save!
        model.contains.create(title: ['title 1'])
        model.contains.create(title: ['title 2'])
        model.reload
      end

      it "has the two contained objects" do
        expect(model.contains.size).to eq 2
        expect(model.contains.map(&:title)).to contain_exactly ['title 1'], ['title 2']
      end
    end

    describe "#destroy_all" do
      before do
        model.save!
        model.contains.create(title: ['title 1'])
        model.contains.create(title: ['title 2'])
        model.reload
      end

      it "destroys the two contained objects" do
        expect { model.contains.destroy_all }
          .to change { model.contains.size }.by(-2)
          .and change { Thing.count }.by(-2)
      end
    end

    describe "#reload" do
      before do
        model.save!
        child = model.contains.create(title: ['title 1'])
        model.reload # Cause the model to load its graph that contains the child ids.
        ActiveFedora::Base.find(child.id).destroy
      end

      it "can reload without attempting to load any deleted objects" do
        expect { model.contains.reload }.not_to raise_error
      end
    end
  end
end
