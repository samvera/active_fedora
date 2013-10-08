require 'spec_helper'

describe ActiveFedora::RelationshipGraph do
  before do 
    @graph = ActiveFedora::RelationshipGraph.new
    @n1 = ActiveFedora::Base.new()
    @n1.stub(:pid => 'foo:777')
  end

  describe "#relationships" do
    it "should have hash accessors" do
      @graph.should respond_to(:[])
    end

    it "should initialize new relation keys" do
      @graph[:has_description].should be_empty
      @graph[:has_description].should respond_to(:<<)
    end

  end

  it "should add relationships" do
    @n2 = ActiveFedora::Base.new
    @graph.add(:has_part, @n1)
    @graph[:has_part].should == [@n1]
    @graph.add(:has_part, @n2)
    @graph[:has_part].should == [@n1, @n2]
    @graph.add(:has_part, @n2)
    @graph[:has_part].should == [@n1, @n2]
    @graph.dirty.should be_true
  end

  it "should create a rdf graph" do
    graph = @graph.to_graph('info:fedora/foo:1')
    graph.should be_kind_of RDF::Graph
    graph.statements.to_a.should == []

    @graph.add(:has_part, @n1)
    graph = @graph.to_graph('info:fedora/foo:1')
    stmts = graph.statements.to_a
    stmts.size.should == 1
    stmt = stmts.first
    stmt.subject.to_s.should == 'info:fedora/foo:1'
    stmt.predicate.to_s.should == 'info:fedora/fedora-system:def/relations-external#hasPart'
    stmt.object.to_s.should == 'info:fedora/foo:777'
    
  end

  it "should have array accessor" do
    @graph.add(:has_part, @n1)
    @graph[:has_part].should == [@n1]
  end

  describe "has_predicate?" do
    it "should return true when it has it" do
      @graph.has_predicate?(:has_part).should be_false
      @graph.add(:has_part, @n1)
      @graph.has_predicate?(:has_part).should be_true
    end
  end

  describe "delete" do
    it "should delete an object when an object is passed" do
      @graph.add(:has_part, @n1)
      @graph[:has_part].should == [@n1]
      @graph.delete(:has_part, @n1)
      @graph[:has_part].should == []
    end
    it "should delete an pid when an object is passed" do
      #a reloaded rels-ext is just a list of uris, not inflated.
      @graph.add(:has_part, 'info:fedora/foo:777')
      @graph[:has_part].should == ['info:fedora/foo:777']
      @graph.delete(:has_part, @n1)
      @graph[:has_part].should == []
    end
    it "should delete an pid when a string is passed" do
      #a reloaded rels-ext is just a list of uris, not inflated.
      @graph.add(:has_part, 'info:fedora/foo:777')
      @graph[:has_part].should == ['info:fedora/foo:777']
      @graph.delete(:has_part, 'info:fedora/foo:777')
      @graph[:has_part].should == []
    end
    it "should delete an object when a pid is passed" do
      #a reloaded rels-ext is just a list of uris, not inflated.
      @graph.add(:has_part, @n1)
      @graph[:has_part].should == [@n1]
      @graph.delete(:has_part, 'info:fedora/foo:777')
      @graph[:has_part].should == []
    end

    it "should delete all the predicates if only one arg is passed" do
      @graph.add(:has_part, @n1)
      @graph[:has_part].should == [@n1]
      @graph.delete(:has_part)
      @graph.has_predicate?(:has_part).should_not be_true
    end
  end
  describe "build_statement" do
    it "should raise an error when the target is a pid, not a uri" do
      lambda { @graph.build_statement('info:fedora/spec:9', :is_part_of, 'spec:7') }.should raise_error ArgumentError
    end
    it "should run the happy path" do
      stm = @graph.build_statement('info:fedora/spec:9', :is_part_of, 'info:fedora/spec:7')
      stm.object.to_s.should == "info:fedora/spec:7"
    end
    it "should also be happy with non-info URIs" do
      stm = @graph.build_statement('info:fedora/spec:9', :is_annotation_of, 'http://www.w3.org/standards/techs/rdf')
      stm.object.to_s.should == "http://www.w3.org/standards/techs/rdf"
    end
    it "should also be happy with targets that are URI::Generics" do
      stm = @graph.build_statement('info:fedora/spec:9', :is_annotation_of, URI.parse('http://www.w3.org/standards/techs/rdf'))
      stm.object.to_s.should == "http://www.w3.org/standards/techs/rdf"
    end
  end
end
