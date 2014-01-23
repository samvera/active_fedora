require "spec_helper"
describe ActiveFedora::Rdf::Repositories do
  subject {ActiveFedora::Rdf::Repositories}

  after(:each) do
    subject.clear_repositories!
    subject.add_repository :default, RDF::Repository.new
    subject.add_repository :vocabs, RDF::Repository.new
  end

  describe '#add_repositories' do
    it 'should accept a new repository' do
      subject.add_repository :name, RDF::Repository.new
      expect(subject.repositories).to include :name
    end
    it 'should throw an error if passed something that is not a repository' do
      expect{subject.add_repository :name, :not_a_repo}.to raise_error
    end
  end

  describe '#clear_repositories!' do
    it 'should empty the repositories list' do
      subject.clear_repositories!
      expect(subject.repositories).to be_empty
    end
  end

end
