namespace :post do
  desc "crawl and create index"
  task crawl: :environment do
    crawler = WikiCrawler.new
    crawler.perform
  end
end
