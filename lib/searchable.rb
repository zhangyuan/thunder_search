module Searchable
  extend ActiveSupport::Concern

  module ClassMethods
    def search_client
      Elasticsearch::Client.new url: Settings.elasticsearch.url, log: Settings.elasticsearch.try(:log)   
    end

    def search_index_name
      Settings.elasticsearch.index
    end

    def search_index_type
      name.underscore 
    end

    def elasticsearch(options = {})
      opt = {index: search_index_name, type: search_index_type}
      opt.merge!(options)
      search_client.search opt
    end

    def delete_search_mapping
      opt = {index: self.search_index_name, type: search_index_type}
      search_client.indices.delete_mapping opt
    end

  end

  def search_index_attributes
    respond_to?(:attributes) ? attributes : {}
  end

  def create_search_index(options = {})
    opt = {index: self.class.search_index_name, type: self.class.search_index_type, id: id, body: search_index_attributes}
    opt.merge!(options)

    search_client.index opt
  end

  def delete_search_index
    opt = {index: self.class.search_index_name, type: self.class.search_index_type, id: id}
    search_client.delete opt
  end

  def search_client
    self.class.search_client 
  end
end
