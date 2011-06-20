require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'net/http'

class ReaderStats

  def dump_links(doc)
    doc.xpath('//feed/entry').each_with_index do |entry, i|
      next if i == 0 #skip the first one
      link = entry.search('link').attribute('href').text
      if link.include?('~r') || link.include?('feedproxy') #stupid fb
        puts "resolving #{link}"
        new_link = Net::HTTP.get_response(URI.parse(link))['location']
        link = new_link unless new_link == nil
        puts "resolved to #{new_link}"
      end
      @raw_url_dump_links.write("#{link}\n")
    end
  end

  def stats(file)
    @feedurls = {}
    @cnt = 0
    stats_file = File.open(file)
    stats_file.each do |link|
      puts link
      link += '/' # we cheat
      base, path = link.match(/https?:\/\/(.+?)\/(.*?)/).captures
      puts base
      if @feedurls[base]
        @feedurls[base] += 1
      else
        @feedurls[base] = 1
      end
      @cnt += 1
    end
  end

  def write_stats(file)
    out = File.new(file, 'w')
    out.write "You've shared #{@cnt} items to this date.\n"
    out.write "You have shared from #{@feedurls.count} different sources.\n"
    out.write "--------\n"
    sorted = @feedurls.sort {|a, b| b[1]<=>a[1]} #reverse sort
    sorted.each do |item|
      # only over 10
      next if item[1] < 5
      out.write "You've shared #{item[0]} exactly #{item[1]} times.\n" 
    end
    out.close
    puts "done writing stats to #{file}"
  end

  def fetch_and_dump(file)
    @the_cnt = 0
    @raw_url_dump_links = File.new(file, 'w')
    user="11540475980865935293"
    count="500"
    atom_url="http://www.google.com/reader/public/atom/user/#{user}/state/com.google/broadcast?n=#{count}"
    doc = Nokogiri(open(atom_url))
    dump_links(doc)
    cont = doc.search('continuation')
    while cont.length > 0
      @the_cnt += 1
      puts "Starting the next #{@the_cnt * count.to_i}"
      next_url = "#{atom_url}&c=#{cont.first.text}"
      doc = Nokogiri(open(next_url))
      dump_links(doc)
      cont = doc.search('continuation')
    end
    puts "done!"
    @raw_url_dump_links.close()
  end
  

  def fetch_reader_xml
    user="11540475980865935293"
    count=500
    iter=0
    atom_url="http://www.google.com/reader/public/atom/user/#{user}/state/com.google/broadcast?n=#{count}"
    doc = Nokogiri(open(atom_url))
    author = doc.search('author name').first.text
    cont = doc.search('continuation')
    doc.write_xml_to(File.new("#{author}_dump_#{iter}.xml", 'w'))
    while cont.length > 0
      iter += 1
      puts "Starting the next #{iter * count}"
      next_url = "#{atom_url}&c=#{cont.first.text}"
      doc = Nokogiri(open(next_url))
      cont = doc.search('continuation')
      doc.write_xml_to(File.new("#{author}_dump_#{iter}.xml", 'w'))
    end
    puts "done!"
  end

  def initialize
    fetch_reader_xml
  end

end

stats = ReaderStats.new
