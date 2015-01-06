require 'spec_helper'

describe ActiveFedora::RelationshipGraph do
  before do
    @graph = ActiveFedora::RelationshipGraph.new
    @n1 = ActiveFedora::Base.new()
    @n1.stub(:pid => 'foo:777')
  end

  describe "#relationships" do
    it "should have hash accessors" do
      expect(@graph).to respond_to(:[])
    end

    it "should initialize new relation keys" do
      expect(@graph[:fictional_key]).to be_empty
      expect(@graph[:fictional_key]).to respond_to(:<<)
    end

  end

  it "should add relationships" do
    @n2 = ActiveFedora::Base.new
    @graph.add(:has_part, @n1)
    expect(@graph.relationships[:has_part]).to eq([@n1])
    @graph.add(:has_part, @n2)
    expect(@graph.relationships[:has_part]).to eq([@n1, @n2])
    @graph.add(:has_part, @n2)
    expect(@graph.relationships[:has_part]).to eq([@n1, @n2])
    expect(@graph.dirty).to be_truthy
  end

  it "should create a rdf graph" do
    graph = @graph.to_graph('info:fedora/foo:1')
    expect(graph).to be_kind_of RDF::Graph
    expect(graph.statements.to_a).to eq([])

    @graph.add(:has_part, @n1)
    graph = @graph.to_graph('info:fedora/foo:1')
    stmts = graph.statements.to_a
    expect(stmts.size).to eq(1)
    stmt = stmts.first
    expect(stmt.subject.to_s).to eq('info:fedora/foo:1')
    expect(stmt.predicate.to_s).to eq('info:fedora/fedora-system:def/relations-external#hasPart')
    expect(stmt.object.to_s).to eq('info:fedora/foo:777')

  end

  it "should have array accessor" do
    @graph.add(:has_part, @n1)
    expect(@graph[:has_part]).to eq([@n1])
  end

  describe "has_predicate?" do
    it "should return true when it has it" do
      expect(@graph.has_predicate?(:has_part)).to be_falsey
      @graph.add(:has_part, @n1)
      expect(@graph.has_predicate?(:has_part)).to be_truthy
    end
  end

  describe "delete" do
    it "should delete an object when an object is passed" do
      @graph.add(:has_part, @n1)
      expect(@graph[:has_part]).to eq([@n1])
      @graph.delete(:has_part, @n1)
      expect(@graph[:has_part]).to eq([])
    end
    it "should delete an pid when an object is passed" do
      #a reloaded rels-ext is just a list of uris, not inflated.
      @graph.add(:has_part, 'info:fedora/foo:777')
      expect(@graph[:has_part]).to eq(['info:fedora/foo:777'])
      @graph.delete(:has_part, @n1)
      expect(@graph[:has_part]).to eq([])
    end
    it "should delete an pid when a string is passed" do
      #a reloaded rels-ext is just a list of uris, not inflated.
      @graph.add(:has_part, 'info:fedora/foo:777')
      expect(@graph[:has_part]).to eq(['info:fedora/foo:777'])
      @graph.delete(:has_part, 'info:fedora/foo:777')
      expect(@graph[:has_part]).to eq([])
    end
    it "should delete an object when a pid is passed" do
      #a reloaded rels-ext is just a list of uris, not inflated.
      @graph.add(:has_part, @n1)
      expect(@graph[:has_part]).to eq([@n1])
      @graph.delete(:has_part, 'info:fedora/foo:777')
      expect(@graph[:has_part]).to eq([])
    end

    it "should delete all the predicates if only one arg is passed" do
      @graph.add(:has_part, @n1)
      expect(@graph[:has_part]).to eq([@n1])
      @graph.delete(:has_part)
      expect(@graph.has_predicate?(:has_part)).not_to be_truthy
    end
  end
  describe "build_statement" do
    it "should raise an error when the target is a pid, not a uri" do
      expect { @graph.build_statement('info:fedora/spec:9', :is_part_of, 'spec:7') }.to raise_error ArgumentError
    end
    it "should run the happy path" do
      stm = @graph.build_statement('info:fedora/spec:9', :is_part_of, 'info:fedora/spec:7')
      expect(stm.object.to_s).to eq("info:fedora/spec:7")
    end
    it "should also be happy with non-info URIs" do
      stm = @graph.build_statement('info:fedora/spec:9', :is_annotation_of, 'http://www.w3.org/standards/techs/rdf')
      expect(stm.object.to_s).to eq("http://www.w3.org/standards/techs/rdf")
    end
    it "should also be happy with targets that are URI::Generics" do
      stm = @graph.build_statement('info:fedora/spec:9', :is_annotation_of, URI.parse('http://www.w3.org/standards/techs/rdf'))
      expect(stm.object.to_s).to eq("http://www.w3.org/standards/techs/rdf")
    end
  end
end
