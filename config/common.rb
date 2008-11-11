# common.rb - SSB common code
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distributes under the same terms as Ruby
#
# $Id: common.rb 2827 2007-12-07 18:00:13Z coji $
#
$SAFE = 1
$KCODE = 'utf-8'

module SSB
  CONFIG = {} unless defined? CONFIG 
  CONFIG[:home_dir] = File.expand_path(File.join(File.dirname(__FILE__), '..')).untaint
  CONFIG[:public_dir] = File.join(SSB::CONFIG[:home_dir], 'public_html')
  CONFIG[:template_dir] = File.join(SSB::CONFIG[:home_dir], 'templates')
  CONFIG[:vendor_dir] = File.join(SSB::CONFIG[:home_dir], 'vendor')
  CONFIG[:library_dir] = ['libs', 'vendor']
  CONFIG[:config_dir] = File.join(SSB::CONFIG[:home_dir], 'config')
  CONFIG[:config_file] = File.join(SSB::CONFIG[:config_dir], 'config.yaml')
  CONFIG[:dat_dir] = File.join(SSB::CONFIG[:home_dir], 'dat')

  @@config = nil

  def self.config(force_reload = false)
    if @@config.nil? or force_reload
      begin
        File.open(SSB::CONFIG[:config_file]) do |f|
          @@config = YAML.load(f.read.untaint)
        end
      rescue =>e
        @@config = {}
      end
    end

    # useragent/homepage だけは設定がなくてもデフォルトで入れる
    @@config['default'] ||= {}
    @@config['default']['useragent'] ||= 'DoCoMo/2.0 P905i'
    @@config['default']['homepage'] ||= 'about:blank'

    @@config
  end
end

$LOAD_PATH.concat SSB::CONFIG[:library_dir].map{|d| File.join(SSB::CONFIG[:home_dir], d)}
