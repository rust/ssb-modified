require (File.join(File.dirname(__FILE__), 'config', 'common'))

require 'rake'
require 'rake/testtask'
require 'scripts/emoji_scrape.rb'

desc "Run all unit tests"
task :test do
  ruby "test/all_tests.rb"
end

desc "Initial setup"
task :setup => ["chmod_logs", "config/config.yaml", "public_html/.htaccess"]
task :setup => [:scrape]
task :setup => ["ktai:update"]
task :setup => ["vendor"]

desc "Scrape all emoji"
task :scrape => ["scrape:kddi", "scrape:docomo", "scrape:thirdforce"]
namespace :scrape do
  desc "Scrape KDDI(AU) emoji"
  task :kddi => ["public_html/emoji/kddi"] do
    puts "Retrieving KDDI emoji"
    EmojiScraper.scrape_kddi
    puts "done."
  end
  desc "Scrape NTT Docomo emoji"
  task :docomo => ["public_html/emoji/docomo"] do
    puts "Retrieving Docomo emoji"
    EmojiScraper.scrape_docomo
    puts "done."
  end
  desc "Scrape Softbank emoji"
  task :softbank => :thirdforce
  desc "Scrape Thirdforce (Softbank) emoji"
  task :thirdforce => ["public_html/emoji/softbank"] do
    puts "Retrieving Softbank emoji"
    EmojiScraper.scrape_thirdforce
    puts "done."
  end
  desc "Delete all emoji"
  task :clear do
    rm_rf "public_html/emoji/docomo/*"
    rm_rf "public_html/emoji/kddi/*"
    rm_rf "public_html/emoji/softbank/*"
    rm_f "ezicon.lzh"
    rm_rf "icon_image"
  end
end

namespace :logs do
  desc "Delete logs"
  task :clear do
    rm Dir.glob("logs/*"), :force => true
  end
end

namespace :ktai do
  desc "Update ke-tai.org lists"
  task :update do
    ruby "scripts/download_ktai_list.rb"
  end
end

desc "download vendor library"
task :vendor => ["vendor:qrcode"]
namespace :vendor do
  desc "download QR code library"
  task :qrcode => ["vendor/qrcode"] do
    puts "Retrieving QR code library"
    ruby "scripts/download_qrcode_library.rb"
    puts "done."
  end
end

directory "public_html/emoji/docomo"
directory "public_html/emoji/kddi"
directory "public_html/emoji/softbank"
directory "logs"
directory "vendor/qrcode"
task "chmod_logs" => ["logs"] do chmod(0777, "logs") end
file "config/config.yaml" do |t| cp "#{t.name}.default", t.name end
file "public_html/.htaccess" do |t| cp "#{t.name}.default", t.name end
