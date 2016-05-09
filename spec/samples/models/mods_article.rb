require "active-fedora"
require_relative '../hydra-mods_article_datastream.rb'

# This Model is used to load & index the test:fixture_mods_article1 fixture for use in tests.
#
# See lib/samples/sample_thing.rb for a fuller, annotated example of an ActiveFedora Model
class ModsArticle < ActiveFedora::Base
  has_subresource "descMetadata", class_name: 'Hydra::ModsArticleDatastream'
end
