# -*- encoding: utf-8 -*-
require 'spec_helper'

describe ActiveFedora::RDF do
  describe ActiveFedora::RDF::Fcrepo do
    it "registers the vocabularies" do
      namespaces = [
        "info:fedora/fedora-system:def/model#",
        "info:fedora/fedora-system:def/view#",
        "info:fedora/fedora-system:def/relations-external#",
        "info:fedora/fedora-system:"
      ]
      namespaces.each do |namespace|
        vocab = RDF::Vocabulary.find(namespace)
        expect(vocab.superclass).to be(RDF::StrictVocabulary)
      end
    end
  end
  describe ActiveFedora::RDF::ProjectHydra do
    it "registers the vocabularies" do
      namespaces = [
        "http://projecthydra.org/ns/relations#"
      ]
      namespaces.each do |namespace|
        vocab = RDF::Vocabulary.find(namespace)
        expect(vocab.superclass).to be(RDF::StrictVocabulary)
      end
    end
  end
end
