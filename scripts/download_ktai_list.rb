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

uri = 'http://ke-tai.org/moblist/csv_down.php'

print 'updating ke-tai list from ke-tai.org...'
STDOUT.flush

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
