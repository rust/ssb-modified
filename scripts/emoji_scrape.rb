# scrape.rb - k-tai emoji scraper
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distribute under the same terms as Ruby
#
# $Id: emoji_scrape.rb 18931 2008-09-06 18:50:45Z koshigoe $
#
require 'config/common.rb'
require 'rubygems'
require 'scrapi'
require 'open-uri'
require 'nkf'
$KCODE = 'utf-8'

module EmojiScraper
  EMOJI_DIR = File.join(SSB::CONFIG[:public_dir], 'emoji')

  def self.emoji_dir(carrier)
    File.join(EMOJI_DIR, carrier)
  end

  def self.scrape_docomo
    base_uri =
      ['http://www.nttdocomo.co.jp/service/imode/make/content/pictograph/basic/',
      'http://www.nttdocomo.co.jp/service/imode/make/content/pictograph/extention/']

    emoji_scraper = Scraper.define do
      process 'td:nth-child(3) > span.txt', :code => :text
      process 'td > img', :uri => '@src'
      result :code, :uri
    end

    scraper = Scraper.define do
      array :emoji
      process 'tr.acenter', :emoji => emoji_scraper
      result :emoji
    end

    opt = { :char_encoding => 'utf8' }
    base_uri.each do |uri|
      html = NKF::nkf('-w', open(uri).read)
      scraper.scrape(html, opt).select{|e| e unless e.uri.nil? }.each do |p|
        tmpfile = File.join(emoji_dir('docomo'), p.code + '.tmp.gif')
        filename = File.join(emoji_dir('docomo'), p.code + '.gif')
        pict_uri = URI.parse(uri) + p.uri
        open(pict_uri) do |img|
          open(tmpfile, 'w') do |out|
            out.write img.read
          end
        end

        `convert -transparent white -resize 16x16 #{tmpfile} #{filename}`
        `rm #{tmpfile}`
        puts pict_uri.to_s + " => " + filename
      end
    end
  end

  def self.scrape_kddi
    tmpfile = 'ezicon.lzh'
    open('http://www.au.kddi.com/ezfactory/tec/spec/lzh/icon_image.lzh') do |f|
      open(tmpfile, 'w') do |out|
        out.print f.read
      end
    end

    `lha -x #{tmpfile}`
    Dir.glob('icon_image/*.ai') do |src|
      if(match = src.match(/(\d+).+\.ai$/))
    puts src
        out_filename = File.join(emoji_dir('kddi'), match[1] + '.gif')
        `convert -trim -geometry 16x16 +repage "#{src}" #{out_filename}`
      end
    end
    `rm #{tmpfile}`
    `rm -Rf icon_image`
  end

  def self.scrape_thirdforce
    base_uri = 'http://creation.mb.softbank.jp/web/'
    page = 'web_pic_%02d.html'
    1.upto(6) do |n|
      pict_scraper = Scraper.define {
          process 'td:nth-child(2)[bgcolor="#FFFFFF"]', :unicode => :text
          process 'td > img', :image  => '@src'
          result :unicode, :image
      }
      Scraper.define{
        process 'table[width="100%"] > tr', 'pictograms[]' => pict_scraper
        result :pictograms
      }.scrape(URI.parse(base_uri + page % n)).select {|x| not x.nil? }.select {|x| not x.unicode.nil? }.each {|pictinfo|
        tmpfile = File.join(emoji_dir('softbank'), pictinfo.unicode + '.tmp.gif')
        filename = File.join(emoji_dir('softbank'), pictinfo.unicode + '.gif')
        pict_uri = URI.parse(base_uri) + pictinfo.image

        open(pict_uri) do |img|
          open(tmpfile, 'w') do |out|
            out.write img.read
          end
        end

        `convert -transparent white -resize 16x16 #{tmpfile} #{filename}`
        `rm #{tmpfile}`
        puts pict_uri.to_s + " => " + filename
      }
    end
  end

  def self.run
    scrape_docomo
    scrape_kddi
    scrape_thirdforce
  end
end

if $0 == __FILE__
  EmojiScraper.run
end  
