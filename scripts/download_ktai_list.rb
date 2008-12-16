# download_ktai_list.rb - download ke-tai list from http://ke-tai.org/
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distribute under the same terms as Ruby
#
# $Id: download_ktai_list.rb 2407 2007-12-04 06:49:13Z coji $
#
require 'config/common'
require 'ssb/ktai_db'
require 'open-uri'
require 'fileutils'
require 'yaml'
require 'csv'
require 'nkf'

# settings
filename = File.basename(url)
dirname  = File.dirname(__FILE__) + "/../config/"
tmp_dir  = File.dirname(__FILE__) + "/../tmp/"
user     = YAML.load_file(dirname + "impress.yml")

print 'updating ke-tai list from ke-tai.org...'
STDOUT.flush

# retreive files
Dir.chdir tmp_dir
unless File.exist?(filename)
  system("wget --http-user #{user} --http-password #{password} #{url}")
  system("unzip -o #{filename}")
end
Dir.glob("*.csv").each do |file|
  FileUtils.mv file, File.basename(file).gsub(/[^a-zA-Z\.]/, "")
end

# キャリア変換
carriers = {
  "DoCoMo"   => "DoCoMo",
  "au"       => "au",
  "Tu-Ka"    => "au",
  "Softbank" => "Softbank",
}

profile_data = CSV.open("ProfileData").read
user_agent   = CSV.open("UserAgent").read
display_info = CSV.open("DisplayInfo").read

# build csv file
# "連番"
# "メーカ名"
# "機種名"
# "機種略名"
# "ユーザエージェント"
# "タイプ１"
# "タイプ２"
# "ブラウザ幅(x)"
# "ブラウザ高さ(y)"
# "表示カラー数"
# "ブラウザキャッシュ"
# "GIF"
# "JPG"
# "PNG"
# "Flash"
# "Flashバージョン"
# "Flashワークメモリ"
# "Javaアプリ"
# "BREW"
# "HTML"
# "SSL"
# "ログイン"
# "クッキー"
# "CSS"
# "GPS"
# "発売日"
# "備考"
# "更新状況メモ"
# "更新日"



open(File.join(SSB::CONFIG[:config_dir], 'ke-tai_list.csv'), 'w') do |out|
  out.print open(uri).read()
end

puts 'done.'

print 'generating ke-tai db js...'
db = SSB::KtaiDB.new(true)
File.open(File.join(SSB::CONFIG[:public_dir], ['javascripts', 'ktai_db.js']), 'w') do |out|
  out.puts 'var SSB = {';
  out.puts '  ktai_list : ['
  out.puts(db.map {|e| %Q|"#{e[:carrier]} #{e[:name]}"| }.join(",\n"))
  out.puts '  ],'
  out.puts '  ktai_db : {'
  list = Array.new
  db.each do |e|
    str = Array.new
    e.each_pair do |k,v|
      str << %Q|      "#{k}": "#{v}"|
    end
    list << %Q|    "#{e[:carrier]} #{e[:name]}": {\n #{str.join(",\n")}\n}|
  end
  out.puts list.join(",\n")
  out.puts '  }'
  out.puts '};'
end
puts 'done.'
