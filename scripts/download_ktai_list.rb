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
dirname  = File.dirname(__FILE__) + "/../config/"
tmp_dir  = File.dirname(__FILE__) + "/../tmp/"
user     = YAML.load_file(dirname + "impress.yml")
filename = File.basename(user["impress"]["url"])

print 'updating ke-tai list from ke-tai.org...'
STDOUT.flush

# retreive files
Dir.chdir tmp_dir
unless File.exist?(filename)
  system("wget --http-user #{user["impress"]["user"]} --http-password #{user["impress"]["password"]} #{user["impress"]["url"]}")
  system("unzip -o #{filename}")
end
Dir.glob("*.csv").each do |file|
  if File.basename(file).=~ /[^a-zA-Z\.]/
    FileUtils.mv file, File.basename(file).gsub(/[^a-zA-Z\.]/, "")
  end
end

# キャリア変換
carriers = {
  "DoCoMo"   => "DoCoMo",
  "au"       => "au",
  "Tu-Ka"    => "au",
  "SoftBank" => "SoftBank",
}

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
id = 1
mobile_info = {}
CSV.foreach("ProfileData.csv") do |row|
  row.map!{|r| NKF.nkf("-w -S", r || "")}
  if carrier = carriers[row[0]]
    mobile_info[carrier] ||= Hash.new
    model_name = row[1].gsub(/カメラ(無し|なし)/, "")
    mobile_info[carrier][model_name] = [
      id,
      carrier,
      model_name,
      model_name,
      nil,
      row[16],
      row[16],
      nil,
      nil,
      nil,
      row[48],
      row[10]  == "N" ? 1 : 0,
      row[11]  == "N" ? 1 : 0,
      row[12]  == "N" ? 1 : 0,
      row[32]  == "N" ? 1 : 0,
      row[47],
      nil,
      row[21]  =~ /java/i ? "Java" : nil,
      row[21]  =~ /BREW/i ? "BREW" : nil,
      row[6]   =~ /html/i ? 1 : 0,
      (row[17] == "E" or row[17] == "L") ? 1 : 0,
      row[54]  == "Y" ? 1 : 0,
      (row[53] == "C" or row[53] == "S") ? 1 : 0,
      nil,
      row[66]
    ]
    id += 1
  end
end
CSV.foreach("UserAgent.csv") do |row|
  row.map!{|r| NKF.nkf("-w -S", r || "")}
  if carrier = carriers[row[0]]
    model_name = row[1].gsub(/カメラ(無し|なし)/, "")
    if mobile_info[carrier][model_name][4].nil?
      mobile_info[carrier][model_name][4] = (row[3].to_s + row[4].to_s).chomp
    end
  end
end
CSV.foreach("DisplayInfo.csv") do |row|
  row.map!{|r| NKF.nkf("-w -S", r || "")}
  if carrier = carriers[row[0]]
    model_name = row[1].gsub(/カメラ(無し|なし)/, "")
    if row[2] =~ /ブラウザ画像サイズ/
      mobile_info[carrier][model_name][7] = row[3]
      mobile_info[carrier][model_name][8] = row[4]
    end
  end
end

csv_data = []
mobile_info.each do |carrier, mobiles|
  mobiles.each do |model_name, model_info|
    csv_data[model_info[0].to_i] = mobile_info[carrier][model_name]
  end
end
# 保存
CSV.open(File.join(SSB::CONFIG[:config_dir], 'ke-tai_list.csv'), 'w') do |writer|
  writer << ["MobilePhoneList [#{Time.now}] By Impress"]
  writer << ["連番", "メーカ名", "機種名", "機種略名", "ユーザエージェント", "タイプ１", "タイプ２", "ブラウザ幅(x)", "ブラウザ高さ(y)", "表示カラー数", "ブラウザキャッシュ", "GIF", "JPG", "PNG", "Flash", "Flashバージョン", "Flashワークメモリ", "Javaアプリ", "BREW", "HTML", "SSL", "ログイン", "クッキー", "CSS", "GPS", "発売日", "備考", "更新状況メモ", "更新日"]
  csv_data.each do |mobile_info|
    unless mobile_info.nil?
      mobile_info.map!{|m| NKF.nkf("-W -s", (m || "").to_s)}
      writer << mobile_info
    end
  end
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
