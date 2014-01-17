class WikiCrawler
  def authenticate
    add_http_auth
    sign_in
  end

  def url_prefix
    Settings.crawler_url_prefix 
  end

  def wiki_url
    Settings.wiki_url 
  end

  def add_http_auth
    username = Settings.auth.username
    password = Settings.auth.password
    agent.add_auth url_prefix, username, password
  end

  def sign_in
    username = Settings.sign_in.username
    password = Settings.sign_in.password
    agent.post "#{url_prefix}/login", username: username, password: password
  end

  def perform
    authenticate
    fetch_posts_list.each do |post|
      begin
        post.content = fetch_post_content(post) 
      rescue Mechanize::ResponseCodeError => e
        if e.response_code == '403'
          next
        end
      end
      post.create_search_index
      sleep rand(4)
    end
  end

  def fetch_posts_list
    page = agent.get wiki_url
    page.search(".pages-hierarchy a").map do |a|
      title = a.text.to_s.strip rescue ""
      Post.new(title: title, path: a['href']) 
    end
  end

  def fetch_post_content(post)
    page = agent.get(post.path) 
    page.search('.wiki.wiki-page').text.to_s.strip
  end

  def agent
    if defined?(@agent)
      @agent
    else
      @agent= Mechanize.new
      @agent.user_agent = 'Wiki Search'
      @agent.max_history= 1
      @agent
    end
  end
end
