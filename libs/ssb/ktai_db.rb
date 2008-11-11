# ktai_db.rb - ktai database
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distribute under the same terms as Ruby
#
# $Id: ktai_db.rb 2318 2007-12-02 19:22:46Z coji $
#
require 'csv'
require 'nkf'

module SSB
  class KtaiDB
    COLUMN_MAP = {
      '連番'               => :id,
      'メーカ名'           => :carrier,
      '機種名'             => :name,
      '機種略名'           => :name_abbr,
      'ユーザエージェント' => :useragent,
      'タイプ１'            => :generation,
      'タイプ２'            => :generation_ver,
      'ブラウザ幅(x)'      => :screen_width,
      'ブラウザ高さ(y)'    => :screen_height,
      '表示カラー数'       => :colors,
      'ブラウザキャッシュ' => :cache_size,
      'GIF'                => :gif,
      'JPG'                => :jpg,
      'PNG'                => :png,
      'Flash'              => :flash,
      'Flashバージョン'    => :flash_ver,
      'Flashワークメモリ'  => :flash_work_memory,
      'Javaアプリ'         => :java,
      'BREW'               => :brew,
      'HTML'               => :html,
      'SSL'                => :ssl,
      'ログイン'           => :login,
      'クッキー'           => :cookie,
      '備考'               => :note,
      '更新日'             => :lastupdate,
    }

    def initialize(do_load = false, filename = nil)
      @cols = Array.new
      @list = Array.new

      if filename.nil?
        filename = File.join(SSB::CONFIG[:config_dir], 'ke-tai_list.csv')
      end

      if do_load
        load_from_csv(filename)
      end
    end

    def search(query)
      real_search(@list, query)
    end

    def self.load(force_load = false)

    end

    private
    def load_from_csv(filename)
      state = :start
      CSV.open(filename, 'r') do |csv|
        csv = csv.map{|e| NKF::nkf('-w', e)}
        case state
        when :start
          state = :columns
        when :columns
          state = :body
          @cols = csv.map{ |e| COLUMN_MAP[e] }
        when :body
          add_item combine(csv)
        end
      end
    end

    def real_search(list, query)
      ret = list
      cond = query.shift
      return ret if cond[1].nil?

      # キャリア名の変動対応(ThirdForce等)
      cond[1] = remap_carrier(cond[1]) if cond[0] == :carrier

      # 前方一致で探す
      if cond[0] == :useragent
        # useragent のときだけ前方からの部分一致でok
        ret = list.select {|e| e[cond[0]].index(cond[1]) }
      else
        # 普通は後方一致
        ret = list.select {|e| e[cond[0]] =~ Regexp.union(/^#{cond[1]}.*/i) }
      end

      if query.size == 0
        ret
      else
        real_search(ret, query) # 再帰
      end
    end

    # 同一キャリアの別名を許容する
    def remap_carrier(source)
      remap_table = [
        'DoCoMo',
        'au|KDDI|Tu-ka',
        'Vodafone|SoftBank|ThirdForce', # ディズニーとか...
      ]

      for cond in remap_table do
        if source =~ Regexp.union(/#{cond}/i)
          source = cond
          break
        end
      end
      source
    end

    def add_item(ktai)
      @list << ktai
    end

    def combine(data)
      t = Hash.new
      @cols.size.times do |i|
        t[@cols[i]] = data[i]
      end
      t
    end

    def method_missing(msg, *arg, &block)
      @list.send(msg, *arg, &block)
    end
  end
end
