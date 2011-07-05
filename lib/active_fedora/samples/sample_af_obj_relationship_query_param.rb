class SampleAFObjRelationshipQueryParam < ActiveFedora::Base
  #points to all parents linked via is_member_of
  has_relationship "parents", :is_member_of
  #returns only parents that have a level value set to "series"
  has_relationship "series_parents", :is_member_of, :query_params=>{:q=>{"level_t"=>"series"}}
  #returns all parts
  has_relationship "parts", :is_part_of, :inbound=>true
  #returns only parts that have level to "series"
  has_relationship "series_parts", :is_part_of, :inbound=>true, :query_params=>{:q=>{"level_t"=>"series"}}
  has_bidirectional_relationship "bi_series_parts", :has_part, :is_part_of, :query_params=>{:q=>{"level_t"=>"series"}}
end
