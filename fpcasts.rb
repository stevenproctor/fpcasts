#! /usr/bin/env ruby

require 'cgi'
require 'erb'
require 'rss'
require 'yaml'
require 'ostruct'

def feed_summary(feed_url)
  puts "[#{Time.now}] generating summary for #{feed_url}"
  rss = RSS::Parser.parse(feed_url, false)
  latest = rss.items.first
  if (rss.channel.itunes_image)
    image = rss.channel.itunes_image.href
  else
    image = rss.image.url
  end
  OpenStruct.new({
    url: feed_url,
    title: CGI.escapeHTML(rss.channel.title),
    image: image,
    description: CGI.escapeHTML(rss.channel.description),
    latest_episode_title: CGI.escapeHTML(latest.title),
    latest_episode_link: latest.link,
    last_updated: latest.date.strftime("%F")
  })
rescue
  STDERR.puts "error generating summary for feed: #{feed_url}"
end

def get_feed_summaries(feed_config)
  feed_urls = YAML.load(File.read(feed_config))
  feed_urls.map{ |feed_url| feed_summary(feed_url) }.sort_by{ |feed| feed.title.downcase }
end

def main(config, template_path, output_path)
  template = File.read(template_path)

  renderer = ERB.new(template)

  feeds = get_feed_summaries(config)
  output = renderer.result(binding)

  File.open(output_path, 'w') do |f|
    f << output
  end
end

main('config/feeds.yml', 'templates/index.html.erb', 'output/index.html')
