require 'spec_helper'

describe ActiveFedora::FixityService do
  let(:service) { described_class.new(uri) }
  let(:uri) { RDF::URI("http://path/to/resource") }

  let(:passing_fedora44_response_body) {
    <<-EOF
@prefix premis: <http://www.loc.gov/premis/rdf/v1#> .

<http://127.0.0.1:8080/rest/dev/0k/22/5b/04/0k225b04p/files/9f296a1f-10e7-44a3-83eb-4811d611edc6/fcr:versions/version1> premis:hasFixity <http://127.0.0.1:8080/rest/dev/0k/22/5b/04/0k225b04p/files/9f296a1f-10e7-44a3-83eb-4811d611edc6/fcr:versions/version1#fixity/1493843767961> .

<http://127.0.0.1:8080/rest/dev/0k/22/5b/04/0k225b04p/files/9f296a1f-10e7-44a3-83eb-4811d611edc6/fcr:versions/version1#fixity/1493843767961> a premis:Fixity , premis:EventOutcomeDetail ;
  premis:hasEventOutcome "SUCCESS"^^<http://www.w3.org/2001/XMLSchema#string> ;
  premis:hasMessageDigest <urn:sha1:b995eef5262dd1c74f0ed9c96be1f404394d45dc> ;
  premis:hasSize "103945"^^<http://www.w3.org/2001/XMLSchema#long> .
  EOF
  }

  let(:failing_fedora44_response_body) {
    <<-EOF
@prefix premis: <http://www.loc.gov/premis/rdf/v1#> .

<http://127.0.0.1:8080/rest/dev/ks/65/hc/20/ks65hc20t/files/e316b4b5-4627-44f8-9fdb-d2016e0e7380/fcr:versions/version3> premis:hasFixity <http://127.0.0.1:8080/rest/dev/ks/65/hc/20/ks65hc20t/files/e316b4b5-4627-44f8-9fdb-d2016e0e7380/fcr:versions/version3#fixity/1493844791463> .

<http://127.0.0.1:8080/rest/dev/ks/65/hc/20/ks65hc20t/files/e316b4b5-4627-44f8-9fdb-d2016e0e7380/fcr:versions/version3#fixity/1493844791463> a premis:Fixity , premis:EventOutcomeDetail ;
  premis:hasEventOutcome "BAD_CHECKSUM"^^<http://www.w3.org/2001/XMLSchema#string> , "BAD_SIZE"^^<http://www.w3.org/2001/XMLSchema#string> ;
  premis:hasMessageDigest <urn:sha1:1a89571e25dd372563a10740a883e93f8af2d146> ;
  premis:hasSize "1878582"^^<http://www.w3.org/2001/XMLSchema#long> .
EOF
  }

  describe "the instance" do
    subject { described_class.new(uri) }
    it { is_expected.to respond_to(:response) }
  end

  describe "initialize" do
    context "with a string" do
      subject { service.target }
      let(:uri) { 'http://path/to/resource' }
      it { is_expected.to eq 'http://path/to/resource' }
    end

    context "with an RDF::URI" do
      subject { service.target }
      it { is_expected.to eq 'http://path/to/resource' }
    end
  end

  describe "#verified?" do
    before { allow(service).to receive(:fixity_response_from_fedora).and_return(response) }
    subject { service.verified? }

    context "with Fedora version >= 4.4.0" do
      context "with a passing result" do
        let(:response) do
          instance_double("Response", body: passing_fedora44_response_body)
        end
        it { is_expected.to be true }
      end

      context "with a failing result" do
        let(:response) do
          instance_double("Response", body: failing_fedora44_response_body)
        end
        it { is_expected.to be false }
      end
    end

    context "with Fedora version < 4.4.0" do
      context "with a passing result" do
        let(:response) do
          instance_double("Response", body: '<subject> <http://fedora.info/definitions/v4/repository#status> "SUCCESS"^^<http://www.w3.org/2001/XMLSchema#string> .')
        end
        it { is_expected.to be true }
      end

      context "with a failing result" do
        let(:response) do
          instance_double("Response", body: '<subject> <http://fedora.info/definitions/v4/repository#status> "BAD_CHECKSUM"^^<http://www.w3.org/2001/XMLSchema#string> .')
        end
        it { is_expected.to be false }
      end
    end

    context "with a non-existent predicate" do
      let(:response) do
        instance_double("Response", body: '<subject> <http://bogus.com/definitions/v1/bogusTerm#foo> "SUCCESS"^^<http://www.w3.org/2001/XMLSchema#string> .')
      end
      it { is_expected.to be false }
    end
  end

  describe "expected_message_digest" do
    before { allow(service).to receive(:fixity_response_from_fedora).and_return(response) }
    subject { service.expected_message_digest }
    context "with success response" do
      let(:response) do
        instance_double("Response", body: passing_fedora44_response_body)
      end
      it { is_expected.to match(/urn:sha1:[a-f0-9]+/) }
    end
    context "with failure response" do
      let(:response) do
        instance_double("Response", body: failing_fedora44_response_body)
      end
      it { is_expected.to match(/urn:sha1:[a-f0-9]+/) }
    end
  end

  describe "expected_size" do
    before { allow(service).to receive(:fixity_response_from_fedora).and_return(response) }
    subject { service.expected_size }
    context "with success response" do
      let(:response) do
        instance_double("Response", body: passing_fedora44_response_body)
      end
      it { is_expected.to be_kind_of Numeric }
    end
    context "with failure response" do
      let(:response) do
        instance_double("Response", body: failing_fedora44_response_body)
      end
      it { is_expected.to be_kind_of Numeric }
    end
  end
end
