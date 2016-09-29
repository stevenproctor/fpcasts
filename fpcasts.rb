#! /usr/bin/env ruby

require 'cgi'
require 'erb'
require 'rss'
require 'yaml'
require 'ostruct'


def get_image_path!(rss, output_directory)
  if (rss.channel.itunes_image)
    image_location = rss.channel.itunes_image.href
  else
    image_location = rss.image.url
  end

  image_path = File.basename(image_location).split("?").first

  `wget -O - #{image_location} > #{File.join(output_directory, image_path)}`

  image_path
end

def feed_summary(feed_url, output_directory)
  puts "[#{Time.now}] generating summary for #{feed_url}"
  rss = RSS::Parser.parse(feed_url, false)
  latest = rss.items.first
  image = get_image_path!(rss, output_directory)

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

def get_feed_summaries(feed_config, output_directory)
  feed_urls = YAML.load(File.read(feed_config))
  feed_urls.map{ |feed_url| feed_summary(feed_url, output_directory) }.sort_by{ |feed| feed.title.downcase }
end

def main(config, template_path, output_directory)
  `cp ./*.css #{output_directory}`

  template = File.read(template_path)
  output_filename = File.basename(template_path, '.erb')

  renderer = ERB.new(template)

  feeds = get_feed_summaries(config, output_directory)
  output = renderer.result(binding)

  output_path = File.join(output_directory, output_filename)

  File.open(output_path, 'w') do |f|
    f << output
  end
end

main('config/feeds.yml', 'templates/index.html.erb', 'output')
