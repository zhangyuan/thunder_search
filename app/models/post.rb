class Post
  include Searchable

  attr_accessor :title, :content, :path

  def initialize(attributes = {})
    attributes.each_pair do |name, value|
      send("#{name}=", value) 
    end  
  end

  def search_index_attributes
    {title: title, content: content, path: path}
  end

  def id
    title.to_s.strip 
  end

  def url
    "#{Settings.post_url_prefix}#{path}"
  end

  def self.search(query, options = {})
    size = options[:per_page] || 10
    from = ([options[:page].to_i, 1].max - 1) * size

    json = Jbuilder.encode do |j|
      j.fields [:id, :path]
      j.from from
      j.size size

      j.query do
        j.match do
          j.content do
            j.query query
            j.operator :and
          end
        end
      end
    end

    response = elasticsearch body: json

    hits = response['hits']

    total_count = hits['total']

    posts = hits['hits'].map do |hit|
      Post.new(title: hit['_id'], path: hit['fields']['path'])
    end

    Kaminari.paginate_array(posts, total_count: total_count).page(options[:page]).per(options[:per_page])
  end
end
