##
# This module is included to allow for an ActiveFedora::Base object to be set as the class_name for a Resource.
# Enables functionality like:
#   base = ActiveFedora::Base.new('oregondigital:1')
#   base.title = 'test'
#   base.save
#   subject.descMetadata.set = base
#   subject.descMetadata.set # => <ActiveFedora::Base>
#   subject.descMetadata.set.title # => 'test'
module ActiveFedora::Rdf::Identifiable
  extend ActiveSupport::Concern
  delegate :parent, :dump, :query, :rdf_type, :to => :resource

  ##
  # Defines which resource defines this ActiveFedora object.
  # This is required for ActiveFedora::Rdf::Resource#set_value to append graphs.
  # If there is no RdfResource, make a dummy one and freeze its graph.
  def resource
    return self.send(self.class.resource_datastream).resource unless self.class.resource_datastream.nil?
    ActiveFedora::Rdf::ObjectResource.new(self.pid).freeze
  end

  module ClassMethods
    ##
    # Returns the datastream whose ActiveFedora::Rdf::Resource is used
    # for the identifiable object. This supports delegating methods to
    # the Resource and #from_uri.  Defaults to :descMetadata if it
    # responds to #rdf_subject, otherwise looks for the first
    # registered datastream that does.
    def resource_datastream(ds=nil)
      @resource_datastream ||= ds ? ds : nil
      return @resource_datastream unless @resource_datastream.nil?
      return :descMetadata if self.ds_specs['descMetadata'][:type].respond_to? :rdf_subject
      self.ds_specs.each do |dsid, conf|
        return dsid.to_sym if conf[:type].respond_to? :rdf_subject
      end
      nil
    end

    ##
    # Finds the appropriate ActiveFedora::Base object given a URI from a graph.
    # Expected by the API in ActiveFedora::Rdf::Resource
    # @TODO: Generalize this.
    # @see ActiveFedora::Rdf::Resource.from_uri
    # @param [RDF::URI] uri URI that is being looked up.
    def from_uri(uri,_)
      begin
        self.find(pid_from_subject(uri))
      rescue ActiveFedora::ObjectNotFoundError
        self.ds_specs[resource_datastream.to_s][:type].resource_class.new(uri)
      end
    end

    ##
    # Finds the pid of an object from its RDF subject, override this
    # for URI configurations not of form base_uri + pid
    # @param [RDF::URI] uri URI to convert to pid
    def pid_from_subject(uri)
      base_uri = resource_datastream ? self.ds_specs[resource_datastream.to_s][:type].resource_class.base_uri : ActiveFedora::Rdf::ObjectResource.base_uri
      uri.to_s.gsub(base_uri, "")
    end
  end
end
