module ActiveFedora::File::Attributes
  delegate :mime_type=, to: :metadata

  def assign_attributes(_)
    # nop
  end

  def mime_type
    fetch_mime_type
  end

  def original_name
    @original_name ||= fetch_original_name
  end

  def original_name=(name)
    @original_name = name
  end

  def digest
    response = metadata.ldp_source.graph.query(predicate: RDF::Vocab::PREMIS.hasMessageDigest)
    # fallback on old predicate for checksum
    response = metadata.ldp_source.graph.query(predicate: fallback_digest_predicate) if response.empty?
    response.map(&:object)
  end

  def persisted_size
    ldp_source.head.content_length unless new_record?
  end

  def dirty_size
    content.size if content_changed? && content.respond_to?(:size)
  end

  def size
    dirty_size || persisted_size
  end

  def has_content?
    size && size > 0
  end

  def empty?
    !has_content?
  end

  def create_date
    created = metadata.attributes["http://fedora.info/definitions/v4/repository#created"]
    created && created.first
  end

  private

    # Fcrepo4.digest was used by Fedora < 4.3, but it was removed
    # from the 2015-07-24 version of the fedora 4 ontology
    # http://fedora.info/definitions/v4/2015/07/24/repository and
    # from rdf-vocab in version 0.8.5
    def fallback_digest_predicate
      @fallback_digest ||= if RDF::Vocab::Fcrepo4.respond_to? :digest
                             RDF::Vocab::Fcrepo4.digest
                           else
                             ::RDF::URI("http://fedora.info/definitions/v4/repository#digest")
                           end
    end

    def links
      @links ||= ldp_source.head.links
    end

    def default_mime_type
      'text/plain'
    end

    def fetch_mime_type
      return default_mime_type if new_record? && metadata.mime_type.blank?
      metadata.mime_type.first
    end

    def fetch_original_name
      return if new_record?
      ldp_source.head.content_disposition_filename
    end
end
